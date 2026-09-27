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

echo "╔══════════════════════════════╗"
echo "║ Setting up zsh configuration ║"
echo "╚══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
DEST="$CONFIG_DIR/zsh"

if [ "$flag_force" = false ] && [ -e "$DEST" ]; then
    echo "    skipped    $DEST: file already exists (not symlink)"
else
    echo "Setting up $DEST..."

    rm -rf "$DEST"

    mkdir -p "$DEST"

    for file in "$ROOT_DIR"/config/*.zsh; do
        [ -e "$file" ] || continue
        target="$DEST/$(basename "$file")"

        if [ "$flag_overwrite" = true ]; then
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

    echo "    ready      $DEST"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Creating user scripts directory structure..."

if [ -w "$ROOT_DIR" ]; then
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
else
    echo "    skipped    $ROOT_DIR/user: source is read-only, user script not created"
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

if [ "$flag_no_link" = true ]; then
    echo "Skipping main scripts symlinks (make do on your own)"
else
    echo "Linking main scripts..."

    for zsh_file in "$ROOT_DIR"/*.zsh; do
        [ -e "$zsh_file" ] || continue

        filename=$(basename "$zsh_file")
        target="$HOME/.${filename%.zsh}"

        if [ -L "$target" ]; then
            echo "    skipped    $target: file already exists (symlink)"
        elif [ -e "$target" ]; then
            echo "    skipped    $target: file already exists (not symlink)"
        else
            ln -s "$zsh_file" "$target"
            echo "    linked     $zsh_file -> $target"
        fi
    done
fi

echo "╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌"

echo "Zsh configured successfully!"
