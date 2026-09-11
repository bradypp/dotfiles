#!/usr/bin/bash
# Verify dotfiles-stow imports home paths into selected Stow packages.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
home="$tmp/home"
commands="$tmp/commands"
log="$tmp/stow.log"
mkdir -p "$fixture/stow/base/.local/bin" "$fixture/stow/work" "$home/.config/example" "$commands"
printf '#!/usr/bin/bash\n' >"$fixture/deploy"
chmod +x "$fixture/deploy"
cp "$repo/stow/base/.local/bin/dotfiles-stow" "$fixture/stow/base/.local/bin/dotfiles-stow"
chmod +x "$fixture/stow/base/.local/bin/dotfiles-stow"
cat >"$commands/stow" <<'STOW'
#!/usr/bin/bash
printf '%s\n' "$*" >>"$TEST_LOG"
[[ ${TEST_STOW_FAIL:-false} != true ]]
STOW
chmod +x "$commands/stow"
command="$fixture/stow/base/.local/bin/dotfiles-stow"

printf 'base config\n' >"$home/.config/example/base.conf"
HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" "$home/.config/example/base.conf"
assert_file "$fixture/stow/base/.config/example/base.conf"
assert_eq "$(<"$fixture/stow/base/.config/example/base.conf")" 'base config'
assert_eq "$(<"$log")" "--restow --no-folding --dir=$fixture/stow --target=$home base"
pass 'dotfiles-stow imports into the existing base package by default'

: >"$log"
printf 'work config\n' >"$home/.config/example/work.conf"
HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" -p work "$home/.config/example/work.conf"
assert_file "$fixture/stow/work/.config/example/work.conf"
assert_eq "$(<"$log")" "--restow --no-folding --dir=$fixture/stow --target=$home work"
pass 'dotfiles-stow -p imports into an existing named package'

: >"$log"
printf 'new config\n' >"$home/.config/example/new.conf"
HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" -c personal "$home/.config/example/new.conf"
assert_file "$fixture/stow/personal/.config/example/new.conf"
assert_eq "$(<"$log")" "--restow --no-folding --dir=$fixture/stow --target=$home personal"
pass 'dotfiles-stow -c creates and selects a named package'

: >"$log"
mkdir -p "$fixture/stow/long"
printf 'long package\n' >"$home/.config/example/long.conf"
HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" --package long "$home/.config/example/long.conf"
assert_file "$fixture/stow/long/.config/example/long.conf"
printf 'long create\n' >"$home/.config/example/long-create.conf"
HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" --create-package long-new "$home/.config/example/long-create.conf"
assert_file "$fixture/stow/long-new/.config/example/long-create.conf"
pass 'dotfiles-stow supports long package options'

printf 'missing package\n' >"$home/.config/example/missing.conf"
if HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" -p missing "$home/.config/example/missing.conf" >"$tmp/out" 2>"$tmp/err"; then
    fail 'dotfiles-stow accepted a missing package without -c'
fi
assert_file "$home/.config/example/missing.conf"
assert_contains "$(<"$tmp/err")" "Package does not exist: missing"
pass 'dotfiles-stow refuses a missing package without -c'

printf 'outside\n' >"$tmp/outside.conf"
if HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" "$tmp/outside.conf" >"$tmp/out" 2>"$tmp/err"; then
    fail 'dotfiles-stow accepted a path outside HOME'
fi
assert_file "$tmp/outside.conf"
assert_contains "$(<"$tmp/err")" 'Path must be inside HOME'
pass 'dotfiles-stow refuses paths outside HOME'

printf 'duplicate\n' >"$home/.config/example/duplicate.conf"
mkdir -p "$fixture/stow/base/.config/example/duplicate.conf"
if HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" \
    "$command" "$home/.config/example/duplicate.conf" >"$tmp/out" 2>"$tmp/err"; then
    fail 'dotfiles-stow overwrote an existing repository destination'
fi
assert_file "$home/.config/example/duplicate.conf"
assert_contains "$(<"$tmp/err")" 'Repository destination already exists'
pass 'dotfiles-stow refuses an existing repository destination'

printf 'rollback\n' >"$home/.config/example/rollback.conf"
if HOME="$home" PATH="$commands:/usr/bin:/bin" TEST_LOG="$log" TEST_STOW_FAIL=true \
    "$command" "$home/.config/example/rollback.conf" >"$tmp/out" 2>"$tmp/err"; then
    fail 'dotfiles-stow succeeded when Stow failed'
fi
assert_file "$home/.config/example/rollback.conf"
[[ ! -e $fixture/stow/base/.config/example/rollback.conf ]] ||
    fail 'failed import remained in the repository'
assert_contains "$(<"$tmp/err")" 'Stow failed; restored the original path.'
pass 'dotfiles-stow restores the original path when Stow fails'
