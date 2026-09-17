#!/bin/sh
# hypr/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_no_link=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) ;;
        --"$name"-n) flag_no_link=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═══════════════════════════════════╗"
echo "║ Setting up hyprland configuration ║"
echo "╚═══════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/hypr"
USER_DIR="$ROOT_DIR/user"

create_file() {
    if [ -f "$USER_DIR/$1" ]; then
        echo "    skipped    $USER_DIR/$1:  file already exists"
        return
    fi

    cat > "$USER_DIR/$1" <<EOF
-- hypr/user/$1


----- USER'S CUSTOM $2 --------------------------- #

EOF

    echo "    created   $USER_DIR/$1"
}

mkdir -p "$DEST"

if [ "$flag_no_link" = true ]; then
    echo "Skipping default/user/hyprland.lua links in $CONFIG_DIR (-n set)..."
else
    echo "Linking static files into $DEST..."

    ln -sf "$ROOT_DIR/hyprland.lua" "$DEST/hyprland.lua"
    echo "    linked     hyprland.lua"

    ln -sf "$ROOT_DIR/default"      "$DEST/default"
    echo "    linked     default/"

    ln -sf "$ROOT_DIR/user"         "$DEST/user"
    echo "    linked     user/"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating symlink for theme file..."

theme_file_src="$CONFIG_DIR/elysian_themes/active_theme/colors.lua"
theme_file_dst="$DEST/theme.lua"

if [ -L "$theme_file_dst" ]; then
    echo "    skipped    $theme_file_dst: file already exists (symlink)"
elif [ -e "$theme_file_dst" ]; then
    echo "    skipped    $theme_file_dst: file already exists (not symlink)"
else
    ln -s "$theme_file_src" "$theme_file_dst"
    echo "    linked     $theme_file_src -> $theme_file_dst"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating override files in hypr/user/ directory..."

if [ -w "$ROOT_DIR" ]; then
    mkdir -p "$USER_DIR"

    create_file "env.lua"              "ENVIRONMENT VARIABLES CONFIGURATION"
    create_file "variables.lua"        "GENERAL SETTINGS"
    create_file "monitors.lua"         "MONITORS CONFIGURATION"
    create_file "look_and_feel.lua"    "LOOK AND FEEL CONFIGURATION"
    create_file "input.lua"            "INPUT CONFIGURATION"
    create_file "keybinds.lua"         "KEYBINDS CONFIGURATION"
    create_file "windowrules.lua"      "WINDOW RULES CONFIGURATION"
    create_file "autostart.lua"        "AUTO START CONFIGURATION"

    echo "Edit files in $USER_DIR to override defaults."
else
    echo "    skipped    $USER_DIR: source is read-only, override stubs not created"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Hyprland configured successfully!"
