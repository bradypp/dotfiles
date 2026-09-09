# Dotfiles

Personal GNU Stow dotfiles with automatic desktop/session detection and an optional, user-selected physical-machine name.

## Quick start

```bash
git clone <repository-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap --machine home-pc
```

The machine name is personal and stable across operating systems and hostnames. Omit it on machines with no machine-specific configuration:

```bash
./bootstrap --no-machine
```

## Commands

| Command | Purpose |
|---|---|
| `./install` | Restore packages for the detected distribution. |
| `./deploy` | Restow the automatically selected packages. |
| `./configure` | Run setup for the active session, desktop, and machine. |
| `./update` | Refresh package inventories. |
| `./verify` | Check all repository-managed state without repairing it. |
| `./bootstrap` | Run install, deploy, configure, and verify in order. |

Use `./bootstrap --skip-install` when packages are already restored.

## Composition

`stow/base` is always deployed. A KDE session adds `stow/kde`; leaving KDE causes `./deploy` to unstow that known inactive package. Wayland setup scripts live under `setup/wayland/`, and KDE setup scripts live under `setup/kde/`.

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

Unmanaged target conflicts are reported rather than adopted or overwritten.

## Packages

- `packages/arch/official.txt`: packages shared by Arch-family systems.
- `packages/cachyos/official.txt`: CachyOS additions.
- `packages/arch/aur.txt`: foreign/AUR candidates.
- `packages/arch/flatpak.txt`: Arch-family Flatpaks.
- `packages/fedora/`: Fedora official, COPR, and Flatpak inventories.

The AUR helper order is the `AUR_HELPERS` array near the top of `packages/install`.

See [AGENTS.md](AGENTS.md) before maintaining the repository. Deferred KDE, automount, and backup-recovery ideas are in [BACKLOG.md](BACKLOG.md).
