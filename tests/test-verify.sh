#!/usr/bin/bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/repo"; home="$tmp/home"; bin="$tmp/bin"
mkdir -p "$fixture/stow/base" "$fixture/stow/kde/.config" "$fixture/machines" "$home" "$bin" "$tmp/applications"
printf base >"$fixture/stow/base/.base"
printf kde >"$fixture/stow/kde/.kde"
printf 'hdr_output=HDMI-A-1\nvorta_drive_uuid=1C54FDAF54FD8C30\nvorta_mount_point=/run/media/paul/Local Disk\n' >"$fixture/machines/home-pc.conf"
printf '[Desktop Entry]\nName=Kitty\n' >"$tmp/applications/kitty.desktop"
printf '#!/usr/bin/bash\ncase $1 in --print-id) echo kitty.desktop;; --print-path) echo /usr/share/applications/kitty.desktop;; --print-cmd) echo kitty;; esac\n' >"$bin/xdg-terminal-exec"
printf '#!/usr/bin/bash\nprintf "\\033[01;32mOutput: \\033[0;0m1 HDMI-A-1 id\\n\\tHDR: disabled\\n"\n' >"$bin/kscreen-doctor"
printf '#!/usr/bin/bash\nprintf "sdc2 Local Disk 1C54FDAF54FD8C30 ntfs 10.9T /run/media/paul/Local Disk\\n"\n' >"$bin/lsblk"
printf '#!/usr/bin/bash\nexit 0\n' >"$bin/vorta"
printf '#!/usr/bin/bash\nexit 0\n' >"$bin/borg"
printf '#!/usr/bin/bash\n[[ ${FINDMNT_OK:-1} == 1 ]]\n' >"$bin/findmnt"
chmod +x "$bin"/*

HOME="$home" XDG_STATE_HOME="$tmp/state" DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland "$repo/deploy" --machine home-pc >/dev/null
before=$(stat -c '%Y:%s' "$tmp/state/dotfiles/machine")
out=$(HOME="$home" XDG_STATE_HOME="$tmp/state" XDG_DATA_DIRS="$tmp" PATH="$bin:$PATH" DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland "$repo/verify")
after=$(stat -c '%Y:%s' "$tmp/state/dotfiles/machine")
assert_eq "$before" "$after"
assert_contains "$out" 'context: kde / home-pc'
assert_contains "$out" 'stow: 2 links verified (base kde)'
assert_contains "$out" 'terminal: kitty.desktop'
assert_contains "$out" 'hardware: HDR output present; Vorta drive mounted'
assert_contains "$out" 'result: PASS'
pass 'verify checks complete composition without changing state'

printf 'hdr_output=HDMI-A-1\nvorta_drive_uuid=UUID-A\nvorta_mount_point=/mnt/vorta\n' >"$fixture/machines/home-pc.conf"
printf '#!/usr/bin/bash\nprintf "sda UUID-A /mnt/other\\nsdb UUID-B /mnt/vorta\\n"\n' >"$bin/lsblk"
chmod +x "$bin/lsblk"
if HOME="$home" XDG_STATE_HOME="$tmp/state" PATH="$bin:$PATH" FINDMNT_OK=0 DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=KDE DOTFILES_SESSION_TYPE=wayland "$repo/verify" >"$tmp/out" 2>"$tmp/error"; then
    fail 'verify associated a UUID with another drive mount point'
fi
pass 'verify requires UUID and mount point on the same mounted filesystem'

if HOME="$home" XDG_STATE_HOME="$tmp/none-state" PATH="$bin:$PATH" DOTFILES_REPO="$fixture" DOTFILES_CURRENT_DESKTOP=GNOME DOTFILES_SESSION_TYPE=x11 "$repo/verify" >"$tmp/out" 2>"$tmp/error"; then
    fail 'verify accepted a link from inactive KDE package'
fi
assert_contains "$(<"$tmp/error")" 'Inactive Stow package remains linked: kde'
pass 'verify rejects links from inactive known packages'
