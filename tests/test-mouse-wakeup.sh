#!/usr/bin/bash
# Verify mouse wakeup rule installation in an isolated filesystem root.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
assert_file "$repo/setup/mouse-wakeup"
"$repo/setup/mouse-wakeup" --root "$tmp"
rule="$tmp/etc/udev/rules.d/90-logitech-g502x-wakeup.rules"
assert_file "$rule"
assert_contains "$(<"$rule")" 'ATTR{idVendor}=="046d", ATTR{idProduct}=="c099"'
assert_contains "$(<"$rule")" 'ATTR{power/wakeup}="enabled"'
udevadm verify "$rule"
assert_eq "$(stat -c %a "$rule")" 644
pass 'installs a valid rule for only the G502 X'
before=$(stat -c '%i:%Y' "$rule")
"$repo/setup/mouse-wakeup" --root "$tmp" >/dev/null
assert_eq "$(stat -c '%i:%Y' "$rule")" "$before"
pass 'rerunning leaves an identical rule untouched'
printf '# existing user rule\n' >"$rule"
if "$repo/setup/mouse-wakeup" --root "$tmp" >"$tmp/out" 2>&1; then
    fail 'overwrote a conflicting rule'
fi
assert_eq "$(<"$rule")" '# existing user rule'
pass 'refuses to overwrite conflicting configuration'
