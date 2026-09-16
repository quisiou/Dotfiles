#!/bin/sh
# vscodium/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_overwrite_config=false
flag_overwrite_package=false
flag_overwrite_theme=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) ;;
        --"$name"-oC)   flag_overwrite_config=true ;;
        --"$name"-oP)   flag_overwrite_package=true ;;
        --"$name"-oT)   flag_overwrite_theme=true ;;
        --"$name"-*)    echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔═══════════════════════════════════╗"
echo "║ Setting up VSCodium configuration ║"
echo "╚═══════════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/vscodium"

echo "Setting up $DEST..."

mkdir -p "$DEST"

ln -sf "$ROOT_DIR/build_config.py"  "$DEST/build_config.py"
ln -sf "$ROOT_DIR/build_theme.py"   "$DEST/build_theme.py"
ln -sf "$ROOT_DIR/build_package.py" "$DEST/build_package.py"
ln -sf "$ROOT_DIR/template.json"    "$DEST/template.json"

echo "    linked     build_config.py, build_theme.py, build_package.py, template.json"

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

    if [ "$flag_overwrite_config" = true ]; then
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
fi

if [ -e "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists"
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

    if [ "$flag_overwrite_theme" = true ]; then
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

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "VSCodium configured successfully!"
