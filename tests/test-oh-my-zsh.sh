#!/usr/bin/bash
# Verify Oh My Zsh is restored with a safe, idempotent Git clone.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bin="$tmp/bin"
home="$tmp/home"
log="$tmp/git-log"
mkdir -p "$bin" "$home"

cat >"$bin/git" <<'EOF'
#!/usr/bin/bash
printf '%q ' "$@" >>"$TEST_LOG"
printf '\n' >>"$TEST_LOG"
if [[ $1 == clone ]]; then
    mkdir -p "${@: -1}/.git"
fi
EOF
chmod +x "$bin/git"

TEST_LOG="$log" PATH="$bin:$PATH" HOME="$home" "$repo/setup/base/oh-my-zsh"
assert_eq "$(<"$log")" $'clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git '"$home"$'/.oh-my-zsh \nclone --depth=1 https://github.com/romkatv/powerlevel10k.git '"$home"$'/.oh-my-zsh/custom/themes/powerlevel10k \nclone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git '"$home"$'/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \nclone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git '"$home"'/.oh-my-zsh/custom/plugins/zsh-autosuggestions '
[[ -d $home/.oh-my-zsh/.git ]] || fail 'Oh My Zsh clone target was not created'
[[ -d $home/.oh-my-zsh/custom/themes/powerlevel10k/.git ]] || fail 'Powerlevel10k clone target was not created'
[[ -d $home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/.git ]] || fail 'zsh-syntax-highlighting clone target was not created'
[[ -d $home/.oh-my-zsh/custom/plugins/zsh-autosuggestions/.git ]] || fail 'zsh-autosuggestions clone target was not created'
pass 'missing Oh My Zsh theme and plugins are cloned into the expected home paths'

: >"$log"
TEST_LOG="$log" PATH="$bin:$PATH" HOME="$home" "$repo/setup/base/oh-my-zsh"
[[ ! -s $log ]] || fail 'existing Oh My Zsh clone was modified'
pass 'existing Oh My Zsh clone is left unchanged'

rm -rf "$home/.oh-my-zsh"
printf '%s\n' 'unmanaged content' >"$home/.oh-my-zsh"
if TEST_LOG="$log" PATH="$bin:$PATH" HOME="$home" "$repo/setup/base/oh-my-zsh" 2>"$tmp/error"; then
    fail 'non-clone Oh My Zsh target was accepted'
fi
assert_contains "$(<"$tmp/error")" "$home/.oh-my-zsh exists but is not a Git clone"
pass 'non-clone Oh My Zsh target is rejected without overwriting it'

rm -f "$home/.oh-my-zsh"
mkdir -p "$home/.oh-my-zsh/.git" "$home/.oh-my-zsh/custom/themes"
printf '%s\n' 'unmanaged content' >"$home/.oh-my-zsh/custom/themes/powerlevel10k"
if TEST_LOG="$log" PATH="$bin:$PATH" HOME="$home" "$repo/setup/base/oh-my-zsh" 2>"$tmp/error"; then
    fail 'non-clone Powerlevel10k target was accepted'
fi
assert_contains "$(<"$tmp/error")" "$home/.oh-my-zsh/custom/themes/powerlevel10k exists but is not a Git clone"
pass 'non-clone Powerlevel10k target is rejected without overwriting it'
