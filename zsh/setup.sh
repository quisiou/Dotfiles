#!/bin/sh
# zsh/setup.sh


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

echo "╔══════════════════════════════╗"
echo "║ Setting up zsh configuration ║"
echo "╚══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/zsh"

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

for file in "$ROOT_DIR"/config/*.zsh; do
    [ -e "$file" ] || continue
    target="$DEST/$(basename "$file")"
    link_file "$file" "$target"
done

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating user scripts directory structure..."

mkdir -p "$DEST/user"
private_script="$DEST/user/env.zsh"

if [ -L "$private_script" ]; then
    echo "    skipped    $private_script: file already exists (symlink)"
elif [ -e "$private_script" ]; then
    echo "    skipped    $private_script: file already exists (not symlink)"
else
    cat > "$private_script" <<EOF
#!/usr/bin/env zsh
# zsh/user/env.zsh


# Place your personal environment variables here...

EOF
    echo "    created    $private_script"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

if [ "$flag_no_link" = true ]; then
    echo "Skipping main scripts symlinks (make do on your own)"
else
    echo "Linking main zsh files..."

    for zsh_file in "$ROOT_DIR"/*.zsh; do
        [ -e "$zsh_file" ] || continue

        filename=$(basename "$zsh_file")
        target="$HOME/.${filename%.zsh}"
        link_file "$zsh_file" "$target"
    done
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Zsh configured successfully!"
