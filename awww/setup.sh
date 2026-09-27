#!/bin/sh
# awww/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_overwrite=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═══════════════════════════════╗"
echo "║ Setting up awww configuration ║"
echo "╚═══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/awww"

echo "Setting up $DEST..."

mkdir -p "$DEST"
ln -sf "$ROOT_DIR/default" "$DEST/default"
echo "    linked     default/"

mkdir -p "$DEST/user"
echo "    ready      user/ (writable)"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting default wallpaper if cache is missing..."

AWWW_VERSION=$(awww --version | awk '{print $2}')

if [ -z "$AWWW_VERSION" ]; then
    echo "Error: Could not detect awww version."
    exit 1
fi

# This only works for 1 monitor

CACHE_FILE="$HOME/.cache/awww/$AWWW_VERSION/eDP-1"

if [ -f "$CACHE_FILE" ] && [ "$flag_overwrite" = false ]; then
    echo "    skipped    $CACHE_FILE:  cached wallpaper already exists"
else
    awww img "$DEST/default/Leshy.jpg" --transition-type center
    echo "    created    $CACHE_FILE"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Awww configured successfully!"
