#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$ROOT_DIR/dconf" "$ROOT_DIR/gsettings" "$ROOT_DIR/manifest"

confirm() {
  local prompt="$1"
  if [[ ! -t 0 ]]; then
    return 1
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

favorites_to_lines() {
  local raw="$1"
  python3 - <<'PY' "$raw"
import ast
import sys
raw = sys.argv[1]
try:
    items = ast.literal_eval(raw)
except Exception:
    items = []
for item in items:
    if isinstance(item, str) and item:
        print(item)
PY
}

resolve_desktop_file() {
  local desktop_id="$1"
  local candidates=(
    "/usr/share/applications/$desktop_id"
    "/usr/local/share/applications/$desktop_id"
    "$HOME/.local/share/applications/$desktop_id"
    "/var/lib/snapd/desktop/applications/$desktop_id"
  )

  local path
  for path in "${candidates[@]}"; do
    if [[ -f "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  return 1
}

add_apt_pkg_for_file() {
  local path="$1"
  local owner

  owner="$(dpkg -S "$path" 2>/dev/null | head -n1 || true)"
  if [[ -z "$owner" ]]; then
    return 0
  fi

  printf '%s\n' "${owner%%:*}" >> "$ROOT_DIR/manifest/apt-packages.txt"
}

add_snap_for_desktop_file() {
  local desktop_file="$1"
  local desktop_id="$2"

  if [[ "$desktop_file" != /var/lib/snapd/desktop/applications/* ]]; then
    return 0
  fi

  local snap_name=""
  snap_name="$(grep -m1 '^X-SnapInstanceName=' "$desktop_file" 2>/dev/null | cut -d= -f2- || true)"

  if [[ -z "$snap_name" && "$desktop_id" == snap.*.desktop ]]; then
    snap_name="${desktop_id#snap.}"
    snap_name="${snap_name%%.*}"
  fi

  if [[ -z "$snap_name" ]]; then
    snap_name="$(grep -m1 '^Exec=' "$desktop_file" 2>/dev/null | grep -oE 'snap run [^ ]+' | awk '{print $3}' || true)"
  fi

  if [[ -z "$snap_name" ]]; then
    return 0
  fi

  local snap_info
  snap_info="$(snap list "$snap_name" 2>/dev/null | tail -n +2 || true)"

  if [[ -n "$snap_info" ]]; then
    python3 - <<'PY' "$snap_name" "$snap_info" >> "$ROOT_DIR/manifest/snaps.txt"
import sys
name = sys.argv[1]
line = sys.argv[2]
parts = line.split()
channel = ""
notes = ""
# snap list columns: Name Version Rev Tracking Publisher Notes
if len(parts) >= 4:
    channel = parts[3]
if len(parts) >= 6:
    notes = parts[5]
extra = []
if channel:
    extra.append(channel)
if notes and "classic" in notes:
    extra.append("classic")
print(" ".join([name] + extra))
PY
  else
    printf '%s\n' "$snap_name" >> "$ROOT_DIR/manifest/snaps.txt"
  fi
}

# Extensions + settings

dconf dump /org/gnome/shell/extensions/ > "$ROOT_DIR/dconf/shell-extensions.dconf"

gsettings get org.gnome.shell favorite-apps > "$ROOT_DIR/gsettings/favorite-apps.txt"

gsettings get org.gnome.shell enabled-extensions > "$ROOT_DIR/gsettings/enabled-extensions.gsettings.txt"

# Keyboard shortcuts (incl. custom)

dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$ROOT_DIR/dconf/media-keys.dconf"
dconf dump /org/gnome/desktop/wm/keybindings/ > "$ROOT_DIR/dconf/wm-keybindings.dconf"
dconf dump /org/gnome/mutter/keybindings/ > "$ROOT_DIR/dconf/mutter-keybindings.dconf"

# Enabled extensions list (exclude cron@status.jobz)
if command -v gnome-extensions >/dev/null 2>&1; then
  : > "$ROOT_DIR/manifest/enabled-extensions.txt"
  while IFS= read -r uuid; do
    [[ -z "$uuid" ]] && continue
    [[ "$uuid" == "cron@status.jobz" ]] && continue
    printf '%s\n' "$uuid" >> "$ROOT_DIR/manifest/enabled-extensions.txt"
  done < <(gnome-extensions list --enabled)
fi

# Package candidates (from favorites)

: > "$ROOT_DIR/manifest/apt-packages.txt"
: > "$ROOT_DIR/manifest/snaps.txt"

favorites_raw="$(cat "$ROOT_DIR/gsettings/favorite-apps.txt")"
while IFS= read -r desktop_id; do
  desktop_file="$(resolve_desktop_file "$desktop_id" || true)"
  [[ -z "$desktop_file" ]] && continue

  add_snap_for_desktop_file "$desktop_file" "$desktop_id"
  add_apt_pkg_for_file "$desktop_file"

done < <(favorites_to_lines "$favorites_raw")

sort -u -o "$ROOT_DIR/manifest/apt-packages.txt" "$ROOT_DIR/manifest/apt-packages.txt" || true
sort -u -o "$ROOT_DIR/manifest/snaps.txt" "$ROOT_DIR/manifest/snaps.txt" || true

# Optional: infer from shell history (privacy-sensitive)
if confirm "Also infer packages from ~/.bash_history (command names only)?"; then
  if [[ -f "$HOME/.bash_history" ]]; then
    python3 - <<'PY' "$HOME/.bash_history" > "$ROOT_DIR/manifest/top-commands.txt"
import collections
import sys
from pathlib import Path
path = Path(sys.argv[1])
counts = collections.Counter()
for line in path.read_text(errors="ignore").splitlines():
    if not line or line.startswith("#"):
        continue
    cmd = line.strip().split()[0]
    if cmd:
        counts[cmd] += 1
for cmd, _ in counts.most_common(30):
    print(cmd)
PY

    while IFS= read -r cmd; do
      [[ -z "$cmd" ]] && continue
      bin_path="$(command -v "$cmd" 2>/dev/null || true)"
      [[ -z "$bin_path" ]] && continue

      if [[ "$bin_path" == /snap/* || "$bin_path" == /var/lib/snapd/snap/bin/* ]]; then
        snap_name="${bin_path##*/}"
        printf '%s\n' "$snap_name" >> "$ROOT_DIR/manifest/snaps.txt"
      else
        add_apt_pkg_for_file "$bin_path"
      fi
    done < "$ROOT_DIR/manifest/top-commands.txt"

    sort -u -o "$ROOT_DIR/manifest/apt-packages.txt" "$ROOT_DIR/manifest/apt-packages.txt" || true
    sort -u -o "$ROOT_DIR/manifest/snaps.txt" "$ROOT_DIR/manifest/snaps.txt" || true
  fi
fi

# OpenCode / opencode config + plugins

: > "$ROOT_DIR/manifest/opencode-plugins.txt"

if [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
  python3 - <<'PY' "$HOME/.config/opencode/opencode.json" "$ROOT_DIR/manifest/opencode-plugins.txt" "$ROOT_DIR/opencode/opencode.json"
import json
import re
import sys
from pathlib import Path

src_path = Path(sys.argv[1])
plugins_out = Path(sys.argv[2])
config_out = Path(sys.argv[3])

raw = src_path.read_text(encoding="utf-8", errors="ignore")
data = json.loads(raw or "{}")

# Plugins list (for quick installs)
plugins = data.get("plugin", [])
plugin_lines = []
if isinstance(plugins, list):
    for item in plugins:
        if isinstance(item, str) and item.strip():
            plugin_lines.append(item.strip())
plugins_out.write_text("\n".join(plugin_lines) + ("\n" if plugin_lines else ""), encoding="utf-8")

# Sanitized config for public repo: remove obvious secrets recursively
secret_key_re = re.compile(r"(api[-_]?key|token|secret|password|passwd|auth|credential)", re.IGNORECASE)

def sanitize(obj):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            if isinstance(k, str) and secret_key_re.search(k):
                continue
            out[k] = sanitize(v)
        return out
    if isinstance(obj, list):
        return [sanitize(v) for v in obj]
    return obj

sanitized = sanitize(data)
config_out.write_text(json.dumps(sanitized, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Wrote plugins: {plugins_out}")
print(f"Wrote config:  {config_out}")
PY
fi

printf '%s\n' "OK: exported into $ROOT_DIR"