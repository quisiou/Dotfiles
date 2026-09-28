#!/bin/sh
# btop/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_force=false
flag_overwrite=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═══════════════════════════════╗"
echo "║ Setting up btop configuration ║"
echo "╚═══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/btop"

echo "Setting up $DEST..."

mkdir -p "$DEST"
ln -sf "$ROOT_DIR/btop.conf" "$DEST/btop.conf"

echo "    linked     btop.conf"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

target="$DEST/active.theme"
dir="$CONFIG_DIR/elysian_themes/active_theme/btop.theme"

echo "Setting up color theme configuration file..."

if [ "$flag_overwrite" = true ]; then
    rm -f "$target"
fi

if [ -L "$target" ]; then
    echo "    skipped    $target: file already exists (symlink)"
elif [ -e "$target" ]; then
    echo "    skipped    $target: file already exists (not symlink)"
else
    ln -s "$dir" "$target"
    echo "    linked     $dir -> $target"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Btop configured successfully!"
