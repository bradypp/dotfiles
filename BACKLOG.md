# Backlog

Ideas intentionally deferred to keep this personal repository small. Implement an item only when there is a concrete need.

## KDE configuration

- Audit KDE config files before deciding whether to Stow complete files.
- Consider `kdeglobals`, `kwinrc`, `kwinrulesrc`, `dolphinrc`, `konsolerc`, and `mimeapps.list` individually.
- Preserve default applications, Night Light, panels, widgets, appearance, and window rules if they become useful to restore.
- Keep generated, private, runtime, and monitor-specific KDE state out of the portable KDE package.
- Later split portable launcher actions from KDE-specific KGlobalAccel bindings when another desktop is implemented; keep the current launchers and `kglobalshortcutsrc` in `stow/kde` until then.

## Machine configuration

- Configure stable automounting for the Vorta drive after choosing KDE automount, `/etc/fstab`, or systemd mount units.
- Add more monitors, drives, power settings, or peripherals only when a script needs them.
- Add another named machine only when it needs machine-specific values.

## Vorta and Borg

- Add an interactive reconnect and recovery checklist.
- Document repository location, source directories, archive mount/test procedure, and passphrase storage location without storing the passphrase.
- Verify Vorta profiles and Borg repositories read-only without modifying Vorta’s SQLite database.

## Capture and migration

- Extend `update` to further unmanaged state only when it is not already Stowed (Herdr plugins and AppImage filenames are already covered).
- Test Fedora/COPR behavior on an actual Fedora installation.
- Test clean-machine restoration in a disposable VM.
- Test CopyQ selection-and-paste end to end in a real Hyprland session before claiming Hyprland support.

## AI Ran Setup

- Add setup instructions for an ai agent to automatically handle the setup of things that can't be handled by a script or needs verification before install
- Could ai take care of the [POST_BOOTSTRAP.md](POST_BOOTSTRAP.md) steps?

## Other

- Harness (omp, pi) plugin/extension auto update & install
- Record original AppImage download URLs; `update` inventories filenames only.
- Vorga backup should be per distro/de?