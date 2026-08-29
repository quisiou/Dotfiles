#!/usr/bin/env bash
# quickshell/shell/scripts/askpass.sh

set -uo pipefail

PROMPT="${1:-SSH Passphrase}"
CANCEL_SENTINEL="__ASKPASS_CANCELLED__"

fallback_terminal() {
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        local passwd=""
        IFS= read -r -s -p "$PROMPT: " passwd < /dev/tty > /dev/tty 2>&1 || true
        echo > /dev/tty 2>/dev/null || true
        printf '%s\n' "$passwd"
    fi
}

FIFO="$(mktemp -u /tmp/askpass-XXXXXX.fifo)"
mkfifo -m 600 "$FIFO"
trap 'rm -f "$FIFO"' EXIT

if qs -c shell ipc call controlMenu askPass "$PROMPT" "$FIFO" >/dev/null 2>&1; then
    result="$(timeout 60 cat "$FIFO" || exit 1)"
    if [ "$result" = "$CANCEL_SENTINEL" ]; then
        exit 1   # tells sudo the user cancelled — no retry
    fi
    printf '%s\n' "$result"
else
    fallback_terminal
fi
