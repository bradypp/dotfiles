#!/usr/bin/bash
# Verify external Herdr launches return to an interactive shell after detach.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.local/bin"
printf '#!/bin/sh\nprintf "<%%s>\\n" "$@" >"%s"\n' "$tmp/launched" >"$tmp/.local/bin/open-terminal"
chmod +x "$tmp/.local/bin/open-terminal"

HOME="$tmp" PATH=/usr/bin:/bin "$repo/stow/base/.local/bin/open-herdr" --session 'two words'
assert_eq "$(<"$tmp/launched")" $'</usr/bin/zsh>\n<-lic>\n<herdr "$@"; exec /usr/bin/zsh -l>\n<zsh>\n<--session>\n<two words>'
pass 'external Herdr launch leaves an interactive shell after detach'
