#!/bin/sh
# vencord/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
name=$(basename "$ROOT_DIR")

flag_force=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔══════════════════════════════════╗"
echo "║ Setting up Vencord configuration ║"
echo "╚══════════════════════════════════╝"
echo ""

VENCORD_DIR="$HOME/.local/share/Vencord"

cd "$ROOT_DIR"

echo "Cloning Vencord repository from GitHub..."

if [ -d "$VENCORD_DIR" ] && [ "$flag_force" = true ]; then
    echo "Force flag set, removing existing Vencord clone..."
    rm -rf "$VENCORD_DIR"
fi

if [ ! -d "$VENCORD_DIR" ]; then
    echo "Cloning Vencord to $VENCORD_DIR..."
    git clone https://github.com/Vendicated/Vencord.git "$VENCORD_DIR"
else
    echo "Vencord already present at $VENCORD_DIR, skipping clone."
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

cd "$VENCORD_DIR"

echo "Mounting and building custom plugins..."

echo "Copying files..."

PLUGIN_SOURCE="$ROOT_DIR/callStatusBridge"
PLUGIN_DIR="$VENCORD_DIR/src/userplugins"
echo "$PLUGIN_SOURCE"
echo "$PLUGIN_DIR"

mkdir -p "$PLUGIN_DIR"

cp -r "$PLUGIN_SOURCE" "$PLUGIN_DIR/"

echo "Installing dependencies..."
pnpm install --frozen-lockfile

echo "Building custom plugins..."
pnpm build

cd "$ROOT_DIR"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Vencord configured successfully!"
