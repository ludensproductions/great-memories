#!/bin/bash
for svc in avahi-daemon bluetooth immich-ble; do
  systemctl is-active "$svc" &>/dev/null && echo "✓ $svc" || echo "✗ $svc"
done
curl -sf http://localhost:2283/api/server/ping &>/dev/null && echo "✓ immich http" || echo "✗ immich http"
(cd ~/immich/docker && sg docker -c "docker compose ps --format 'table {{.Name}}\t{{.Status}}'") 2>/dev/null || true
