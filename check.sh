#!/bin/bash
HOSTNAME="$(hostname)"
FAIL=0

for svc in avahi-daemon bluetooth great-memories-ble; do
  systemctl is-active "$svc" &>/dev/null && echo "✓ $svc" || { echo "✗ $svc"; FAIL=1; }
done

PONG=$(curl -sf http://localhost:2283/api/server/ping 2>/dev/null) \
  && echo "✓ great-memories http → $PONG" \
  || { echo "✗ great-memories http"; FAIL=1; }

ping -c1 -W2 "$HOSTNAME.local" &>/dev/null \
  && echo "✓ mDNS ($HOSTNAME.local)" \
  || { echo "✗ mDNS ($HOSTNAME.local)"; FAIL=1; }

(cd ~/great-memories/docker && sg docker -c "docker compose ps --format 'table {{.Name}}\t{{.Status}}'") 2>/dev/null || true

exit $FAIL
