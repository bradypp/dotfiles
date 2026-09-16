#!/usr/bin/bash
# setup/storage validates machine storage config before touching the system.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if "$repo/setup/storage" 2>"$tmp/error"; then
    fail 'storage setup ran without a machine config'
fi
pass 'storage setup requires a machine config argument'

printf 'unknown=value\n' >"$tmp/bad.conf"
if "$repo/setup/storage" "$tmp/bad.conf" 2>"$tmp/error"; then
    fail 'unknown machine key was accepted'
fi
assert_contains "$(<"$tmp/error")" 'Unknown machine key'
pass 'storage setup rejects unknown machine keys'

printf 'hdr_output=HDMI-A-1\ndisk1_uuid=TEST-UUID\ndisk1_mount=relative\n' >"$tmp/rel.conf"
if "$repo/setup/storage" "$tmp/rel.conf" 2>"$tmp/error"; then
    fail 'relative mount point was accepted'
fi
pass 'storage setup requires absolute mount points'

printf 'hdr_output=HDMI-A-1\n' >"$tmp/laptop.conf"
"$repo/setup/storage" "$tmp/laptop.conf" >"$tmp/out"
assert_contains "$(<"$tmp/out")" 'No drives declared; nothing to do.'
pass 'storage setup leaves machines without declared drives alone'
