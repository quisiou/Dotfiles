#!/bin/sh
# nvim/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_overwrite=false
flag_no_link=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) ;;
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-n) flag_no_link=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═════════════════════════════════╗"
echo "║ Setting up neovim configuration ║"
echo "╚═════════════════════════════════╝"
echo ""


CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/nvim"

mkdir -p "$DEST"

if [ "$flag_no_link" = false ]; then
    ln -sf "$ROOT_DIR/init.lua"        "$DEST/init.lua"
    echo "    linked     init.lua"
fi

echo "Linking static files into $DEST..."

ln -sf "$ROOT_DIR/lazy-lock.json"  "$DEST/lazy-lock.json"
ln -sf "$ROOT_DIR/colors"          "$DEST/colors"
ln -sf "$ROOT_DIR/lua/"            "$DEST/lua"

echo "    linked     init.lua, lazy-lock.json, colors/, lua/"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Neovim configured successfully!"
