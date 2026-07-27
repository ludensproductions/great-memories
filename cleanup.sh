#!/bin/bash
# Deshace todo lo que hace deploy.sh. Para pruebas desde cero.
# Ejecutar desde cualquier lugar en la Pi.

set -e

IMMICH_DIR="$HOME/immich"
BLE_DIR="/opt/immich-ble"

echo ">>> Deteniendo servicios..."
for svc in immich-ble avahi-daemon; do
  systemctl is-active "$svc" &>/dev/null && sudo systemctl stop "$svc" || true
  systemctl is-enabled "$svc" &>/dev/null && sudo systemctl disable "$svc" || true
done

echo ">>> Bajando contenedores Immich..."
if [ -f "$IMMICH_DIR/docker/docker-compose.yml" ] || [ -f "$IMMICH_DIR/docker/compose.yml" ]; then
  (cd "$IMMICH_DIR/docker" && sg docker -c "docker compose down -v" 2>/dev/null) || true
fi

echo ">>> Eliminando datos..."
sudo rm -rf /srv/immich
sudo rm -rf "$BLE_DIR"
sudo rm -f /etc/avahi/services/immich.service
sudo rm -f /etc/systemd/system/immich-ble.service
sudo systemctl daemon-reload

echo ">>> Eliminando repo..."
cd "$HOME"
rm -rf "$IMMICH_DIR"

echo ""
echo "LISTO. Para reinstalar: git clone <repo> && cd immich && bash deploy.sh"
