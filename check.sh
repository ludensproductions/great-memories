#!/bin/bash
HOSTNAME="$(hostname)"
for svc in avahi-daemon bluetooth immich-ble; do
  systemctl is-active "$svc" &>/dev/null && echo "✓ $svc" || echo "✗ $svc"
done
PONG=$(curl -sf http://localhost:2283/api/server/ping 2>/dev/null) && echo "✓ immich http → $PONG" || echo "✗ immich http"
ping -c1 -W2 "$HOSTNAME.local" &>/dev/null && echo "✓ mDNS ($HOSTNAME.local)" || echo "✗ mDNS ($HOSTNAME.local)"
(cd ~/immich/docker && sg docker -c "docker compose ps --format 'table {{.Name}}\t{{.Status}}'") 2>/dev/null || true
