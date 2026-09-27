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

if [ "$flag_force" = false ] && [ -e "$DEST" ]; then
    echo "    skipped    $DEST: file already exists (not symlink)"
else
    echo "Setting up $DEST..."

    THEMES_DIR="$DEST/themes"

    rm -rf "$DEST"

    mkdir -p "$THEMES_DIR"

    for file in "$ROOT_DIR"/themes/*; do
        [ -e "$file" ] || continue
        target="$THEMES_DIR/$(basename "$file")"

        if [ "$flag_overwrite" = true ]; then
            rm -rf "$target"
        fi

        if [ -L "$target" ]; then
            echo "    skipped    $target: file already exists (symlink)"
        elif [ -e "$target" ]; then
            echo "    skipped    $target: file already exists (not symlink)"
        else
            ln -s "$file" "$target"
            echo "    linked     $file -> $target"
        fi
    done

    ln -sf "$ROOT_DIR/btop.conf" "$DEST/btop.conf"

    echo "    ready      btop.conf, themes/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Btop configured successfully!"
