# Repository maintenance

- Read [README.md](README.md) for commands and layout.
- Keep portable home files in `stow/base/` and KDE-only files in `stow/kde/`.
- Put Wayland setup in `setup/wayland/`, KDE setup in `setup/kde/`, and generic hardware validation in `setup/hardware`.
- Keep stable, non-secret physical-machine values in `machines/NAME.conf`; never derive the machine name from its hostname or distribution.
- Preserve `stow --no-folding`; never use broad `--adopt`.
- Never commit credentials, passphrases, Vorta/KWallet databases, caches, histories, or `/dev/sdX` device identities.
- Add behavior with a failing test first; run `./tests/run` and `./verify` before committing.
- Put deferred ideas in [BACKLOG.md](BACKLOG.md) instead of adding speculative abstractions.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
