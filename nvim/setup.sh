#!/bin/sh
# nvim/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_force=false
flag_overwrite=false
flag_no_link=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-n) flag_no_link=true ;;
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

echo "╔═════════════════════════════════╗"
echo "║ Setting up neovim configuration ║"
echo "╚═════════════════════════════════╝"
echo ""


CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/nvim"

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

if [ "$flag_no_link" = true ]; then
    echo "Skipping $ROOT_DIR/init.lua..."
else
    link_file "$ROOT_DIR/init.lua" "$DEST/init.lua"
fi

link_file "$ROOT_DIR/lazy-lock.json" "$DEST/lazy-lock.json"
link_file "$ROOT_DIR/colors" "$DEST/colors"
link_file "$ROOT_DIR/lua" "$DEST/lua"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Neovim configured successfully!"
