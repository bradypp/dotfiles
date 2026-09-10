# Post-bootstrap checklist

Run only the steps wanted on the restored machine. Never store credentials or passphrases in this repository.

## Applications

- [ ] Enable autostart in the CopyQ, Vorta, and MEGAsync settings.
- [ ] Install [Hermes Agent](https://hermes-agent.nousresearch.com/docs/): `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`, then run `hermes setup` and configure its gateway.
- [ ] Install [Hermes WebUI](https://github.com/nesquena/hermes-webui) and configure its user service.
- [ ] Install standalone [Collie](https://github.com/AltanS/collie/blob/main/docs/install.md): `curl -fsSL https://colliepwa.dev/install.sh | sh`, then configure its private environment and user service.

## Access and recovery

- [ ] Enable and authenticate Tailscale: `sudo systemctl enable --now tailscaled && sudo tailscale up`.
- [ ] After Collie is listening on `127.0.0.1:8787`, expose it with `sudo tailscale serve --bg --https=7787 http://localhost:8787`.
- [ ] After Hermes WebUI is listening on `127.0.0.1:8788`, expose it with `sudo tailscale serve --bg --https=7788 http://localhost:8788`; verify both with `tailscale serve status`.
- [ ] Reconnect Vorta to the existing Borg repository and confirm its source directories and archive access.
