#!/bin/sh
# yazi/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_overwrite=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) ;;
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═══════════════════════════════╗"
echo "║ Setting up yazi configuration ║"
echo "╚═══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/yazi"

echo "Setting up $DEST..."

mkdir -p "$DEST"
ln -sf "$ROOT_DIR/keymap.toml" "$DEST/keymap.toml"
echo "    linked     keymap.toml"

ln -sf "$ROOT_DIR/yazi.toml"   "$DEST/yazi.toml"
echo "    linked     yazi.toml"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

target="$DEST/theme.toml"
dir="$CONFIG_DIR/elysian_themes/active_theme/yazi.toml"

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

echo "Yazi configured successfully!"
