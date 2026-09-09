# Dotfiles

Composable home configuration deployed with GNU Stow. The base package is reusable across Linux distributions; profiles add desktop-specific files and setup.

## Layout

```text
.
├── bootstrap                    # Deploy base plus selected/saved profiles
├── install                      # Restore packages, then bootstrap
├── update                       # Refresh this machine's package inventory
├── verify                       # Verify the saved composition
├── profiles/
│   └── kde                      # KDE Stow package and setup selection
├── setup/
│   ├── copyq                    # Self-described one-time setup
│   └── klipper                  # Self-described one-time setup
├── packages/
│   ├── install                  # OS-aware package installer
│   ├── update                   # OS-aware inventory updater
│   ├── arch/
│   │   ├── official.txt
│   │   ├── aur.txt
│   │   └── flatpak.txt
│   ├── cachyos/
│   │   └── official.txt
│   └── fedora/
│       ├── official.txt
│       ├── copr.txt
│       └── flatpak.txt
└── stow/
    ├── base/                    # Cross-distribution home files and commands
    └── kde/                     # KDE commands, unit, and service helper
```

## Entry points

Deploy only the reusable base on a new machine:

```bash
./bootstrap --base-only
```

Deploy base plus KDE configuration:

```bash
./bootstrap kde
```

The selected profiles are saved in `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/profiles`. Later runs reuse them, so routine deployment is simply:

```bash
./bootstrap
```

Restore packages for the detected operating system and then deploy the selected or saved composition:

```bash
./install
./install kde
```

Refresh the current machine's package inventory:

```bash
./update
```

Verify the saved composition from the repository or any directory:

```bash
./verify
dotfiles-verify
```

GNU Stow is the only base deployment requirement. Package installation is explicit and never runs during ordinary bootstrap.

## Profiles and Stow packages

`base` is always deployed. A profile is a small data file containing the extra Stow packages and setup scripts to apply. The current KDE profile deploys `stow/kde`, then runs `setup/copyq` and `setup/klipper`.

The KDE Stow package contains `open-kde-terminal`, the current KScreen-based `hdr` command, and the Klipper user service. Machine-specific HDR output handling can be separated later if needed.

Profiles can be combined by passing multiple names. Switching to base only removes links from previously saved profiles:

```bash
./bootstrap --base-only
```

Preview a composition manually:

```bash
stow --simulate --verbose=2 --restow --no-folding \
  --dir="$PWD/stow" --target="$HOME" base kde
```

Existing unmanaged destination files conflict with Stow. Move files that should be preserved into the appropriate package first; do not use `stow --adopt` without reviewing every affected path.

Editing an existing managed file needs no Stow command because its home path is already a symlink. New, moved, or deleted files require another bootstrap. Stow does not watch for changes; explicit restowing avoids silently linking accidental files.

## Adding managed files

Put reusable files under `stow/base/` and desktop-specific files under the matching package, using paths relative to `$HOME`:

```text
stow/base/.config/example/config       -> ~/.config/example/config
stow/base/.local/bin/example           -> ~/.local/bin/example
stow/kde/.local/bin/kde-example        -> ~/.local/bin/kde-example
```

`--no-folding` keeps shared directories such as `~/.config` and `~/.local/bin` real while linking managed leaf files, so unmanaged files can coexist.

## Package inventories

The update and install entry points dispatch through `/etc/os-release`.

On Arch-based systems:

- `arch/official.txt` contains packages available from standard Arch repositories.
- `cachyos/official.txt` contains additional CachyOS repository packages.
- `arch/aur.txt` contains Pacman-foreign packages to review before treating them as AUR packages.
- `arch/flatpak.txt` contains the Flatpaks used by the Arch-based environment.

CachyOS restores the shared Arch list plus its additions. Plain Arch restores only the Arch list. Official packages use Pacman; AUR packages use the first installed helper from `AUR_HELPERS` at the top of `packages/install`. Reorder this array to change the preference:

```bash
readonly AUR_HELPERS=(shelly paru yay)
```

Fedora keeps separate `official.txt`, `copr.txt`, and `flatpak.txt` inventories. DNF restores RPM packages; repositories needed by entries in `copr.txt` must already be enabled. Flatpak inventories are separate because the desired GUI applications can differ between Arch-based and Fedora systems.

When package-manager elevation is required, installation uses `run0`. If unavailable, it prints the required command rather than running the entire dotfiles deployment as root.

## Sensitive and machine-specific files

Track only stable configuration. Do not add Git credentials, API keys, browser profiles, KWallet data, caches, histories, or generated application state. Keep desktop-specific behavior in profiles and defer host-specific packages or display settings until they are useful enough to separate.
