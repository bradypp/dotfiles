#!/usr/bin/bash
# Verify Stow composition, pruning, and conflict handling.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
home="$tmp/home"
mkdir -p "$fixture/stow/base/.local/bin" "$fixture/stow/base/.config" "$fixture/stow/kde" "$fixture/machines" "$home"
printf base >"$fixture/stow/base/.base"
printf '#!/bin/sh\nprintf managed\\n\n' >"$fixture/stow/base/.local/bin/new-command"
printf 'plain config\n' >"$fixture/stow/base/.config/example.conf"
chmod 0644 "$fixture/stow/base/.local/bin/new-command" "$fixture/stow/base/.config/example.conf"
printf kde >"$fixture/stow/kde/.kde"
printf 'hdr_output=HDMI-A-1\n' >"$fixture/machines/home-pc.conf"

HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/deploy" --machine none
assert_link_to "$home/.base" "$fixture/stow/base/.base"
assert_link_to "$home/.kde" "$fixture/stow/kde/.kde"
[[ -x $fixture/stow/base/.local/bin/new-command ]] || fail 'shebang script was not made executable'
[[ ! -x $fixture/stow/base/.config/example.conf ]] || fail 'non-script config was made executable'
pass 'deploy composes base and detected KDE'
pass 'deploy makes shebang files executable without changing config modes'

HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/deploy" --machine home-pc >/dev/null
assert_eq "$(<"$tmp/state/dotfiles/machine")" home-pc
HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" \
DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/deploy" --no-machine >/dev/null
[[ ! -e $tmp/state/dotfiles/machine ]] || fail '--no-machine did not clear saved selection'
pass 'machine selection is optional and can be cleared explicitly'

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

wrapper=$repo/stow/base/.local/bin/dotfiles-deploy
[[ -x $wrapper ]] || fail 'dotfiles-deploy entry point is missing'
remote_home="$tmp/remote-home"
mkdir -p "$remote_home"
(
    cd /tmp
    HOME="$remote_home" XDG_STATE_HOME="$tmp/remote-state" DOTFILES_REPO="$fixture" \
    DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 \
        "$wrapper" --no-machine >/dev/null
)
assert_link_to "$remote_home/.base" "$fixture/stow/base/.base"
pass 'dotfiles-deploy runs repository deploy from any directory'
