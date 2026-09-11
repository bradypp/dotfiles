#!/usr/bin/bash
# Verify each root entry point delegates only its intended lifecycle stage.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
mkdir -p "$fixture/packages" "$fixture/setup/base" "$fixture/setup/wayland" "$fixture/setup/kde" "$fixture/machines"
log="$tmp/log"

for path in packages/install packages/update packages/update-user setup/base/mise setup/base/oh-my-zsh setup/base/plugins setup/wayland/copyq setup/wayland/ydotool setup/kde/klipper setup/hardware; do
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
assert_eq "$(<"$log")" $'setup/base/mise\nsetup/base/oh-my-zsh\nsetup/base/plugins\nsetup/wayland/copyq\nsetup/wayland/ydotool\nsetup/kde/klipper\nsetup/hardware'
pass 'configure runs base, detected setup directories, and machine hardware'

TEST_LOG="$log" DOTFILES_REPO="$fixture" "$repo/update"
assert_eq "$(<"$log")" $'setup/base/mise\nsetup/base/oh-my-zsh\nsetup/base/plugins\nsetup/wayland/copyq\nsetup/wayland/ydotool\nsetup/kde/klipper\nsetup/hardware\npackages/update\npackages/update-user'
pass 'update only refreshes package inventories'

commands="$tmp/commands"
mkdir -p "$commands"
: >"$log"
for command in install deploy configure verify; do
    printf '#!/usr/bin/bash\nprintf "%%s\\n" "%s" >>"$TEST_LOG"\n' "$command" >"$commands/$command"
    chmod +x "$commands/$command"
done
bootstrap_output=$(TEST_LOG="$log" DOTFILES_COMMAND_ROOT="$commands" "$repo/bootstrap" --machine home-pc)
assert_eq "$(<"$log")" $'install\ndeploy\nconfigure\nverify'
assert_contains "$bootstrap_output" 'Review POST_BOOTSTRAP.md for interactive setup.'
pass 'bootstrap runs lifecycle stages in order and points to manual steps'

: >"$log"
for command in install verify; do
    printf '#!/usr/bin/bash\nprintf "%%s\\n" "%s" >>"$TEST_LOG"\n' "$command" >"$commands/$command"
done
for command in deploy configure; do
    printf '#!/usr/bin/bash\nprintf "%%s %%s\\n" "%s" "$*" >>"$TEST_LOG"\n' "$command" >"$commands/$command"
done
chmod +x "$commands"/*
TEST_LOG="$log" DOTFILES_COMMAND_ROOT="$commands" "$repo/bootstrap" -sam home-pc >/dev/null
assert_eq "$(<"$log")" $'deploy --adopt --machine home-pc\nconfigure --machine home-pc\nverify'
pass 'bootstrap supports combined short skip-install, adopt, and machine options'

: >"$log"
TEST_LOG="$log" DOTFILES_COMMAND_ROOT="$commands" "$repo/bootstrap" -na --skip-install >/dev/null
assert_eq "$(<"$log")" $'deploy --adopt --no-machine\nconfigure --no-machine\nverify'
pass 'bootstrap supports combined short no-machine and adopt options'

if TEST_LOG="$log" DOTFILES_COMMAND_ROOT="$commands" \
    "$repo/bootstrap" -amhome-pc --skip-install >"$tmp/out" 2>"$tmp/error"; then
    fail 'bootstrap accepted an attached -m machine value'
fi

: >"$log"
TEST_LOG="$log" HOME="$tmp/configure-home" XDG_STATE_HOME="$tmp/configure-state" \
DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland \
    "$repo/configure" -m home-pc
assert_eq "$(<"$log")" $'setup/base/mise\nsetup/base/oh-my-zsh\nsetup/base/plugins\nsetup/wayland/copyq\nsetup/wayland/ydotool\nsetup/kde/klipper\nsetup/hardware'
pass 'configure supports the short machine option'
