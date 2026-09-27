#!/bin/sh
# elysian_themes/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_default=false
flag_force=false
flag_overwrite=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-d) flag_default=true ;;
        --"$name"-f) flag_force=true ;;
        --"$name"-o) flag_overwrite=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═════════════════════════════════════════╗"
echo "║ Setting up elysian themes configuration ║"
echo "╚═════════════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/elysian_themes"

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

    ln -sf "$ROOT_DIR/set_theme.py" "$DEST/set_theme.py"

    echo "    ready      set_theme.py, themes/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting active theme configuration files..."

if [ -d "$DEST/active_theme" ] && [ "$flag_default" = false ]; then
    echo "    skipped    $DEST/active_theme/:  directory already exists"
else
    if [ "$flag_default" = true ]; then
        rm -rf "$DEST/active_theme"
        mkdir -p "$DEST/active_theme"
    fi

    python3 "$DEST/set_theme.py" "$DEST/themes/default/TokyoCarbon.toml"
    echo "    created    $DEST/active_theme/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Elysian themes configured successfully!"
