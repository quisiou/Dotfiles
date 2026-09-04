#!/bin/sh
# hypr/setup.sh


name="hypr"

flag_force=false
flag_no_link=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
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
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
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

if [ "$flag_no_link" = true ]; then
    echo "Skipping symlink in $CONFIG_DIR (-n set)..."
else
    echo "Creating symlink in $CONFIG_DIR..."

    symlink_src="${ROOT_DIR%/}"
    symlink_dst="$CONFIG_DIR/$(basename "$symlink_src")"

    if [ "$flag_force" = true ]; then
        rm -f "$symlink_dst"
    fi

    if [ -L "$symlink_dst" ]; then
        echo "    skipped    $symlink_dst: file already exists (symlink)"
    elif [ -e "$symlink_dst" ]; then
        echo "    skipped    $symlink_dst: file already exists (not symlink)"
    else
        ln -s "$symlink_src" "$symlink_dst"
        echo "    linked     $symlink_src -> $symlink_dst"
    fi
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating symlink for theme file..."

theme_file_src="$CONFIG_DIR/elysian_themes/active_theme/colors.lua"
theme_file_dst="$ROOT_DIR/theme.lua"

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

mkdir -p "$USER_DIR"

create_file "env.lua"              "ENVIRONMENT VARIABLES CONFIGURATION"
create_file "variables.lua"        "GENERAL SETTINGS"
create_file "monitors.lua"         "MONITORS CONFIGURATION"
create_file "look_and_feel.lua"    "LOOK AND FEEL CONFIGURATION"
create_file "input.lua"            "INPUT CONFIGURATION"
create_file "keybinds.lua"         "KEYBINDS CONFIGURATION"
create_file "windowrules.lua"      "WINDOW RULES CONFIGURATION"
create_file "autostart.lua"        "AUTO START CONFIGURATION"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Edit files in $USER_DIR to override defaults."

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Hyprland configured successfully!"
