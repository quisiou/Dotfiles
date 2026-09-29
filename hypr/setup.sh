#!/bin/sh
# hypr/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_force=false
flag_no_link=false
flag_overwrite=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
        --"$name"-n) flag_no_link=true ;;
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

create_file() {
    if [ -L "$USER_DIR/$1" ]; then
        echo "    skipped    $USER_DIR/$1:  file already exists (symlink)"
        return
    elif [ -e "$USER_DIR/$1" ]; then
        echo "    skipped    $USER_DIR/$1:  file already exists (not symlink)"
        return
    fi

    cat > "$USER_DIR/$1" <<EOF
-- hypr/user/$1


----- USER'S CUSTOM $2 --------------------------- #

EOF

    echo "    created   $USER_DIR/$1"
}

echo "╔═══════════════════════════════════╗"
echo "║ Setting up hyprland configuration ║"
echo "╚═══════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/hypr"
USER_DIR="$DEST/user"

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
    echo "Skipping $ROOT_DIR/hyprland.lua..."
else
    link_file "$ROOT_DIR/hyprland.lua" "$DEST/hyprland.lua"
fi

link_file "$ROOT_DIR/default" "$DEST/default"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Linking color theme file..."
link_file "$CONFIG_DIR/elysian_themes/active_theme/colors.lua" "$DEST/theme.lua"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating override files in $USER_DIR/..."

if [ "$flag_overwrite" = true ] || [ ! -e "$USER_DIR" ]; then
    rm -rf "$USER_DIR"
    mkdir -p "$USER_DIR"
    echo "    created    $USER_DIR/"
else
    echo "    skipped    $USER_DIR/: file already exists"
fi

create_file "env.lua"              "ENVIRONMENT VARIABLES CONFIGURATION"
create_file "variables.lua"        "GENERAL SETTINGS"
create_file "monitors.lua"         "MONITORS CONFIGURATION"
create_file "look_and_feel.lua"    "LOOK AND FEEL CONFIGURATION"
create_file "input.lua"            "INPUT CONFIGURATION"
create_file "keybinds.lua"         "KEYBINDS CONFIGURATION"
create_file "windowrules.lua"      "WINDOW RULES CONFIGURATION"
create_file "autostart.lua"        "AUTO START CONFIGURATION"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Hyprland configured successfully!"
