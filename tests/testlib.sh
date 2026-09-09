#!/usr/bin/bash
set -euo pipefail

fail() { printf 'not ok - %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$*"; }
assert_eq() { [[ ${1-} == "${2-}" ]] || fail "expected '${2-}', got '${1-}'"; }
assert_contains() { [[ ${1-} == *"${2-}"* ]] || fail "expected '${1-}' to contain '${2-}'"; }
assert_file() { [[ -f $1 ]] || fail "missing file: $1"; }
assert_link_to() {
    [[ -L $1 ]] || fail "not a symlink: $1"
    [[ $(readlink -f -- "$1") == $(readlink -f -- "$2") ]] ||
        fail "$1 does not resolve to $2"
}
