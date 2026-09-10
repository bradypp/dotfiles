#!/usr/bin/bash
# Verify desktop/session and named-machine context resolution.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
source "$repo/lib/dotfiles.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/state" "$tmp/repo/machines"
printf 'hdr_output=HDMI-A-1\n' >"$tmp/repo/machines/home-pc.conf"

DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland DOTFILES_STATE_HOME="$tmp/state" DOTFILES_REPO="$tmp/repo"
dotfiles_resolve_context home-pc
assert_eq "${DOTFILES_STOW_PACKAGES[*]}" 'base kde'
assert_eq "${DOTFILES_SETUP_DIRS[*]}" 'base wayland kde'
assert_eq "$DOTFILES_MACHINE" 'home-pc'
assert_eq "$DOTFILES_MACHINE_CONFIG" "$tmp/repo/machines/home-pc.conf"
pass 'KDE Wayland and named machine compose automatically'

DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11
dotfiles_resolve_context none
assert_eq "${DOTFILES_STOW_PACKAGES[*]}" 'base'
assert_eq "${DOTFILES_SETUP_DIRS[*]}" 'base'
assert_eq "$DOTFILES_MACHINE" ''
pass 'non-KDE without machine stays base-only'

printf 'home-pc\n' >"$tmp/state/machine"
DOTFILES_CURRENT_DESKTOP= DOTFILES_SESSION_TYPE=wayland
dotfiles_resolve_context ''
assert_eq "$DOTFILES_MACHINE" 'home-pc'
assert_eq "${DOTFILES_SETUP_DIRS[*]}" 'base wayland'
pass 'saved personal machine name is reused without hostname coupling'

if dotfiles_resolve_context missing 2>"$tmp/error"; then
    fail 'missing machine config was accepted'
fi
assert_contains "$(<"$tmp/error")" 'Unknown machine: missing'
pass 'unknown machine name is rejected'
