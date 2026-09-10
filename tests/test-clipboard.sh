#!/usr/bin/bash
# Verify clipboard paste injection uses one resilient ydotool service setup.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)

setup_script="$repo/setup/wayland/ydotool"
drop_in="$repo/stow/base/.config/systemd/user/ydotool.service.d/retry-uinput.conf"
assert_file "$setup_script"
assert_file "$drop_in"
[[ ! -e $repo/stow/kde/.config/systemd/user/ydotool.service.d/retry-uinput.conf ]] ||
    fail 'ydotool retry policy is incorrectly KDE-specific'

setup_content=$(<"$setup_script")
assert_contains "$setup_content" 'enable --now ydotool.service'

drop_in_content=$(<"$drop_in")
assert_contains "$drop_in_content" 'StartLimitIntervalSec=0'
assert_contains "$drop_in_content" 'RestartSec=2'

for clipboard_setup in "$repo/setup/wayland/copyq" "$repo/setup/kde/klipper"; do
    if grep -q 'enable --now ydotool.service' "$clipboard_setup"; then
        fail "$clipboard_setup still owns ydotool service setup"
    fi
done

verify_content=$(<"$repo/verify")
assert_contains "$verify_content" 'StartLimitIntervalUSec'
assert_contains "$verify_content" '.ydotool_socket'
assert_contains "$verify_content" 'copyq config activate_pastes'
assert_contains "$verify_content" 'Wayland Support'

pass 'ydotool retries until uinput access is available'
pass 'clipboard managers share the global ydotool setup'
