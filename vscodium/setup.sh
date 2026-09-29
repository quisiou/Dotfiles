#!/bin/sh
# vscodium/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_force=false
flag_overwrite_config=false
flag_overwrite_files=false
flag_overwrite_package=false
flag_overwrite_theme=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f)    flag_force=true ;;
        --"$name"-oC)   flag_overwrite_config=true ;;
        --"$name"-oF)   flag_overwrite_files=true ;;
        --"$name"-oP)   flag_overwrite_package=true ;;
        --"$name"-oT)   flag_overwrite_theme=true ;;
        --"$name"-*)    echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

link_file() {
    src=$1
    target=$2
    ow_flag=$3

    if [ "$ow_flag" = true ]; then
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

echo "╔═══════════════════════════════════╗"
echo "║ Setting up VSCodium configuration ║"
echo "╚═══════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/vscodium"

echo "Setting up $DEST/..."

if [ "$flag_force" = true ] || [ ! -e "$DEST" ]; then
    rm -rf "$DEST"
    mkdir -p "$DEST"
    echo "    created    $DEST/"
else
    echo "    skipped    $DEST/: file already exists"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Linking main build scripts and resources..."

link_file "$ROOT_DIR/build_theme.py"   "$DEST/build_theme.py" "$flag_overwrite_files"
link_file "$ROOT_DIR/build_config.py"  "$DEST/build_config.py" "$flag_overwrite_files"
link_file "$ROOT_DIR/build_package.py" "$DEST/build_package.py" "$flag_overwrite_files"
link_file "$ROOT_DIR/template.json"    "$DEST/template.json" "$flag_overwrite_files"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up configuration files..."

CODIUM_USER_DIR="$CONFIG_DIR/VSCodium/User"
mkdir -p "$CODIUM_USER_DIR"

CONFIG_GEN_DIR="$DEST/config"
mkdir -p "$CONFIG_GEN_DIR"

python3 "$DEST/build_config.py"

for file in "$CONFIG_GEN_DIR"/*; do
    [ -e "$file" ] || continue
    target="$CODIUM_USER_DIR/$(basename "$file")"
    link_file "$file" "$target" "$flag_overwrite_config"
done

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up color themes..."

COLOR_THEMES_DIR="$DEST/themes/"
mkdir -p "$COLOR_THEMES_DIR"

THEME_SRC_DIR="$CONFIG_DIR/elysian_themes/themes/default"
if [ -d "$THEME_SRC_DIR" ]; then
    for file in "$THEME_SRC_DIR"/*; do
        [ -e "$file" ] || continue
        python3 "$DEST/build_theme.py" "$file" "$COLOR_THEMES_DIR"
        echo "    completed  $file"
    done
else
    echo "    warning    Theme source directory missing: $THEME_SRC_DIR"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating color theme extension package file..."

PACKAGE_FILE="$DEST/package.json"

if [ "$flag_overwrite_package" = true ]; then
    rm -f "$PACKAGE_FILE"
elif [ -L "$PACKAGE_FILE" ] && [ ! -e "$PACKAGE_FILE" ]; then
    rm "$PACKAGE_FILE"    # dangling symlink, replace it
fi

if [ -L "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (symlink)"
elif [ -e "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (not symlink)"
else
    python3 "$DEST/build_package.py"
    echo "    created    $PACKAGE_FILE"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up vscodium global color theme extension directory..."

EXTENSION_DIR="$HOME/.vscode-oss/extensions/quisiou.elysian-color-themes-universal"
mkdir -p "$EXTENSION_DIR"

for file in "$COLOR_THEMES_DIR" "$PACKAGE_FILE"; do
    file="${file%/}"
    target="$EXTENSION_DIR/$(basename "$file")"
    link_file "$file" "$target" "$flag_overwrite_theme"
done

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "VSCodium configured successfully!"
