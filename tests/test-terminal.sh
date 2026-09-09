#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)

[[ -x $repo/stow/kde/.local/bin/open-terminal ]] || fail 'open-terminal is missing'
[[ ! -e $repo/stow/kde/.local/bin/open-kde-terminal ]] || fail 'obsolete terminal command remains'
[[ ! -e $repo/stow/kde/.config/kde-xdg-terminals.list ]] || fail 'terminal default is being overridden'
[[ ! -e $repo/setup/kde/terminal ]] || fail 'unnecessary terminal setup remains'
assert_contains "$(<"$repo/stow/kde/.local/bin/open-terminal")" 'xdg-terminal-exec'
pass 'terminal launcher delegates to the existing system default'
