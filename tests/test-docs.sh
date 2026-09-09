#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
assert_file "$repo/AGENTS.md"
assert_file "$repo/BACKLOG.md"
for command in bootstrap install deploy configure update verify; do
    [[ -x $repo/$command ]] || fail "missing executable root command: $command"
    assert_contains "$(<"$repo/README.md")" "\`./$command"
done
assert_contains "$(<"$repo/BACKLOG.md")" 'KDE configuration'
assert_contains "$(<"$repo/BACKLOG.md")" 'Vorta and Borg'
assert_contains "$(<"$repo/README.md")" 'machines/home-pc.conf'
pass 'documentation covers commands, machine config, and deferred work'
