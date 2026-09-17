#!/bin/sh
# quickshell/shell/build.sh


flag_f=false
while getopts "fn" opt; do
    case "$opt" in
        f) flag_f=true ;;
        n) ;;
        *) echo "Usage: $0 [-f]"; exit 1 ;;
    esac
done

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT_DIR"

BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/build"

echo "Building resources and dependencies..."

if [ "$flag_f" = true ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

cmake -B "$BUILD_DIR" -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
if [ $? -ne 0 ]; then
    echo "cmake configure failed, aborting..."
    exit 1
fi

cmake --build "$BUILD_DIR" --parallel
if [ $? -ne 0 ]; then
    echo "cmake build failed, aborting..."
    exit 1
fi
