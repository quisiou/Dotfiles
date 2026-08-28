#!/usr/bin/env bash
# quickshell/shell/scripts/ssh-askpass.sh

set -uo pipefail

PROMPT="${1:-SSH Passphrase}"

fallback_terminal() {
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        local passwd=""
        IFS= read -r -s -p "$PROMPT: " passwd < /dev/tty > /dev/tty 2>&1 || true
        echo > /dev/tty 2>/dev/null || true
        printf '%s\n' "$passwd"
    fi
}

FIFO="$(mktemp -u /tmp/ssh-askpass-XXXXXX.fifo)"
mkfifo -m 600 "$FIFO"
trap 'rm -f "$FIFO"' EXIT

if qs -c shell ipc call controlMenu sshAskPass "$PROMPT" "$FIFO" >/dev/null 2>&1; then
    timeout 60 cat "$FIFO" || true
else
    fallback_terminal
fi
