#!/usr/bin/bash
# Verify open-terminal follows KDE's selected terminal.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

[[ -x $repo/stow/kde/.local/bin/open-terminal ]] || fail 'open-terminal is missing'
[[ ! -e $repo/stow/kde/.local/bin/open-kde-terminal ]] || fail 'obsolete terminal command remains'
[[ ! -e $repo/stow/kde/.config/kde-xdg-terminals.list ]] || fail 'terminal default is being overridden'
[[ ! -e $repo/setup/kde/terminal ]] || fail 'unnecessary terminal setup remains'

mkdir "$tmp/bin" "$tmp/config"
printf '#!/bin/sh\nprintf "kitty.desktop\\n"\n' >"$tmp/bin/kreadconfig6"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >"%s"\n' "$tmp/launched" >"$tmp/bin/xdg-terminal-exec"
printf '#!/bin/sh\nprintf "wrong launcher\\n" >"%s"\n' "$tmp/launched" >"$tmp/bin/gtk-launch"
chmod +x "$tmp/bin/"*
XDG_CONFIG_HOME="$tmp/config" PATH="$tmp/bin:$PATH" "$repo/stow/kde/.local/bin/open-terminal" /bin/printf '%s' 'two words'
assert_eq "$(<"$tmp/launched")" '-- /bin/printf %s two words'
assert_eq "$(<"$tmp/config/kde-xdg-terminals.list")" 'kitty.desktop'
verify_content=$(<"$repo/verify")
assert_contains "$verify_content" 'kreadconfig6'
if [[ $verify_content == *'xdg-terminal-exec --print-id'* ]]; then
    fail 'verify checks xdg-terminal-exec instead of the KDE terminal setting'
fi
pass 'terminal launcher follows the KDE default'
