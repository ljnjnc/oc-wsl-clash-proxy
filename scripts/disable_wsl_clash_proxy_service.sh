#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-openclaw-gateway.service}"
DROPIN_DIR="$HOME/.config/systemd/user/${SERVICE_NAME}.d"
DROPIN_FILE="$DROPIN_DIR/proxy.conf"
ENV_FILE="$HOME/.openclaw/openclaw-proxy.env"

echo "[OC] Disable WSL auto-proxy for ${SERVICE_NAME}"

if [[ -f "$DROPIN_FILE" ]]; then
  cp "$DROPIN_FILE" "$DROPIN_FILE.bak.$(date +%F-%H%M%S)"
  rm -f "$DROPIN_FILE"
  echo "[OK] removed drop-in: $DROPIN_FILE"
else
  echo "[SKIP] drop-in not found: $DROPIN_FILE"
fi

systemctl --user daemon-reload
systemctl --user restart "$SERVICE_NAME"

echo "[OK] restarted $SERVICE_NAME without proxy drop-in"

if [[ -f "$ENV_FILE" ]]; then
  echo "[INFO] env file kept for reference: $ENV_FILE"
fi

echo "[DONE] Auto-proxy mechanism disabled for systemd startup path."
