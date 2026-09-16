#!/bin/sh
# quickshell/shell/scripts/parse_color_themes.sh


# Output: <path>\t<name>

themes_dir="${1:?Usage: $0 <themes_dir>}"

find -L "$themes_dir" -type f -iname '*.toml' -print0 |
while IFS= read -r -d '' f; do
    name=$(awk '
        /^\[meta\]/ { in_meta=1; next }
        /^\[/       { in_meta=0 }
        in_meta && /^[ \t]*name[ \t]*=/ {
            match($0, /"([^"]*)"/, arr)
            print arr[1]
            exit
        }
    ' "$f")

    # fallback to filename without extension if name wasn't found
    if [ -z "$name" ]; then
        base=$(basename -- "$f")
        name="${base%.*}"
    fi

    printf '%s\t%s\n' "$f" "$name"
done
