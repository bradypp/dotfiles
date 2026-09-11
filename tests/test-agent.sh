#!/usr/bin/bash
# Verify agent reuses a terminal or delegates external launches.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.config" "$tmp/.local/bin"
printf 'codex\n' >"$tmp/.config/default-ai-agent"
printf '#!/bin/sh\nprintf "<%%s>\\n" "$@" >"%s"\n' "$tmp/launched" >"$tmp/.local/bin/open-terminal"
chmod +x "$tmp/.local/bin/open-terminal"

HOME="$tmp" PATH=/usr/bin:/bin "$repo/stow/base/.local/bin/agent" --resume 'two words'
assert_eq "$(<"$tmp/launched")" $'</usr/bin/zsh>\n<-lic>\n<exec "$1" "${@:2}">\n<zsh>\n<codex>\n<--resume>\n<two words>'
pass 'agent delegates non-terminal launches to open-terminal'
