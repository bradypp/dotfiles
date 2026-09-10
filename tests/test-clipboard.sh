#!/usr/bin/bash
# Verify clipboard paste injection uses one resilient ydotool service setup.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

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

if output=$(PATH=/nonexistent XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME \
    "$repo/setup/wayland/copyq" 2>&1); then
    assert_contains "$output" 'skipped (unsupported desktop: GNOME)'
else
    fail 'unsupported Wayland desktop did not skip CopyQ integration cleanly'
fi
pass 'CopyQ skips unsupported Wayland desktops before checking dependencies'

mkdir -p "$tmp/bin"
for command_name in copyq ydotool curl sha256sum mktemp rm; do
    ln -s /usr/bin/true "$tmp/bin/$command_name"
done

for desktop_and_command in 'KDE kdotool' 'Hyprland hyprctl'; do
    read -r desktop backend_command <<<"$desktop_and_command"
    if PATH="$tmp/bin" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP="$desktop" \
        "$repo/setup/wayland/copyq" >"$tmp/out" 2>"$tmp/error"; then
        fail "$desktop CopyQ integration accepted a missing $backend_command"
    fi
    assert_contains "$(<"$tmp/error")" "Missing commands: $backend_command"
done
pass 'CopyQ checks the selected Wayland desktop backend dependency'

pass 'ydotool retries until uinput access is available'
pass 'clipboard managers share the global ydotool setup'
