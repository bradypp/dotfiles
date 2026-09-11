# Repository maintenance

- Read [README.md](README.md) for commands and layout; keep it synchronized with user-facing behavior and paths.
- Keep [POST_BOOTSTRAP.md](POST_BOOTSTRAP.md) concise and current whenever a required step remains interactive, credentialed, application-owned, or otherwise intentionally manual.
- Keep portable home files in `stow/base/` and KDE-only files in `stow/kde/`.
- Put Wayland setup in `setup/wayland/`, KDE setup in `setup/kde/`, and generic hardware validation in `setup/hardware`.
- Keep stable, non-secret physical-machine values in `machines/NAME.conf`; never derive the machine name from its hostname or distribution.
- Preserve `stow --no-folding`; never use broad `--adopt`.
- Never commit credentials, passphrases, Vorta/KWallet databases, caches, histories, or `/dev/sdX` device identities.
- Add repository-maintenance behavior with a failing test first; do not add tests for the behavior of managed dotfile contents themselves. Run `./tests/run` and `./verify` before committing.
- Keep documentation current: remove or update stale entries in `README.md`, `POST_BOOTSTRAP.md`, and `BACKLOG.md` when behavior changes.
- Put useful but currently unjustified work in [BACKLOG.md](BACKLOG.md) instead of adding speculative abstractions.
