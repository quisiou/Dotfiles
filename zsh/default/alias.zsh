#!/usr/bin/env zsh
# zsh/default/alias.zsh


alias sudo='sudo -A'
alias pubip='curl ipinfo.io/ip && echo'
alias srcrst='. ~/.zshrc'
alias suicidate='systemctl poweroff'
alias popup='xdg-open'
alias uvfcheck='uv format --check --preview-features format'
alias uvfdiff='uv format --diff --preview-features format'
alias uvformat='uv format --preview-features format'
alias gitgraph='git log --oneline --graph --decorate --color'
alias discord='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia vesktop --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-gpu-rasterization --enable-zero-copy &'
alias code='codium'
alias rmhist='history -c && history -w && rm ~/.zsh_history'
alias list-wifi='nmcli -f IN-USE,BSSID,SSID,SIGNAL,RATE,BARS device wifi'
alias cdl='cd -P'
alias ll='ls -lahF'
alias la='ls -A'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
