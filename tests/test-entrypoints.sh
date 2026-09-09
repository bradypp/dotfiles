#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
mkdir -p "$fixture/packages" "$fixture/setup/wayland" "$fixture/setup/kde" "$fixture/machines"
log="$tmp/log"

for path in packages/install packages/update setup/wayland/copyq setup/kde/klipper setup/kde/terminal setup/hardware; do
    mkdir -p "$fixture/${path%/*}"
    printf '#!/usr/bin/bash\nprintf "%%s\\n" "%s" >>"$TEST_LOG"\n' "$path" >"$fixture/$path"
    chmod +x "$fixture/$path"
done
printf 'hdr_output=HDMI-A-1\n' >"$fixture/machines/home-pc.conf"

TEST_LOG="$log" DOTFILES_REPO="$fixture" "$repo/install"
assert_eq "$(<"$log")" 'packages/install'
pass 'install only restores packages'

: >"$log"
TEST_LOG="$log" HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" \
DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/configure" --machine home-pc
assert_eq "$(<"$log")" $'setup/wayland/copyq\nsetup/kde/klipper\nsetup/kde/terminal\nsetup/hardware'
pass 'configure runs only detected setup directories and machine hardware'

TEST_LOG="$log" DOTFILES_REPO="$fixture" "$repo/update"
assert_eq "$(<"$log")" $'setup/wayland/copyq\nsetup/kde/klipper\nsetup/kde/terminal\nsetup/hardware\npackages/update'
pass 'update only refreshes package inventories'

commands="$tmp/commands"
mkdir -p "$commands"
: >"$log"
for command in install deploy configure verify; do
    printf '#!/usr/bin/bash\nprintf "%%s\\n" "%s" >>"$TEST_LOG"\n' "$command" >"$commands/$command"
    chmod +x "$commands/$command"
done
TEST_LOG="$log" DOTFILES_COMMAND_ROOT="$commands" "$repo/bootstrap" --machine home-pc
assert_eq "$(<"$log")" $'install\ndeploy\nconfigure\nverify'
pass 'bootstrap runs lifecycle stages in order'
