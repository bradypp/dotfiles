# Dotfiles

Personal GNU Stow dotfiles with automatic desktop/session detection and an optional, user-selected physical-machine name.

## Quick start

```bash
git clone <repository-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap
```

`./bootstrap` starts with no machine on a fresh installation, so it still installs packages and detects the current desktop without applying physical-machine settings. To enable the settings in `machines/home-pc.conf`, select it once:

```bash
./bootstrap --machine home-pc
```

The selection is saved in `~/.local/state/dotfiles/machine` and reused by later `deploy`, `configure`, `bootstrap`, and `verify` runs. `--no-machine` clears a saved machine selection; it does not disable package installation, base dotfiles, Wayland setup, or desktop detection.

## Entry points

Run the root scripts from `~/repos/dotfiles`:

| Command | Purpose |
|---|---|
| `./bootstrap [--skip-install] [--machine NAME\|--no-machine]` | Run install, deploy, configure, and verify in order. |
| `./install` | Restore packages for the detected distribution. |
| `./deploy [--adopt] [--machine NAME\|--no-machine]` | Restow base and the detected desktop package; adopt conflicts only when requested. |
| `./configure [--machine NAME\|--no-machine]` | Run setup for the detected session, desktop, and selected machine. |
| `./update` | Refresh package inventories from the current system. |
| `./verify` | Check repository-managed state without changing it. |
| `./tests/run` | Run the regression test suite. |

`--skip-install` avoids package restoration during bootstrap. `--adopt` imports unmanaged target files into the matching Stow package before linking them. `--machine home-pc` saves that machine selection. `--no-machine` explicitly clears a saved selection; omitting both reuses a saved machine or uses no machine when none has been selected.

## Common management commands

```bash
cd ~/repos/dotfiles

# Complete first-time setup. A fresh installation defaults to no machine.
./bootstrap

# Complete setup for the named physical machine.
./bootstrap --machine home-pc

# Restore packages only.
./install

# Deploy managed files.
./deploy

# Run applicable base, Wayland, KDE, and machine setup.
./configure

# Refresh package inventories.
./update

# Verify without changing anything.
./verify

# Run regression tests.
./tests/run

# Review repository changes.
git status
git diff
git diff --check
```

The usual management commands are `./deploy` after changing Stow sources and `./verify` before committing.

## Optional PATH shortcuts

After `stow/base` is deployed, these convenience commands work from any directory:

| Command | Equivalent root script |
|---|---|
| `dotfiles-deploy` | `~/repos/dotfiles/deploy` |
| `dotfiles-verify` | `~/repos/dotfiles/verify` |

They locate the repository through their own Stow symlinks. The root `./deploy` and `./verify` scripts remain the primary documented interfaces.

## Composition

`stow/base` is always deployed. A KDE session adds `stow/kde`; leaving KDE causes `./deploy` to unstow that known inactive package. Generic setup scripts live under `setup/base/`, Wayland setup scripts under `setup/wayland/`, and KDE setup scripts under `setup/kde/`. Generic setup currently restores missing Oh My Zsh, Powerlevel10k, zsh-syntax-highlighting, and zsh-autosuggestions checkouts under `~/.oh-my-zsh` without replacing the Stowed `.zshrc` or updating existing checkouts.

The selected machine is saved in `~/.local/state/dotfiles/machine`. `machines/home-pc.conf` currently contains only:

- the KScreen output used by `hdr`;
- the filesystem UUID of the drive Vorta needs;
- its expected mount point.

`setup/hardware` confirms those values. It does not mount drives, edit `/etc/fstab`, modify Vorta, unlock Borg repositories, or run backups.

## Managing Stow files

Add a file under the matching package path, then deploy:

```bash
mkdir -p stow/base/.config/example
mv ~/.config/example/config stow/base/.config/example/config
./deploy
```

Removing or moving a source file is applied by `stow --restow` on the next `./deploy`. Unstow an entire package before deleting its package directory:

```bash
stow --delete --no-folding --dir="$PWD/stow" --target="$HOME" kde
```

Unmanaged target conflicts are reported rather than adopted or overwritten unless `./deploy --adopt` is explicitly requested.

For convenience, `deploy` gives the user execute bit to files in the selected Stow packages whose first line is a shebang such as `#!/bin/sh` or `#!/usr/bin/bash`. This covers newly added commands without making ordinary configuration files executable.

## Packages

- `packages/arch/official.txt`: packages shared by Arch-family systems.
- `packages/cachyos/official.txt`: CachyOS additions.
- `packages/arch/aur.txt`: foreign/AUR candidates.
- `packages/arch/flatpak.txt`: Arch-family Flatpaks.
- `packages/fedora/`: Fedora official, COPR, and Flatpak inventories.

The AUR helper order is the `AUR_HELPERS` array near the top of `packages/install`.

See [AGENTS.md](AGENTS.md) before maintaining the repository. Deferred KDE, automount, and backup-recovery ideas are in [BACKLOG.md](BACKLOG.md).
