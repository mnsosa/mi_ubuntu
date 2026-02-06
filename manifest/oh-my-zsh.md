# Zsh + Oh My Zsh

Este documento describe la configuracion de Zsh/Oh My Zsh de esta PC (como esta hoy), para poder replicarla en otra maquina sin copiar archivos privados.

## Estado actual

- Shell por defecto del usuario: `zsh` (ver `getent passwd $USER`)
- Oh My Zsh instalado en: `~/.oh-my-zsh`
- Archivo principal de config: `~/.zshrc`

### Theme

- `ZSH_THEME="awesomepanda"`

### Plugins

En `~/.zshrc`:

- `git`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

Los 2 plugins custom estan en:

- `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions` (git sha corto: `85919cd`)
- `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` (git sha corto: `5eb677b`)

Oh My Zsh (repo base): `~/.oh-my-zsh` (git sha corto: `9df4ea0`)

### PATH compartido (bash + zsh)

`~/.zshrc` sourcea este archivo si existe:

- `~/.config/shell/env.sh`

Hoy hace principalmente:

- `path_prepend` a rutas comunes (por ejemplo `~/.local/bin`, `~/.opencode/bin`, `~/.bun/bin`, `~/.npm-global/bin`)
- deduplica `PATH` preservando orden

### Aliases

Aliases custom en:

- `~/.oh-my-zsh/custom/aliases.zsh`

Incluye shortcuts de navegacion, git, sistema (apt), python, docker, etc.

## Como replicarlo en otra PC

1) Instalar zsh y hacerlo default:

```bash
sudo apt update
sudo apt install -y zsh git
chsh -s "$(command -v zsh)" "$USER"
```

2) Instalar Oh My Zsh (en `$HOME/.oh-my-zsh`).

3) Instalar plugins custom:

```bash
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
mkdir -p "$ZSH_CUSTOM/plugins"

git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
```

4) Configurar `~/.zshrc`:

- sourcear `~/.config/shell/env.sh`
- setear `ZSH_THEME="awesomepanda"`
- setear `plugins=(git zsh-autosuggestions zsh-syntax-highlighting)`
- sourcear `~/.oh-my-zsh/custom/aliases.zsh`

5) Reiniciar sesion (o abrir una terminal nueva).

## Notas

- No versionar: `~/.zsh_history`.
- Si usas NVM: esta instalado en `~/.nvm`, pero su init no aparece en `~/.zshrc` actual.
