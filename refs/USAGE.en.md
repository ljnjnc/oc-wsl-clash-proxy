# Usage Guide (for external users)

> Goal: get it working in 5 minutes using only standard commands.  
> Scope: OpenClaw on WSL2, proxy app on Windows host.

---

## 0) Prerequisites

- OpenClaw is installed (`openclaw --version` works)
- Your Windows proxy app has **Allow LAN / local network access** enabled
- Run commands as the same Linux user that runs OpenClaw Gateway

---

## 1) Install (recommended location)

```bash
mkdir -p ~/.openclaw/workspace/skills
cd ~/.openclaw/workspace/skills
git clone https://github.com/ljnjnc/oc-wsl-clash-proxy.git
cd oc-wsl-clash-proxy
```

Recommended path: `~/.openclaw/workspace/skills/oc-wsl-clash-proxy`

---

## 2) Enable auto-proxy injection

```bash
bash scripts/enable_wsl_clash_proxy_service.sh
```

This script will:
- install `~/.local/bin/openclaw-refresh-proxy.sh`
- write systemd drop-in `~/.config/systemd/user/openclaw-gateway.service.d/proxy.conf`
- generate `~/.openclaw/openclaw-proxy.env`
- restart and enable the gateway service

---

## 3) One-command verification (recommended)

```bash
bash scripts/oc-check.sh
```

If you see `OK: service is running and proxy variables are injected.`, you're done.

---

## 4) Daily commands

```bash
# restart
openclaw gateway restart

# status
openclaw gateway status

# service status
systemctl --user status openclaw-gateway.service --no-pager
```

---

## 5) Rollback / disable auto-proxy injection

```bash
bash scripts/disable_wsl_clash_proxy_service.sh
```

---

## 6) FAQ

### Q1: I see `RPC probe: failed 1006` right after restart
Usually a short warm-up window. Wait 5–10 seconds and run:

```bash
openclaw gateway status
```

### Q2: Why no proxy when I run `node ... gateway` directly?
Auto-proxy depends on systemd startup chain (`ExecStartPre + EnvironmentFile`). Use:

```bash
openclaw gateway restart
# or
systemctl --user restart openclaw-gateway.service
```

---

## 7) Manual quick checks

```bash
openclaw gateway status
pid=$(systemctl --user show -p MainPID --value openclaw-gateway.service)
tr '\0' '\n' < /proc/$pid/environ | grep -Ei '^(http|https|no)_proxy='
```
