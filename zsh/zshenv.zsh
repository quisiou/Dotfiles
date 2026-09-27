#!/usr/bin/env zsh
# zsh/zshenv.zsh


# Source default environment variables
[ -f "$HOME/.config/zsh/env.zsh" ] && . "$HOME/.config/zsh/env.zsh"

# Source personal environment variables
[ -f "$HOME/.config/zsh/user/env.zsh" ] && . "$HOME/.config/zsh/user/env.zsh"
