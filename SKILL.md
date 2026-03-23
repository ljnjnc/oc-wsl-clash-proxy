---
name: oc-wsl-clash-proxy
description: Configure OpenClaw in WSL to use Windows-host Clash proxy automatically for resident gateway startup. Use when users mention WSL, OpenClaw, Clash, proxy auto-detection, unstable/blocked API access in China, or "每次启动自动代理".
---

# OC WSL Clash Proxy

Use this skill when the user wants OpenClaw in WSL to reliably use Windows Clash (LAN proxy) for API/network access, including resident/systemd mode.

## What this skill does

- Detects Windows host IP from `/etc/resolv.conf` (fallback: default route).
- Auto-detects a usable Windows proxy port (not limited to Clash):
  - default candidates: `7897,7890,20171,10809,10808,8080,3128,8118`
  - configurable via `PROXY_PORTS`
- Supports fixed proxy URL override via `PROXY_URL`.
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

- `PROXY_URL` (fixed proxy URL, highest priority), e.g. `http://172.21.208.1:7890`
- `CLASH_PORT` (single preferred port; backward-compatible alias)
- `PROXY_PORTS` (comma-separated candidates for auto-detection)
- `SERVICE_NAME` (default `openclaw-gateway.service`)

Examples:

```bash
# fully automatic (recommended)
bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# fixed proxy URL
PROXY_URL=http://172.21.208.1:7890 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh

# custom candidate ports
PROXY_PORTS=7897,7890,20171,9090 bash skills/oc-wsl-clash-proxy/scripts/enable_wsl_clash_proxy_service.sh
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

- If Clash/proxy app is off or LAN access is disabled, startup will fail fast (by design).
- If Windows IP changes, next service start auto-refreshes proxy env.
- This skill is proxy-app agnostic: supports Clash/Clash Verge/V2RayN/Sing-box and other local HTTP proxies via port probing.
- For non-systemd WSL sessions, fall back to temporary shell proxy export + `openclaw gateway run`.
