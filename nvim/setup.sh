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

mkdir -p "$DEST" "$DEST/lua"

if [ "$flag_no_link" = true ]; then
    echo "Skipping static links in $CONFIG_DIR (-n set)..."
else
    echo "Linking static files into $DEST..."

    ln -sf "$ROOT_DIR/init.lua"        "$DEST/init.lua"
    ln -sf "$ROOT_DIR/lazy-lock.json"  "$DEST/lazy-lock.json"
    ln -sf "$ROOT_DIR/colors"          "$DEST/colors"

    ln -sf "$ROOT_DIR/lua/keymaps.lua"     "$DEST/lua/keymaps.lua"
    ln -sf "$ROOT_DIR/lua/lazy-config.lua" "$DEST/lua/lazy-config.lua"
    ln -sf "$ROOT_DIR/lua/options.lua"     "$DEST/lua/options.lua"
    ln -sf "$ROOT_DIR/lua/plugins"         "$DEST/lua/plugins"

    echo "    linked     init.lua, lazy-lock.json, colors/, lua/*.lua, lua/plugins/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating symlink for theme file..."

theme_file_src="$CONFIG_DIR/elysian_themes/active_theme/colors.lua"
theme_file_dst="$DEST/lua/themes/active.lua"

mkdir -p "$(dirname "$theme_file_dst")"

if [ "$flag_overwrite" = true ]; then
    rm -f "$theme_file_dst"
fi

if [ -L "$theme_file_dst" ]; then
    echo "    skipped    $theme_file_dst: file already exists (symlink)"
elif [ -e "$theme_file_dst" ]; then
    echo "    skipped    $theme_file_dst: file already exists (not symlink)"
else
    ln -s "$theme_file_src" "$theme_file_dst"
    echo "    linked     $theme_file_src -> $theme_file_dst"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Neovim configured successfully!"
