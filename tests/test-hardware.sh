#!/usr/bin/bash
# Verify machine config validation and safe HDR output selection.
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/testlib.sh"
repo=$(cd -- "${BASH_SOURCE[0]%/*}/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bin="$tmp/bin"
mkdir -p "$bin"
printf '#!/usr/bin/bash\nprintf "Output: 1 HDMI-A-1 id\\n\\tHDR: enabled\\n"\n' >"$bin/kscreen-doctor"
printf '#!/usr/bin/bash\nprintf "NAME UUID MOUNTPOINTS\\nsdc2 TEST-UUID /mnt/disk3\\n"\n' >"$bin/lsblk"
printf '#!/usr/bin/bash\n[[ " $* " == *" --mountpoint "* ]] && [[ ${FINDMNT_OK:-1} == 1 ]]\n' >"$bin/findmnt"
chmod +x "$bin"/*

config="$tmp/home-pc.conf"
printf 'hdr_output=HDMI-A-1\ndisk3_uuid=TEST-UUID\ndisk3_mount=/mnt/disk3\n' >"$config"
PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" >"$tmp/out"
assert_contains "$(<"$tmp/out")" 'HDR output: HDMI-A-1'
assert_contains "$(<"$tmp/out")" 'Drive disk3: TEST-UUID at /mnt/disk3'
pass 'hardware setup validates the narrow machine configuration'

printf '#!/usr/bin/bash\nprintf "Output: 1 DP-10 id\\n\\tHDR: enabled\\n"\n' >"$bin/kscreen-doctor"
printf 'hdr_output=DP-1\ndisk3_uuid=TEST-UUID\ndisk3_mount=/mnt/disk3\n' >"$config"
if PATH="$bin:$PATH" FINDMNT_OK=1 DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'substring display match was accepted'
fi
pass 'hardware setup requires an exact KScreen output name'

printf '#!/usr/bin/bash\nprintf "Output: 1 HDMI-A-1 id\\n\\tHDR: enabled\\n"\n' >"$bin/kscreen-doctor"
printf 'hdr_output=HDMI-A-1\ndisk3_uuid=TEST-UUID\ndisk3_mount=/mnt/disk3\n' >"$config"
if PATH="$bin:$PATH" FINDMNT_OK=0 DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'drive mounted at a different path was accepted'
fi
pass 'hardware setup requires UUID and mount point on the same mount'

printf 'unknown=value\n' >"$config"
if PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'unknown machine key was accepted'
fi
assert_contains "$(<"$tmp/error")" 'Unknown machine key: unknown'
pass 'machine configuration rejects unknown keys'

printf 'hdr_output=HDMI-A-1\ndisk3_uuid=/dev/sdb1\ndisk3_mount=relative\n' >"$config"
if PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'unstable drive identity was accepted'
fi
pass 'machine configuration rejects device paths and relative mounts'

mkdir -p "$tmp/hdr-repo/machines"
printf 'hdr_output=HDMI-A-1\ndisk3_uuid=1C54FDAF54FD8C30\ndisk3_mount=/mnt/disk3\n' >"$tmp/hdr-repo/machines/home-pc.conf"
printf '#!/usr/bin/bash\nif [[ $1 == -o ]]; then printf "\\033[01;32mOutput: \\033[0;0m1 HDMI-A-1 id\\n\\tHDR: disabled\\n\\tWide Color Gamut: disabled\\n"; else printf "%%s\\n" "$*" >>"$HDR_LOG"; fi\n' >"$bin/kscreen-doctor"
chmod +x "$bin/kscreen-doctor"
: >"$tmp/hdr-log"
status=$(HOME="$tmp/home" PATH="$bin:$PATH" DOTFILES_REPO="$tmp/hdr-repo" DOTFILES_MACHINE=home-pc HDR_LOG="$tmp/hdr-log" "$repo/stow/kde/.local/bin/hdr" status)
assert_eq "$status" disabled
HOME="$tmp/home" PATH="$bin:$PATH" DOTFILES_REPO="$tmp/hdr-repo" DOTFILES_MACHINE=home-pc HDR_LOG="$tmp/hdr-log" "$repo/stow/kde/.local/bin/hdr" on
assert_eq "$(<"$tmp/hdr-log")" 'output.HDMI-A-1.hdr.enable output.HDMI-A-1.wcg.enable'
pass 'HDR uses only the configured machine output'

printf 'hdr_output=DP-9\ndisk3_uuid=1C54FDAF54FD8C30\ndisk3_mount=/mnt/disk3\n' >"$tmp/hdr-repo/machines/home-pc.conf"
: >"$tmp/hdr-log"
if HOME="$tmp/home" PATH="$bin:$PATH" DOTFILES_REPO="$tmp/hdr-repo" DOTFILES_MACHINE=home-pc HDR_LOG="$tmp/hdr-log" "$repo/stow/kde/.local/bin/hdr" on 2>"$tmp/error"; then
    fail 'HDR accepted a missing configured output'
fi
[[ ! -s $tmp/hdr-log ]] || fail 'HDR changed a display after configured output was missing'
pass 'HDR fails safely when configured output is absent'

printf '#!/usr/bin/bash\nprintf "NAME UUID MOUNTPOINTS\\nsda1 DISK1-UUID /mnt/disk1\\nsdb2 DISK2-UUID /mnt/disk2\\nsdc2 DISK3-UUID /mnt/disk3\\n"\n' >"$bin/lsblk"
chmod +x "$bin/lsblk"
printf 'hdr_output=HDMI-A-1\ndisk1_uuid=DISK1-UUID\ndisk1_mount=/mnt/disk1\ndisk2_uuid=DISK2-UUID\ndisk2_mount=/mnt/disk2\ndisk3_uuid=DISK3-UUID\ndisk3_mount=/mnt/disk3\n' >"$config"
PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" >"$tmp/out"
assert_contains "$(<"$tmp/out")" 'Drive disk3: DISK3-UUID at /mnt/disk3'
pass 'hardware setup validates every declared machine drive'

printf 'hdr_output=HDMI-A-1\ndisk1_uuid=DISK1-UUID\ndisk1_mount=/mnt/disk1\ndisk2_uuid=DISK2-UUID\ndisk2_mount=/mnt/other\ndisk3_uuid=DISK3-UUID\ndisk3_mount=/mnt/disk3\n' >"$config"
if PATH="$bin:$PATH" FINDMNT_OK=0 DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'declared drive mounted at a different path was accepted'
fi
pass 'hardware setup requires every declared drive on its mount'

printf 'hdr_output=HDMI-A-1\ndisk1_uuid=DISK1-UUID\n' >"$config"
if PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" 2>"$tmp/error"; then
    fail 'drive UUID without a mount point was accepted'
fi
pass 'hardware setup requires a mount point for every declared drive'

printf 'hdr_output=HDMI-A-1\n' >"$config"
PATH="$bin:$PATH" DOTFILES_INTERACTIVE=0 "$repo/setup/hardware" "$config" >"$tmp/out"
assert_contains "$(<"$tmp/out")" 'HDR output: HDMI-A-1'
pass 'hardware setup works on machines without declared drives'
