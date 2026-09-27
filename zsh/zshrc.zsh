#!/usr/bin/env zsh
# zsh/zshrc.zsh


# Source default main config
[ -f "$HOME/.config/zsh/main.zsh" ] && . "$HOME/.config/zsh/main.zsh"

# Source user main config
[ -f "$HOME/.config/zsh/user/main.zsh" ] && . "$HOME/.config/zsh/user/main.zsh"

# Set command history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS     # don't store a line identical to the immediately preceding one
setopt HIST_FIND_NO_DUPS    # when searching history, skip consecutive duplicates while scrolling
setopt EXTENDED_HISTORY     # record a timestamp (and duration) for each history entry
setopt INC_APPEND_HISTORY   # write each command to HISTFILE immediately, not just on shell exit

# Init starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
