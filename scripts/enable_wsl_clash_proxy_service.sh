#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-openclaw-gateway.service}"
# Backward compatible: if CLASH_PORT is set, it becomes highest-priority port.
CLASH_PORT="${CLASH_PORT:-}"
# Optional fixed proxy URL, e.g. http://172.21.208.1:7890
PROXY_URL="${PROXY_URL:-}"
# Common Windows local proxy ports (Clash/Clash Verge/V2RayN/Sing-box/etc.)
PROXY_PORTS="${PROXY_PORTS:-7897,7890,20171,10809,10808,8080,3128,8118}"

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

# Supports both fixed URL and auto-detection by Windows host IP + common ports.
PROXY_URL="${PROXY_URL:-}"
PROXY_PORT="${PROXY_PORT:-}"
PROXY_PORTS="${PROXY_PORTS:-7897,7890,20171,10809,10808,8080,3128,8118}"
PROXY_ENV_FILE="$HOME/.openclaw/openclaw-proxy.env"

log() { printf '[openclaw-refresh-proxy] %s\n' "$*"; }
err() { printf '[openclaw-refresh-proxy][ERR] %s\n' "$*" >&2; }

detect_windows_ip() {
  local ip
  ip=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null || true)
  if [[ -n "$ip" ]]; then
    printf '%s' "$ip"
    return 0
  fi
  ip=$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}' || true)
  printf '%s' "$ip"
}

can_proxy_http() {
  local url="$1"
  # Prefer lightweight endpoint; use two candidates for robustness.
  curl -s --connect-timeout 2 --max-time 8 -x "$url" http://connectivitycheck.gstatic.com/generate_204 -o /dev/null && return 0
  curl -s --connect-timeout 2 --max-time 8 -x "$url" https://www.gstatic.com/generate_204 -o /dev/null && return 0
  return 1
}

is_tcp_reachable() {
  local host_port="$1"
  curl -s --connect-timeout 2 "http://${host_port}" -o /dev/null 2>&1
}

write_env() {
  local proxy="$1"
  cat > "$PROXY_ENV_FILE" <<EOV
HTTP_PROXY=${proxy}
HTTPS_PROXY=${proxy}
NO_PROXY=localhost,127.0.0.1
http_proxy=${proxy}
https_proxy=${proxy}
no_proxy=localhost,127.0.0.1
EOV
  log "updated proxy env with ${proxy}"
}

if [[ -n "$PROXY_URL" ]]; then
  if can_proxy_http "$PROXY_URL"; then
    write_env "$PROXY_URL"
    exit 0
  fi
  err "PROXY_URL set but unavailable: $PROXY_URL"
  exit 1
fi

WIN_IP=$(detect_windows_ip)
if [[ -z "$WIN_IP" ]]; then
  err "cannot detect Windows IP from /etc/resolv.conf or default route"
  exit 1
fi

# Build candidate port list (priority: PROXY_PORT -> PROXY_PORTS)
CANDIDATES=()
if [[ -n "$PROXY_PORT" ]]; then
  CANDIDATES+=("$PROXY_PORT")
fi
IFS=',' read -r -a EXTRA_PORTS <<< "$PROXY_PORTS"
for p in "${EXTRA_PORTS[@]}"; do
  p="${p//[[:space:]]/}"
  [[ -n "$p" ]] && CANDIDATES+=("$p")
done

# De-duplicate preserving order
UNIQ=()
for p in "${CANDIDATES[@]}"; do
  skip=0
  for q in "${UNIQ[@]}"; do
    [[ "$p" == "$q" ]] && skip=1 && break
  done
  [[ "$skip" -eq 0 ]] && UNIQ+=("$p")
done

for port in "${UNIQ[@]}"; do
  candidate="http://${WIN_IP}:${port}"
  if can_proxy_http "$candidate"; then
    write_env "$candidate"
    exit 0
  fi
  # Fallback: reachable port, for custom proxy stacks that don't like health URLs.
  if is_tcp_reachable "${WIN_IP}:${port}"; then
    write_env "$candidate"
    log "fallback by TCP reachability on ${WIN_IP}:${port}"
    exit 0
  fi
done

err "no usable Windows proxy found on ${WIN_IP}. Tried ports: ${UNIQ[*]}"
err "Please ensure proxy app is running and LAN access is enabled, or set PROXY_URL manually."
exit 1
EOF
chmod +x "$REFRESH_SCRIPT"

cat > "$OVERRIDE_FILE" <<EOF
[Service]
Environment=PROXY_URL=${PROXY_URL}
Environment=PROXY_PORT=${CLASH_PORT}
Environment=PROXY_PORTS=${PROXY_PORTS}
EnvironmentFile=%h/.openclaw/openclaw-proxy.env
ExecStartPre=
ExecStartPre=%h/.local/bin/openclaw-refresh-proxy.sh
EOF

log "installed refresh script: $REFRESH_SCRIPT"
log "wrote service override: $OVERRIDE_FILE"

# ensure service unit exists
openclaw gateway install >/dev/null

# warm up env once
PROXY_URL="$PROXY_URL" PROXY_PORT="$CLASH_PORT" PROXY_PORTS="$PROXY_PORTS" "$REFRESH_SCRIPT"

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME" >/dev/null
systemctl --user restart "$SERVICE_NAME" >/dev/null

log "done. service restarted with dynamic proxy refresh"
openclaw gateway status
