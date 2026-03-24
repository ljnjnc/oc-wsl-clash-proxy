#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-openclaw-gateway.service}"

echo "=== restart ==="
systemctl --user restart "$SERVICE_NAME"

sleep 6

echo "=== service status ==="
systemctl --user status "$SERVICE_NAME" --no-pager | sed -n '1,20p'

echo "=== gateway status ==="
openclaw gateway status

echo "=== proxy env ==="
pid=$(systemctl --user show -p MainPID --value "$SERVICE_NAME")
if [[ -z "$pid" || "$pid" = "0" ]]; then
  echo "ERROR: service has no MainPID"
  exit 1
fi
tr '\0' '\n' < "/proc/$pid/environ" | grep -Ei '^(http|https|no)_proxy=' || {
  echo "WARN: no proxy variables found in process env"
  exit 2
}

echo "=== result ==="
echo "OK: service is running and proxy variables are injected."
