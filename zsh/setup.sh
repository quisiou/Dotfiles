#!/bin/sh
# zsh/setup.sh


name="zsh"

flag_force=false
flag_no_link=false

for arg in "$@"; do
    case "$arg" in
        --"$name"-f) flag_force=true ;;
        --"$name"-n) flag_no_link=true ;;
        --"$name"-*) echo "Warning: unrecognized flag '$arg' for $name" >&2 ;;
        *) ;;            # not my flag, ignore
    esac
done

echo "╔══════════════════════════════╗"
echo "║ Setting up zsh configuration ║"
echo "╚══════════════════════════════╝"
echo ""

CONFIG_DIR="$HOME/.config"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo "Creating user scripts directory structure..."

mkdir -p "$ROOT_DIR/user"
private_script="$ROOT_DIR/user/env.zsh"

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
