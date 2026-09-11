# Dotfiles

Personal GNU Stow dotfiles with automatic desktop/session detection and an optional, user-selected physical-machine name.

## Quick start

```bash
git clone <repository-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap
```

`./bootstrap` starts with no machine on a fresh installation, so it still installs packages and detects the current desktop without applying physical-machine settings. When it finishes, review [POST_BOOTSTRAP.md](POST_BOOTSTRAP.md) for interactive and application-owned setup. To enable the settings in `machines/home-pc.conf`, select it once:

```bash
./bootstrap --machine home-pc
```

The selection is saved in `~/.local/state/dotfiles/machine` and reused by later `deploy`, `configure`, `bootstrap`, and `verify` runs. `--no-machine` clears a saved machine selection; it does not disable package installation, base dotfiles, Wayland setup, or desktop detection.

## Entry points and PATH shortcuts

Run root scripts from `~/repos/dotfiles`. Shortcuts are available from any
directory after deploying `stow/base`.

| Root command | PATH shortcut | Purpose |
|---|---|---|
| `./bootstrap [-s] [-a] [-m NAME\|-n]` | — | Run initial restoration and verification. |
| `./install` | — | Restore distribution packages and Flatpaks. |
| `./deploy [-a] [-m NAME\|-n]` | `dotfiles-deploy` | Restow files for the current context. |
| `./configure [-m NAME\|-n]` | — | Run applicable setup scripts. |
| `./update` | — | Refresh package, plugin, and AppImage inventories. |
| `./verify` | `dotfiles-verify` | Check managed state without changing it. |
| — | `dotfiles-stow [-p PACKAGE\|-c PACKAGE] PATH` | Import a home path into a Stow package. |
| `./tests/run` | — | Run the regression tests. |

Options: `-s`/`--skip-install`, `-a`/`--adopt`, `-m NAME`/`--machine NAME`, and `-n`/`--no-machine`. Short flags may be combined (`-sam NAME`, `-na`), but the machine name must be separate. Without a machine option, the saved selection is reused.

## Common management commands

```bash
cd ~/repos/dotfiles

# Complete first-time setup. A fresh installation defaults to no machine.
./bootstrap

# Complete setup for the named physical machine.
./bootstrap -m home-pc

# Bootstrap without reinstalling packages.
./bootstrap -s

# Explicitly adopt conflicts, skip reinstalling packages, and select the machine.
./bootstrap -asm home-pc

# Restore packages only.
./install

# Deploy managed files.
./deploy

# Explicitly adopt conflicts and select a machine.
./deploy -am home-pc

# Run applicable base, Wayland, KDE, and machine setup.
./configure

# Clear the saved machine selection.
./configure -n

# Import a config into base or another package.
dotfiles-stow ~/.config/example/config
dotfiles-stow -p work ~/.config/example/config
dotfiles-stow -c work ~/.config/example/config

# Refresh package, Herdr plugin, and AppImage inventories.
./update

# Verify without changing anything.
./verify

# Run regression tests.
./tests/run
```

The usual maintenance cycle is `./deploy`, `./verify`, then `./tests/run`.

## Composition

`stow/base` is always deployed. A KDE session adds `stow/kde`; leaving KDE causes `./deploy` to unstow that known inactive package. The KDE package currently owns the custom desktop launchers and complete KGlobalAccel configuration; a future desktop implementation can split portable actions from desktop-specific bindings. Generic setup scripts live under `setup/base/`, Wayland setup scripts under `setup/wayland/`, and KDE setup scripts under `setup/kde/`. Generic setup currently restores missing Oh My Zsh, Powerlevel10k, zsh-syntax-highlighting, and zsh-autosuggestions checkouts under `~/.oh-my-zsh` without replacing the Stowed `.zshrc` or updating existing checkouts. It also runs `mise install` for tools declared in the Stowed mise configuration and installs missing Herdr plugins listed in `packages/herdr/plugins.txt`. CopyQ’s Wayland setup supports KDE with `kdotool` and is prepared for Hyprland with `hyprctl`; Hyprland behavior still requires live testing.

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

After deploying `stow/base`, `dotfiles-stow` can move a file or directory from
`$HOME` into the repository and immediately restow its package:

```bash
# Import into the existing base package.
dotfiles-stow ~/.config/example/config

# Import into any existing package.
dotfiles-stow -p work ~/.config/example/config

# Create a package when absent, then import into it.
dotfiles-stow -c work ~/.config/example/config
```

| Option | Behavior |
|---|---|
| `-p PACKAGE`, `--package PACKAGE` | Import into an existing package. |
| `-c PACKAGE`, `--create-package PACKAGE` | Import into the package, creating it when absent. |
| `-h` | Show command usage. |

Without `-p` or `-c`, the command imports into the existing `base` package.
The command refuses paths outside `$HOME`, symbolic links, missing packages
without `-c`, and existing repository destinations. If Stow fails, it restores
the imported path to its original location.

Removing or moving a source file is applied on the next `./deploy`. In addition
to `stow --restow`, deployment checks the paths recorded by the previous
successful deployment in `~/.local/state/dotfiles/stow-links` and removes a
broken link only when its target resolves inside this repository's Stow
packages. Unstow an entire package before deleting its package directory:

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
- `packages/herdr/plugins.txt`: GitHub-managed Herdr plugin sources, refreshed by `packages/update-user` from `herdr plugin list`.
- `packages/appimages.txt`: AppImage filenames under `~/AppImages`, refreshed by `packages/update-user`; original download URLs stay manual in [POST_BOOTSTRAP.md](POST_BOOTSTRAP.md).

The AUR helper order is the `AUR_HELPERS` array near the top of `packages/install`.

See [AGENTS.md](AGENTS.md) before maintaining the repository. Interactive and application-owned steps are in [POST_BOOTSTRAP.md](POST_BOOTSTRAP.md). Deferred KDE, automount, and backup-recovery ideas are in [BACKLOG.md](BACKLOG.md).
