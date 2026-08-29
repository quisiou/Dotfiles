#!/usr/bin/env zsh
# zsh/default/env.zsh


# LESS command formatting
export GROFF_NO_SGR=1
export LESS_TERMCAP_mb=$'\e[5;38;2;190;149;255m'                # blink start (text that flashes)
export LESS_TERMCAP_md=$'\e[1;38;2;120;169;255m'                # bold start (section headers, command names...)
export LESS_TERMCAP_me=$'\e[0m'                                 # bold/blink end (reset after bold or blink)
export LESS_TERMCAP_mh=$'\e[2;38;2;82;82;82m'                   # dim start (faded/less important text)
export LESS_TERMCAP_mr=$'\e[38;2;22;22;22;48;2;190;149;255m'    # reverse video start (swaps fg/bg colors)
export LESS_TERMCAP_so=$'\e[38;2;221;225;231;48;2;38;38;38m'    # standout start (status bar, search matches)
export LESS_TERMCAP_se=$'\e[0m'                                 # standout end (reset after standout)
export LESS_TERMCAP_us=$'\e[4;1;38;2;186;230;255m'              # underline start (option flags, emphasized text)
export LESS_TERMCAP_ue=$'\e[0m'                                 # underline end (reset after underline)
export LESS_TERMCAP_ZN=$'\e[74m'                                # subscript start
export LESS_TERMCAP_ZV=$'\e[75m'                                # subscript end
export LESS_TERMCAP_ZO=$'\e[73m'                                # superscript start
export LESS_TERMCAP_ZW=$'\e[75m'                                # superscript end

# ASKPASS stuff
export SUDO_ASKPASS="$HOME/.config/quickshell/shell/scripts/askpass.sh"
export SSH_ASKPASS="$HOME/.config/quickshell/shell/scripts/askpass.sh"
export SSH_ASKPASS_REQUIRE=force
