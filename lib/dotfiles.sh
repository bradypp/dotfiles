#!/usr/bin/bash
# Shared, side-effect-free composition helpers.

: "${DOTFILES_REPO:=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)}"
: "${DOTFILES_STATE_HOME:=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}"
: "${DOTFILES_CURRENT_DESKTOP:=${XDG_CURRENT_DESKTOP:-}}"
: "${DOTFILES_SESSION_TYPE:=${XDG_SESSION_TYPE:-}}"

_dotfiles_append_unique() {
    local array_name=$1 value=$2 existing
    local -n array_ref=$array_name
    for existing in "${array_ref[@]-}"; do
        [[ $existing == "$value" ]] && return 0
    done
    array_ref+=("$value")
}

dotfiles_is_kde() {
    local desktop=${1:-$DOTFILES_CURRENT_DESKTOP}
    [[ :${desktop^^}: == *:KDE:* ]]
}

dotfiles_resolve_context() {
    local override=${1-} saved=''
    DOTFILES_STOW_PACKAGES=(base)
    DOTFILES_SETUP_DIRS=(base)
    DOTFILES_MACHINE_CONFIG=''

    if [[ ${DOTFILES_SESSION_TYPE,,} == wayland ]]; then
        _dotfiles_append_unique DOTFILES_SETUP_DIRS wayland
    fi
    if dotfiles_is_kde; then
        _dotfiles_append_unique DOTFILES_STOW_PACKAGES kde
        _dotfiles_append_unique DOTFILES_SETUP_DIRS kde
    fi

    if [[ -z $override && -r $DOTFILES_STATE_HOME/machine ]]; then
        IFS= read -r saved <"$DOTFILES_STATE_HOME/machine" || true
        override=$saved
    fi

    case $override in
        ''|none)
            DOTFILES_MACHINE=''
            ;;
        *[!A-Za-z0-9._-]*|.*|*/*)
            printf 'Invalid machine name: %s\n' "$override" >&2
            return 1
            ;;
        *)
            DOTFILES_MACHINE_CONFIG="$DOTFILES_REPO/machines/$override.conf"
            if [[ ! -f $DOTFILES_MACHINE_CONFIG ]]; then
                printf 'Unknown machine: %s\n' "$override" >&2
                return 1
            fi
            DOTFILES_MACHINE=$override
            ;;
    esac
}
