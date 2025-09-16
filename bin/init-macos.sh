#!/usr/bin/env bash
# Bootstrap dotfiles on a fresh macOS install (Apple Silicon friendly).
set -euo pipefail

log() {
  printf '[init] %s\n' "$1"
}

warn() {
  printf '[init] warning: %s\n' "$1" >&2
}

require_darwin() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    warn "This script is intended for macOS only."
    exit 1
  fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
timestamp="$(date +%Y%m%d%H%M%S)"

abs_path() {
  python3 - <<'PY' "$1"
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Installing Homebrew..."
  /bin/bash -c "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  local brew_shellenv
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_shellenv="$(/opt/homebrew/bin/brew shellenv)"
  else
    brew_shellenv="$(/usr/local/bin/brew shellenv)"
  fi
  eval "$brew_shellenv"
}

brew_install() {
  local kind="$1" name="$2"

  if [[ "$kind" == "formula" ]]; then
    if brew list --formula "$name" >/dev/null 2>&1; then
      log "brew formula '$name' already installed"
      return
    fi
    log "Installing brew formula '$name'"
    brew install "$name"
  else
    if brew list --cask "$name" >/dev/null 2>&1; then
      log "brew cask '$name' already installed"
      return
    fi
    log "Installing brew cask '$name'"
    brew install --cask "$name"
  fi
}

backup_existing() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.bak.${timestamp}"
    log "Backing up existing $(basename "$target") to ${backup}"
    mv "$target" "$backup"
  fi
}

link_path() {
  local source_path="$1"
  local target_path="$2"
  local abs_source

  if [[ ! -e "$source_path" ]]; then
    warn "Source path not found: $source_path"
    return 1
  fi

  abs_source="$(abs_path "$source_path")"

  if [[ -L "$target_path" ]]; then
    local resolved="$(abs_path "$target_path")"
    if [[ "$resolved" == "$abs_source" ]]; then
      log "Link already in place for ${target_path}"
      return
    fi
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_existing "$target_path"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$abs_source" "$target_path"
  log "Linked $(basename "$source_path") -> ${target_path}"
}

link_into_config() {
  local relative_source="$1"
  local relative_target="${2:-$1}"
  link_path "${repo_root}/${relative_source}" "${config_home}/${relative_target}"
}

link_alias() {
  local existing_target="$1"
  local alias_target="$2"
  link_path "$existing_target" "$alias_target"
}

main() {
  require_darwin

  if [[ "$(uname -m)" != "arm64" ]]; then
    warn "System is not Apple Silicon; continuing but package paths may differ."
  fi

  mkdir -p "$config_home"

  if ! command -v xcode-select >/dev/null 2>&1 || ! xcode-select -p >/dev/null 2>&1; then
    warn "Command line tools not detected. Run 'xcode-select --install' if prompted."
  fi

  ensure_homebrew
  eval "$(brew shellenv)"
  brew update
  local formulas=(
    fish
    tmux
    starship
    eza
    direnv
    fzf
    sqlite
    gh
    neovim
  )

  local casks=(
    alacritty
    amethyst
    font-jetbrains-mono-nerd-font
    hammerspoon
    karabiner-elements
  )

  for formula in "${formulas[@]}"; do
    brew_install formula "$formula"
  done

  for cask in "${casks[@]}"; do
    brew_install cask "$cask"
  done

  link_into_config "fish"
  link_into_config "alacritty"
  link_into_config "karabiner"
  link_into_config "gh"
  link_into_config "nextjs-nodejs"
  link_into_config "tmux/tmux.conf" "tmux/tmux.conf"
  link_into_config "starship.toml" "starship.toml"
  link_into_config ".hammerspoon" "hammerspoon"
  link_into_config ".amethyst.yml" "amethyst/amethyst.yml"

  link_alias "${config_home}/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_alias "${config_home}/hammerspoon" "$HOME/.hammerspoon"
  link_alias "${config_home}/amethyst/amethyst.yml" "$HOME/.amethyst.yml"

  log "All done! Restart your terminal or run 'eval \"$(brew shellenv)\"' to pick up Homebrew."
}

main "$@"
