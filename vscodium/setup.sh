#!/bin/sh
# vscodium/setup.sh


name="vscodium"

flag_force=false
flag_overwrite_config=false
flag_overwrite_package=false
flag_overwrite_theme=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f)    flag_force=true ;;
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
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

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

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up configuration files..."

CODIUM_USER_DIR="$CONFIG_DIR/VSCodium/User"
mkdir -p "$CODIUM_USER_DIR"

python3 "$ROOT_DIR/build_config.py"

for file in "$ROOT_DIR"/config/*; do
    target="$CODIUM_USER_DIR/$(basename "$file")"
    file="$symlink_dst/config/$(basename "$file")"

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

COLOR_THEMES_DIR="$symlink_dst/themes/"
mkdir -p "$COLOR_THEMES_DIR"

THEME_SRC_DIR="$CONFIG_DIR/elysian_themes/themes/default"
if [ -d "$THEME_SRC_DIR" ]; then
    for file in "$THEME_SRC_DIR"/*; do
        [ -e "$file" ] || continue
        python3 "$ROOT_DIR/build_theme.py" "$file" "$COLOR_THEMES_DIR"
        echo "    completed  $file"
    done
else
    echo "    warning    Theme source directory missing: $THEME_SRC_DIR"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating color theme extension package file..."

PACKAGE_FILE="$symlink_dst/package.json"

if [ "$flag_overwrite_package" = true ]; then
    rm -rf "$PACKAGE_FILE"
fi

if [ -L "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (symlink)"
elif [ -e "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (not symlink)"
else
    python3 "$ROOT_DIR/build_package.py"
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
