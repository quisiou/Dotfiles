# lib.sh


# Ensure ELYSIAN_DOTS_HOME is set so no modules fail
require_dotfiles_home() {
    if [ -z "${ELYSIAN_DOTS_HOME:-}" ]; then
        echo "Error: ELYSIAN_DOTS_HOME is not set." >&2
        echo "       Set up the zsh module and re-login (or 'source ~/.zprofile')," >&2
        echo "       or export it yourself. See README." >&2
        exit 1
    fi
}
