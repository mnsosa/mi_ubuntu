#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

printf '%s\n' "GNOME: $(gnome-shell --version 2>/dev/null || printf 'unknown')"

# Install packages (optional)

if [[ -f "$ROOT_DIR/manifest/apt-packages.txt" ]] && [[ -s "$ROOT_DIR/manifest/apt-packages.txt" ]]; then
  if confirm "Install apt packages from manifest/apt-packages.txt?"; then
    sudo apt update
    xargs -a "$ROOT_DIR/manifest/apt-packages.txt" -r sudo apt install -y
  fi
fi

if [[ -f "$ROOT_DIR/manifest/snaps.txt" ]] && [[ -s "$ROOT_DIR/manifest/snaps.txt" ]]; then
  if confirm "Install snap packages from manifest/snaps.txt?"; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue

      read -r -a parts <<< "$line"
      snap_name="${parts[0]}"
      channel=""
      classic="false"

      for token in "${parts[@]:1}"; do
        if [[ "$token" == "classic" ]]; then
          classic="true"
        else
          channel="$token"
        fi
      done

      if snap list "$snap_name" >/dev/null 2>&1; then
        printf '%s\n' "Snap already installed: $snap_name"
        continue
      fi

      cmd=(sudo snap install "$snap_name")
      if [[ -n "$channel" ]]; then
        cmd+=(--channel="$channel")
      fi
      if [[ "$classic" == "true" ]]; then
        cmd+=(--classic)
      fi

      printf '%s\n' "Installing snap: $snap_name"
      "${cmd[@]}"

    done < "$ROOT_DIR/manifest/snaps.txt"
  fi
fi

# OpenCode / opencode config + plugins

if [[ -f "$ROOT_DIR/opencode/opencode.json" ]] && [[ -s "$ROOT_DIR/opencode/opencode.json" ]]; then
  if confirm "Replace ~/.config/opencode/opencode.json with repo version? (backs up current)"; then
    mkdir -p "$HOME/.config/opencode"

    if [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
      ts="$(date +%Y%m%d-%H%M%S)"
      cp "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json.bak.$ts"
      printf '%s\n' "Backed up to ~/.config/opencode/opencode.json.bak.$ts"
    fi

    cp "$ROOT_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  fi
fi

if [[ -f "$ROOT_DIR/manifest/opencode-plugins.txt" ]] && [[ -s "$ROOT_DIR/manifest/opencode-plugins.txt" ]]; then
  if confirm "Ensure plugin list is applied too? (writes plugin[] into opencode.json)"; then
    mkdir -p "$HOME/.config/opencode"

    python3 - <<'PY' "$ROOT_DIR/manifest/opencode-plugins.txt" "$HOME/.config/opencode/opencode.json"
import json
import sys
from pathlib import Path

plugins_path = Path(sys.argv[1])
config_path = Path(sys.argv[2])

plugins = [line.strip() for line in plugins_path.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip()]

data = {"$schema": "https://opencode.ai/config.json"}
if config_path.exists():
    try:
        data.update(json.loads(config_path.read_text(encoding="utf-8", errors="ignore") or "{}"))
    except Exception:
        pass

data["plugin"] = plugins
config_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Updated {config_path} with {len(plugins)} plugins")
PY

    printf '%s\n' "NOTE: opencode may install plugins on next run"
  fi
fi

# Tools (optional)

if confirm "Install uv (Python package manager) from astral.sh?"; then
  if command -v uv >/dev/null 2>&1; then
    printf '%s\n' "uv already installed: $(uv --version 2>/dev/null || true)"
  else
    tmp_file="$(mktemp)"
    curl -LsSf https://astral.sh/uv/install.sh -o "$tmp_file"
    bash "$tmp_file"
    rm -f "$tmp_file"
  fi
fi

# Apply GNOME settings

confirm "Apply GNOME settings (favorite-apps + keybindings + extension settings)?" || exit 0

# favorite-apps
if [[ -f "$ROOT_DIR/gsettings/favorite-apps.txt" ]]; then
  fav_apps="$(cat "$ROOT_DIR/gsettings/favorite-apps.txt")"
  gsettings set org.gnome.shell favorite-apps "$fav_apps"
fi

# dconf loads
if [[ -f "$ROOT_DIR/dconf/shell-extensions.dconf" ]]; then
  dconf load /org/gnome/shell/extensions/ < "$ROOT_DIR/dconf/shell-extensions.dconf"
fi

if [[ -f "$ROOT_DIR/dconf/media-keys.dconf" ]]; then
  dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$ROOT_DIR/dconf/media-keys.dconf"
fi

if [[ -f "$ROOT_DIR/dconf/wm-keybindings.dconf" ]]; then
  dconf load /org/gnome/desktop/wm/keybindings/ < "$ROOT_DIR/dconf/wm-keybindings.dconf"
fi

if [[ -f "$ROOT_DIR/dconf/mutter-keybindings.dconf" ]]; then
  dconf load /org/gnome/mutter/keybindings/ < "$ROOT_DIR/dconf/mutter-keybindings.dconf"
fi

# enable extensions
if command -v gnome-extensions >/dev/null 2>&1 && [[ -f "$ROOT_DIR/manifest/enabled-extensions.txt" ]]; then
  if confirm "Enable listed GNOME extensions now? (missing ones will error)"; then
    while IFS= read -r uuid; do
      [[ -z "$uuid" ]] && continue
      printf '%s\n' "Enabling: $uuid"
      gnome-extensions enable "$uuid" || printf '%s\n' "WARN: could not enable $uuid"
    done < "$ROOT_DIR/manifest/enabled-extensions.txt"
  fi
fi

printf '%s\n' "OK: applied"