#!/bin/sh
# setup.sh


DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Run the critical theme dependency first
if [ -f "$DOTFILES_DIR/elysian_themes/setup.sh" ]; then
    echo ""
    echo ""
    "$DOTFILES_DIR/elysian_themes/setup.sh" "$@"
fi

for dir in "$DOTFILES_DIR"/*/; do
    dir_name=$(basename "$dir")

    # Skip elysian_themes since it ran first
    if [ "$dir_name" = "elysian_themes" ]; then
        continue
    fi

    script="${dir}setup.sh"
    if [ -f "$script" ]; then
        echo ""
        echo ""
        sh "$script" "$@"
        echo ""
    fi
done

printf "\nAll done!\n"
