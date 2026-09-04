#!/bin/sh
# quickshell/shell/setup.sh


ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT_DIR"

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating default quick apps list..."

quickAppsfile="quickapps.json"

if [ -L "$quickAppsfile" ]; then
    echo "    skipped    $quickAppsfile: file already exists (symlink)"
elif [ -e "$quickAppsfile" ]; then
    echo "    skipped    $quickAppsfile: file already exists (not symlink)"
else
    cat > $quickAppsfile <<EOF
[
    "codium",
    "firefox",
    "vesktop",
    "steam",
    "gimp"
]
EOF
    echo "    created    $quickAppsfile"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating default ignore apps' notifications list..."

ignoreNotificationsFile="ignoreNotifications.json"

if [ -L "$ignoreNotificationsFile" ]; then
    echo "    skipped    $ignoreNotificationsFile: file already exists (symlink)"
elif [ -e "$ignoreNotificationsFile" ]; then
    echo "    skipped    $ignoreNotificationsFile: file already exists (not symlink)"
else
    cat > $ignoreNotificationsFile <<EOF
[
    "OpenRazer"
]
EOF
    echo "    created    $ignoreNotificationsFile"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Ensuring scripts are executable..."

[ -d scripts ] && chmod +x scripts/*
