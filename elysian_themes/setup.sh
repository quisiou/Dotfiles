#!/bin/sh
# elysian_themes/setup.sh


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

echo "╔═════════════════════════════════════════╗"
echo "║ Setting up elysian themes configuration ║"
echo "╚═════════════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/elysian_themes"

echo "Setting up $DEST..."

mkdir -p "$DEST" "$DEST/themes"

# Static content: symlinked individually (safe to re-link, these never hold user state)
ln -sf "$ROOT_DIR/set_theme.py" "$DEST/set_theme.py"
ln -sf "$ROOT_DIR/templates" "$DEST/templates"
ln -sf "$ROOT_DIR/themes/default" "$DEST/themes/default"

echo "    linked     set_theme.py, templates/, themes/default/"

# Generated/local state: real writable folders, created once, never overwritten
mkdir -p "$DEST/themes/user"

echo "    ready      themes/user/, active_theme/ (writable)"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting active theme configuration files..."

if [ -d "$DEST/active_theme" ] && [ "$flag_overwrite" = false ]; then
    echo "    skipped    $DEST/active_theme/:  directory already exists"
else
    if [ "$flag_overwrite" = true ]; then
        rm -rf "$DEST/active_theme"
        mkdir -p "$DEST/active_theme"
    fi

    python3 "$DEST/set_theme.py" "$DEST/themes/default/TokyoCarbon.toml"
    echo "    created    $DEST/active_theme/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Elysian themes configured successfully!"
