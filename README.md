# Algunas utilidades de mi Ubuntu

Replicar setup en ubuntu 24.04 + gnome 46.
No es todo muy automático, es nomás una referencia y varias cosas igualmente son manuales.
Esto para no quedar atado a una versión particular de todo.

## Exportar (pc origen)
- `./scripts/export.sh`

## Aplicar (pc destino)
- instalar extensiones de EGO (ver `manifest/extensions.md`)
- `./scripts/apply.sh`
- logout/login (recomendado)
- tools extra: ver `manifest/tools.md`

## Incluye
- favorite apps (dock)
- atajos de teclado (dconf: media-keys + wm + mutter)
- settings de extensiones (dconf)
- candidatos de paquetes (apt + snap) desde tus favoritos (ver `manifest/apt-packages.txt` y `manifest/snaps.txt`)
- plugins de OpenCode/opencode (ver `manifest/opencode-plugins.txt`)
- uv (ver `manifest/tools.md`)
