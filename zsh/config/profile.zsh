#!/usr/bin/env zsh
# zsh/default/profile.zsh


# Source user profile config
[ -f "$HOME/.config/zsh/user/profile.zsh" ] && . "$HOME/.config/zsh/user/profile.zsh"


# Start Hyprland Automatically on TTY1 only, so if something breaks,
# you're still able to log in without hyprland on another TTY
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec uwsm start default
fi
