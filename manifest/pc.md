# Esta PC (snapshot)

Este repo intenta dejar una foto reproducible (lo mas simple posible) del setup de Ubuntu/GNOME y de OpenCode.

- Distro: Ubuntu 24.04.3 LTS
- Desktop: GNOME Shell 46.0
- Kernel: Linux 6.14.0-37-generic
- Hardware (segun `hostnamectl`): ASUSTeK COMPUTER INC. - PRIME H310M-R R2.0

## Dock (favorite apps)

Favoritos actuales (ver `gsettings/favorite-apps.txt`):

- Brave (brave-browser)
- Terminal (gnome-terminal)
- VS Code (snap: `code`)
- Files / Nautilus (nautilus)

## GNOME extensions

Habilitadas (ver `manifest/enabled-extensions.txt` y `gsettings/enabled-extensions.gsettings.txt`):

- Caffeine: evita que se apague/suspenda
- Docker: acceso rapido a Docker / Compose
- Resource Monitor: CPU/RAM/disk/net en la barra
- Ubuntu Tiling Assistant: atajos y layouts de tiling
- Ubuntu Dock + AppIndicators: experiencia default de Ubuntu
- DING: iconos en el escritorio
- Lockscreen Extension + Customize Clock on Lock Screen: personalizacion del lockscreen (en la session normal pueden figurar como INACTIVE)

## Atajos / tiling

Los atajos mas notables que aparecen en la exportacion actual:

- Tiling Assistant (cuadrantes): `Super+Shift+h/j/k/l`

## Paquetes (candidatos)

Los manifests de paquetes son orientativos (hoy se infieren desde los favoritos del dock):

- apt: ver `manifest/apt-packages.txt`
- snap: ver `manifest/snaps.txt`

## OpenCode / opencode

Snapshot de config (sanitizada) en `opencode/opencode.json`:

- Plugins: ver `manifest/opencode-plugins.txt`
- Providers: OpenAI + Google (Gemini)
- MCP: Linear (remote), GitHub (local via docker), Mercado Pago (remote), Chrome DevTools (local via npx)

## Shell

- Zsh + Oh My Zsh: ver `manifest/oh-my-zsh.md`
