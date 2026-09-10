#!/usr/bin/bash
# Verify user-managed package inventories are refreshed without copying payloads.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"
bin="$tmp/bin"
appimages="$tmp/AppImages"
mkdir -p "$fixture/packages/herdr" "$bin" "$appimages/subdir"

cat >"$bin/herdr" <<'EOF'
#!/usr/bin/bash
cat <<'OUT'
3 plugins installed:
- annotate (Annotate) enabled [github:plannotator/herdr-annotate@abc123]
- local (Local) enabled [linked:/tmp/local-plugin]
- auto-title (Auto Title) enabled [github:kryptamine/herdr-auto-title@def456]
OUT
EOF
chmod +x "$bin/herdr"
printf app >"$appimages/ChatGPT.AppImage"
printf nested >"$appimages/subdir/Another.AppImage"

PATH="$bin:$PATH" DOTFILES_REPO="$fixture" DOTFILES_APPIMAGE_DIR="$appimages" \
    "$repo/packages/update-user"
assert_eq "$(<"$fixture/packages/herdr/plugins.txt")" $'kryptamine/herdr-auto-title\nplannotator/herdr-annotate'
assert_eq "$(<"$fixture/packages/appimages.txt")" $'ChatGPT.AppImage\nsubdir/Another.AppImage'
pass 'update captures GitHub Herdr plugins and AppImage filenames'
