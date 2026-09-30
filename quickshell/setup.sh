#!/bin/sh
# quickshell/setup.sh


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

link_file() {
    src=$1
    target=$2

    if [ "$flag_overwrite" = true ]; then
        rm -rf "$target"
    elif [ -L "$target" ] && [ ! -e "$target" ]; then
        rm "$target"    # dangling symlink, replace it
    fi

    if [ -L "$target" ]; then
        echo "    skipped    $target: file already exists (symlink)"
    elif [ -e "$target" ]; then
        echo "    skipped    $target: file already exists (not symlink)"
    else
        ln -s "$src" "$target"
        echo "    linked     $src -> $target"
    fi
}

echo "╔═════════════════════════════════════╗"
echo "║ Setting up quickshell configuration ║"
echo "╚═════════════════════════════════════╝"
echo ""

. "$ROOT_DIR/../lib.sh" && require_dotfiles_home

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/quickshell"
cd "$ROOT_DIR"

echo "Setting up $DEST/..."

if [ "$flag_force" = true ] || [ ! -e "$DEST" ]; then
    rm -rf "$DEST"
    mkdir -p "$DEST"
    echo "    created    $DEST/"
else
    echo "    skipped    $DEST/: file already exists"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Linking main configuration files..."

link_file "$ROOT_DIR/shell" "$DEST/shell"
link_file "$ROOT_DIR/vesktop-overlay" "$DEST/vesktop-overlay"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Building modules..."

[ -f "build.sh" ] && chmod +x "build.sh" && ./build.sh

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

for dir in "$ROOT_DIR"/*/; do
    script="${dir}setup.sh"
    [ -f "$script" ] && sh "$script" "$@"
done

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Quickshell configured successfully!"
