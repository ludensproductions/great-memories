#!/bin/bash
# Deshace todo lo que hace deploy.sh. Para pruebas desde cero.
# Ejecutar desde cualquier lugar en la Pi.

set -e

GREAT_MEMORIES_DIR="$HOME/great-memories"
BLE_DIR="/opt/great-memories-ble"

echo ">>> Deteniendo servicios..."
for svc in great-memories-ble avahi-daemon; do
  systemctl is-active "$svc" &>/dev/null && sudo systemctl stop "$svc" || true
  systemctl is-enabled "$svc" &>/dev/null && sudo systemctl disable "$svc" || true
done

echo ">>> Bajando contenedores Great Memories..."
if [ -f "$GREAT_MEMORIES_DIR/docker/docker-compose.yml" ] || [ -f "$GREAT_MEMORIES_DIR/docker/compose.yml" ]; then
  (cd "$GREAT_MEMORIES_DIR/docker" && sg docker -c "docker compose down -v" 2>/dev/null) || true
fi

echo ">>> Eliminando datos..."
sudo rm -rf /srv/great-memories
sudo rm -rf "$BLE_DIR"
sudo rm -f /etc/avahi/services/great-memories.service
sudo rm -f /etc/systemd/system/great-memories-ble.service
sudo systemctl daemon-reload

echo ">>> Eliminando repo..."
cd "$HOME"
rm -rf "$GREAT_MEMORIES_DIR"

echo ""
echo "LISTO. Para reinstalar: git clone <repo> && cd great-memories && bash deploy.sh"
