#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
home="$tmp/home"
mkdir -p "$fixture/stow/base" "$fixture/stow/kde" "$fixture/machines" "$home"
printf base >"$fixture/stow/base/.base"
printf kde >"$fixture/stow/kde/.kde"

HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/deploy" --machine none
assert_link_to "$home/.base" "$fixture/stow/base/.base"
assert_link_to "$home/.kde" "$fixture/stow/kde/.kde"
pass 'deploy composes base and detected KDE'

HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 \
    "$repo/deploy" --machine none
assert_link_to "$home/.base" "$fixture/stow/base/.base"
[[ ! -e $home/.kde && ! -L $home/.kde ]] || fail 'inactive KDE link remained'
pass 'deploy unstows known inactive packages without saved package state'

printf old >"$fixture/stow/base/.old"
HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 \
    "$repo/deploy" --machine none
assert_link_to "$home/.old" "$fixture/stow/base/.old"
rm "$fixture/stow/base/.old"
HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 \
    "$repo/deploy" --machine none
[[ ! -e $home/.old && ! -L $home/.old ]] || fail 'restow did not prune stale link'
pass 'restow adds and removes package files'

rm "$home/.base"
printf unmanaged >"$home/.base"
if HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
   DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 \
       "$repo/deploy" --machine none 2>"$tmp/error"; then
    fail 'unmanaged conflict was overwritten'
fi
assert_eq "$(<"$home/.base")" unmanaged
pass 'deploy refuses unmanaged conflicts'
