---
name: oc-wsl-clash-proxy
description: Configure OpenClaw in WSL to use Windows-host Clash proxy automatically for resident gateway startup. Use when users mention WSL, OpenClaw, Clash, proxy auto-detection, unstable/blocked API access in China, or "每次启动自动代理".
---

# OC WSL Clash Proxy

Use this skill when the user wants OpenClaw in WSL to reliably use Windows Clash (LAN proxy) for API/network access, including resident/systemd mode.

## What this skill does

- Detects Windows host IP from `/etc/resolv.conf`.
- Verifies Clash endpoint is reachable (default `:7897`).
- Writes/updates `~/.openclaw/openclaw-proxy.env`.
- Installs a refresh hook script at `~/.local/bin/openclaw-refresh-proxy.sh`.
- Configures systemd user override for `openclaw-gateway.service`:
  - `EnvironmentFile=%h/.openclaw/openclaw-proxy.env`
  - `ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh`
- Reloads and restarts gateway service.

## Run

From workspace:

```bash
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

Optional env vars:

- `CLASH_PORT` (default `7897`)
- `SERVICE_NAME` (default `openclaw-gateway.service`)

Example:

```bash
CLASH_PORT=7890 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
```

## Validation checklist

After running, verify:

```bash
openclaw gateway status
systemctl --user status openclaw-gateway.service --no-pager
journalctl --user -u openclaw-gateway.service -n 80 --no-pager
```

Expect:

- service is `enabled` + `active (running)`
- `ExecStartPre=/home/.../.local/bin/openclaw-refresh-proxy.sh` shows `SUCCESS`

## Notes

- If Clash is off or `Allow LAN` is disabled, startup will fail fast (by design).
- If Windows IP changes, next service start auto-refreshes proxy env.
- For non-systemd WSL sessions, fall back to temporary shell proxy export + `openclaw gateway run`.
