#!/usr/bin/env zsh
# zsh/zshrc.zsh


# Set command history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=12000
export SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
setopt AUTO_CD

bindkey -e

# Source main config
[ -f "$HOME/.config/zsh/main.zsh" ] && . "$HOME/.config/zsh/main.zsh"

# Init starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
