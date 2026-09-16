#!/usr/bin/bash
# Machine flows without declared drives: laptop config and no machine.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"; home="$tmp/home"; state="$tmp/state"; bin="$tmp/bin"
mkdir -p "$fixture/stow/base" "$fixture/setup" "$fixture/machines" "$home" "$bin"
printf base >"$fixture/stow/base/.base"
cp "$repo/setup/storage" "$repo/setup/hardware" "$fixture/setup/"
chmod +x "$fixture/setup/storage" "$fixture/setup/hardware"
printf 'hdr_output=HDMI-A-1\n' >"$fixture/machines/laptop.conf"
printf '#!/usr/bin/bash\nprintf "Output: 1 HDMI-A-1 id\\n\\tHDR: enabled\\n"\n' >"$bin/kscreen-doctor"
printf '#!/usr/bin/bash\nexit 0\n' >"$bin/lsblk"
printf '#!/usr/bin/bash\necho "findmnt must not run without declared drives: $*" >&2; exit 1\n' >"$bin/findmnt"
printf '#!/usr/bin/bash\necho "sudo must not run without declared drives" >&2; exit 1\n' >"$bin/sudo"
printf '#!/usr/bin/bash\nexit 0\n' >"$bin/vorta"
printf '#!/usr/bin/bash\nexit 0\n' >"$bin/borg"
chmod +x "$bin"/*

ctx() {
    HOME="$home" XDG_STATE_HOME="$state" DOTFILES_INTERACTIVE=0 DOTFILES_REPO="$fixture" \
        DOTFILES_CURRENT_DESKTOP=XFCE DOTFILES_SESSION_TYPE=x11 PATH="$bin:$PATH" "$@"
}

ctx "$repo/deploy" --machine laptop >/dev/null
out=$(ctx "$repo/configure" --machine laptop)
assert_contains "$out" 'No drives declared; nothing to do.'
assert_contains "$out" 'HDR output: HDMI-A-1'
out=$(ctx "$repo/verify" 2>"$tmp/verify-error")
[[ ! -s $tmp/verify-error ]] || fail "laptop verify wrote to stderr: $(<"$tmp/verify-error")"
assert_contains "$out" 'hardware: PASS (HDR output; machine drives)'
assert_contains "$out" 'result: PASS'
pass 'laptop without drives configures and verifies'

ctx "$repo/deploy" --no-machine >/dev/null
out=$(ctx "$repo/configure" --no-machine)
[[ $out != *storage* && $out != *hardware* && $out != *HDR* ]] || fail "machine setup ran without a machine: $out"
out=$(ctx "$repo/verify")
[[ $out != *hardware:* ]] || fail "hardware ran without a machine: $out"
assert_contains "$out" 'result: PASS'
pass 'no machine skips storage and hardware'
