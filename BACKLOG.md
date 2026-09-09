# Backlog

Ideas intentionally deferred to keep this personal repository small. Implement an item only when there is a concrete need.

## KDE configuration

- Audit KDE config files before deciding whether to Stow complete files.
- Consider `kdeglobals`, `kwinrc`, `kglobalshortcutsrc`, `kwinrulesrc`, `dolphinrc`, `konsolerc`, and `mimeapps.list` individually.
- Preserve default applications, Night Light, custom launchers, global shortcuts, panels, widgets, appearance, and window rules if they become useful to restore.
- Keep generated, private, runtime, and monitor-specific KDE state out of the portable KDE package.

## Machine configuration

- Configure stable automounting for the Vorta drive after choosing KDE automount, `/etc/fstab`, or systemd mount units.
- Add more monitors, drives, power settings, or peripherals only when a script needs them.
- Add another named machine only when it needs machine-specific values.

## Vorta and Borg

- Add an interactive reconnect and recovery checklist.
- Document repository location, source directories, archive mount/test procedure, and passphrase storage location without storing the passphrase.
- Verify Vorta profiles and Borg repositories read-only without modifying Vorta’s SQLite database.

## Capture and migration

- Extend `update` beyond package inventories only for state that is not already Stowed.
- Test Fedora/COPR behavior on an actual Fedora installation.
- Test clean-machine restoration in a disposable VM.

## AI Ran Setup

- Add setup instructions for an ai agent to automatically handle the setup of things that can't be handled by a script or needs verification before install

## Other

- How to handle appimages and curl installs? Are some automatic? (hermes webui, herdr collie, oh-my-zsh, atuin)
- Add different stow categories for de's like hyprland and distros like arch/cachy/fedora (some config is tied to one of these like shelly)
- Add an --adopt flag to deploy & dotfiles-deploy
- Double check all current links, will they break? Do we need to link anything else?