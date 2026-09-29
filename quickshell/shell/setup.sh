#!/bin/sh
# quickshell/shell/setup.sh


CONFIG_DIR="$HOME/.config/quickshell"
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT_DIR"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating default quick apps list..."

quickAppsfile="$CONFIG_DIR/quickapps.json"

if [ -L "$quickAppsfile" ]; then
    echo "    skipped    $quickAppsfile: file already exists (symlink)"
elif [ -e "$quickAppsfile" ]; then
    echo "    skipped    $quickAppsfile: file already exists (not symlink)"
else
    cat > "$quickAppsfile" <<EOF
[
    "codium",
    "firefox",
    "vesktop",
    "steam"
]
EOF
    echo "    created    $quickAppsfile"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating default ignore apps' notifications list..."

ignoreNotificationsFile="$CONFIG_DIR/ignoreNotifications.json"

if [ -L "$ignoreNotificationsFile" ]; then
    echo "    skipped    $ignoreNotificationsFile: file already exists (symlink)"
elif [ -e "$ignoreNotificationsFile" ]; then
    echo "    skipped    $ignoreNotificationsFile: file already exists (not symlink)"
else
    cat > "$ignoreNotificationsFile" <<EOF
[
    "OpenRazer"
]
EOF
    echo "    created    $ignoreNotificationsFile"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Ensuring scripts are executable..."

[ -d scripts ] && chmod +x scripts/* 2>/dev/null
