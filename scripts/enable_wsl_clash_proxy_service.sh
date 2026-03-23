#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-openclaw-gateway.service}"
CLASH_PORT="${CLASH_PORT:-7897}"

OVERRIDE_DIR="$HOME/.config/systemd/user/${SERVICE_NAME}.d"
OVERRIDE_FILE="$OVERRIDE_DIR/proxy.conf"
PROXY_ENV_FILE="$HOME/.openclaw/openclaw-proxy.env"
REFRESH_SCRIPT="$HOME/.local/bin/openclaw-refresh-proxy.sh"

log() { printf '[oc-wsl-clash-proxy] %s\n' "$*"; }
err() { printf '[oc-wsl-clash-proxy][ERR] %s\n' "$*" >&2; }

if ! command -v systemctl >/dev/null 2>&1; then
  err "systemctl not found. This script targets systemd user service mode in WSL."
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  err "openclaw command not found"
  exit 1
fi

mkdir -p "$HOME/.openclaw" "$(dirname "$REFRESH_SCRIPT")" "$OVERRIDE_DIR"

cat > "$REFRESH_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CLASH_PORT="${CLASH_PORT:-7897}"
PROXY_ENV_FILE="$HOME/.openclaw/openclaw-proxy.env"

WIN_IP=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null || true)
if [[ -z "$WIN_IP" ]]; then
  echo "[openclaw-refresh-proxy][ERR] cannot detect Windows IP from /etc/resolv.conf" >&2
  exit 1
fi

if ! curl -s --connect-timeout 2 "http://${WIN_IP}:${CLASH_PORT}" >/dev/null 2>&1; then
  echo "[openclaw-refresh-proxy][ERR] Clash not reachable at ${WIN_IP}:${CLASH_PORT}. Check Clash and Allow LAN." >&2
  exit 1
fi

PROXY="http://${WIN_IP}:${CLASH_PORT}"
cat > "$PROXY_ENV_FILE" <<EOV
HTTP_PROXY=${PROXY}
HTTPS_PROXY=${PROXY}
NO_PROXY=localhost,127.0.0.1
http_proxy=${PROXY}
https_proxy=${PROXY}
no_proxy=localhost,127.0.0.1
EOV

echo "[openclaw-refresh-proxy] updated proxy env with ${PROXY}"
EOF
chmod +x "$REFRESH_SCRIPT"

cat > "$OVERRIDE_FILE" <<EOF
[Service]
Environment=CLASH_PORT=${CLASH_PORT}
EnvironmentFile=%h/.openclaw/openclaw-proxy.env
ExecStartPre=
ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh
EOF

log "installed refresh script: $REFRESH_SCRIPT"
log "wrote service override: $OVERRIDE_FILE"

# ensure service unit exists
openclaw gateway install >/dev/null

# warm up env once
CLASH_PORT="$CLASH_PORT" "$REFRESH_SCRIPT"

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME" >/dev/null
systemctl --user restart "$SERVICE_NAME" >/dev/null

log "done. service restarted with dynamic proxy refresh"
openclaw gateway status
