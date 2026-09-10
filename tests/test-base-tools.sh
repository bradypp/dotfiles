#!/usr/bin/bash
# Verify base setup restores mise tools and missing tracked Herdr plugins.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
bin="$tmp/bin"
log="$tmp/log"
mkdir -p "$fixture/packages/herdr" "$bin"
printf '%s\n' kryptamine/herdr-auto-title plannotator/herdr-annotate >"$fixture/packages/herdr/plugins.txt"

cat >"$bin/mise" <<'EOF'
#!/usr/bin/bash
printf 'mise %s\n' "$*" >>"$TEST_LOG"
EOF
cat >"$bin/herdr" <<'EOF'
#!/usr/bin/bash
if [[ $1 == plugin && $2 == list ]]; then
    printf '%s\n' '- auto-title (Auto Title) enabled [github:kryptamine/herdr-auto-title@abc123]'
elif [[ $1 == plugin && $2 == install ]]; then
    printf 'herdr %s\n' "$*" >>"$TEST_LOG"
fi
EOF
chmod +x "$bin/mise" "$bin/herdr"

TEST_LOG="$log" PATH="$bin:$PATH" "$repo/setup/base/mise"
assert_eq "$(<"$log")" 'mise install'
pass 'base setup installs missing mise tools'

: >"$log"
TEST_LOG="$log" PATH="$bin:$PATH" DOTFILES_REPO="$fixture" "$repo/setup/base/plugins"
assert_eq "$(<"$log")" 'herdr plugin install plannotator/herdr-annotate --yes'
pass 'base setup installs only missing tracked Herdr plugins'
