#!/bin/sh
# quickshell/build.sh


flag_f=false
while getopts "fn" opt; do
    case "$opt" in
        f) flag_f=true ;;
        n) ;;
        *) echo "Usage: $0 [-f]"; exit 1 ;;
    esac
done

BUILD_DIR="$HOME/.config/quickshell/.build"
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT_DIR"

echo "Building resources and dependencies..."

if [ "$flag_f" = true ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

if ! cmake -B "$BUILD_DIR" -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON; then
    echo "cmake configure failed, aborting..."
    exit 1
fi

if ! cmake --build "$BUILD_DIR" --parallel; then
    echo "cmake build failed, aborting..."
    exit 1
fi
