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
DOTS_DIR="$HOME/.local/share/elysian-dots/vscodium"

echo "Linking main build scripts and resources..."

mkdir -p "$DOTS_DIR"

link_file "$ROOT_DIR/build_theme.py"   "$DOTS_DIR/build_theme.py" "$flag_overwrite_files"
link_file "$ROOT_DIR/build_config.py"  "$DOTS_DIR/build_config.py" "$flag_overwrite_files"
link_file "$ROOT_DIR/build_package.py" "$DOTS_DIR/build_package.py" "$flag_overwrite_files"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up configuration files..."

CODIUM_USER_DIR="$CONFIG_DIR/VSCodium/User"
mkdir -p "$CODIUM_USER_DIR"

# -f implies regenerating the config files too
[ "$flag_force" = true ] && flag_overwrite_config=true

if [ "$flag_overwrite_config" = true ]; then
    python3 "$DOTS_DIR/build_config.py" --overwrite
else
    python3 "$DOTS_DIR/build_config.py"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up color themes..."

COLOR_THEMES_DIR="$DOTS_DIR/themes"
mkdir -p "$COLOR_THEMES_DIR"

THEME_SRC_DIR="$HOME/.local/share/elysian-dots/color-themes"
if [ -d "$THEME_SRC_DIR" ]; then
    for file in "$THEME_SRC_DIR"/*; do
        [ -e "$file" ] || continue
        python3 "$DOTS_DIR/build_theme.py" "$file" "$COLOR_THEMES_DIR"
        echo "    completed  $file"
    done
else
    echo "    warning    Theme source directory missing: $THEME_SRC_DIR"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating color theme extension package file..."

PACKAGE_FILE="$DOTS_DIR/package.json"

if [ "$flag_overwrite_package" = true ]; then
    rm -f "$PACKAGE_FILE"
elif [ -L "$PACKAGE_FILE" ] && [ ! -e "$PACKAGE_FILE" ]; then
    rm "$PACKAGE_FILE"
fi

if [ -L "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (symlink)"
elif [ -e "$PACKAGE_FILE" ]; then
    echo "    skipped    $PACKAGE_FILE: file already exists (not symlink)"
elif python3 "$DOTS_DIR/build_package.py" "$DOTS_DIR"; then
    echo "    created    $PACKAGE_FILE"
else
    echo "    failed     $PACKAGE_FILE: build_package.py returned an error" >&2
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Setting up vscodium global color theme extension directory..."

# Must match "version" in package.json; VSCodium expects <publisher>.<name>-<version>
EXT_VERSION="0.1.0"
EXTENSIONS_DIR="$HOME/.vscode-oss/extensions"
EXTENSION_LINK="$EXTENSIONS_DIR/quisiou.elysian-color-themes-$EXT_VERSION"
OLD_EXTENSION_DIR="$EXTENSIONS_DIR/quisiou.elysian-color-themes-universal"

mkdir -p "$EXTENSIONS_DIR"

# Clean up the old (unversioned) layout from earlier runs
if [ -e "$OLD_EXTENSION_DIR" ] || [ -L "$OLD_EXTENSION_DIR" ]; then
    rm -rf "$OLD_EXTENSION_DIR"
    echo "    removed    $OLD_EXTENSION_DIR (old layout)"
fi

link_file "$DOTS_DIR" "$EXTENSION_LINK" "$flag_overwrite_theme"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Registering extension in extensions.json..."

python3 - "$EXTENSIONS_DIR" "$(basename "$EXTENSION_LINK")" "$EXT_VERSION" <<'EOF'
import json, sys
from pathlib import Path
d, rel, ver = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
f = d / "extensions.json"
ext_id = "quisiou.elysian-color-themes"
if not f.exists():
    print("    skipped    extensions.json missing (VSCodium will discover the extension itself)")
    sys.exit(0)
entries = [e for e in json.loads(f.read_text()) if e["identifier"]["id"].lower() != ext_id]
entries.append({"identifier": {"id": ext_id}, "version": ver,
                "location": {"$mid": 1, "path": str(d / rel), "scheme": "file"},
                "relativeLocation": rel})
f.write_text(json.dumps(entries))
print("    registered " + ext_id)
EOF

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "VSCodium configured successfully!"
