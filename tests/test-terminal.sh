#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
bin="$tmp/bin"
mkdir -p "$home/.config" "$bin" "$tmp/applications"
printf 'kitty.desktop\n' >"$home/.config/kde-xdg-terminals.list"
printf '[Desktop Entry]\nName=Kitty\n' >"$tmp/applications/kitty.desktop"
printf '#!/usr/bin/bash\ncase $1 in --print-id) echo kitty.desktop;; --print-path) echo "$TEST_APPS/kitty.desktop";; --print-cmd) echo kitty;; *) exit 2;; esac\n' >"$bin/xdg-terminal-exec"
chmod +x "$bin/xdg-terminal-exec"

HOME="$home" PATH="$bin:$PATH" XDG_DATA_DIRS="$tmp" TEST_APPS="$tmp/apps" \
    "$repo/setup/kde/terminal" >"$tmp/out"
assert_contains "$(<"$tmp/out")" 'kitty.desktop'
pass 'terminal setup verifies the explicitly selected desktop ID'

[[ -x $repo/stow/kde/.local/bin/open-terminal ]] || fail 'open-terminal is missing'
[[ ! -e $repo/stow/kde/.local/bin/open-kde-terminal ]] || fail 'obsolete terminal command remains'
assert_contains "$(<"$repo/stow/kde/.local/bin/open-terminal")" 'xdg-terminal-exec'
pass 'KDE terminal launcher uses xdg-terminal-exec'
