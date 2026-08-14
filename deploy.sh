#!/bin/bash
# Setup completo de Great Memories en la Pi. Ejecutar desde la raiz del repo.
#
# Uso:
#   bash deploy.sh
#   SERVER_HOSTNAME=miservidor bash deploy.sh

set -e

SERVER_HOSTNAME="${SERVER_HOSTNAME:-mipi}"
SERVER_PORT="2283"
GREAT_MEMORIES_DIR="$(cd "$(dirname "$0")" && pwd)"
PHOTOS_DIR="/srv/great-memories/photos"
DB_DIR="/srv/great-memories/db"
BLE_DIR="/opt/great-memories-ble"

echo ">>> 0.1 Sistema base"
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git curl wget nano

echo ">>> 0.2 Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
sudo usermod -aG docker "$USER"

echo ">>> 0.3 Configurar .env"
cd "$GREAT_MEMORIES_DIR/docker"
[ ! -f .env ] && cp example.env .env
sed -i "s|UPLOAD_LOCATION=.*|UPLOAD_LOCATION=$PHOTOS_DIR|" .env
sed -i "s|DB_DATA_LOCATION=.*|DB_DATA_LOCATION=$DB_DIR|" .env

sudo mkdir -p "$PHOTOS_DIR" "$DB_DIR"
sudo chown -R "$USER:$USER" /srv/great-memories

echo ">>> 0.4 Arrancar Great Memories"
sg docker -c "docker compose up -d"

echo ">>> 1. mDNS con Avahi"
sudo apt install -y avahi-daemon avahi-utils
sudo systemctl enable --now avahi-daemon
sudo hostnamectl set-hostname "$SERVER_HOSTNAME"
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
echo "127.0.1.1    $SERVER_HOSTNAME" | sudo tee -a /etc/hosts

sudo tee /etc/avahi/services/great-memories.service > /dev/null << EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Great Memories en %h</name>
  <service>
    <type>_great_memories._tcp</type>
    <port>${SERVER_PORT}</port>
  </service>
</service-group>
EOF

sudo systemctl restart avahi-daemon
sudo ufw allow 5353/udp
sudo ufw allow "${SERVER_PORT}/tcp"
sudo ufw reload

echo ">>> 2. BLE con BlueZ"
sudo apt install -y bluetooth bluez python3-venv python3-dbus
sudo systemctl enable --now bluetooth

sudo mkdir -p "$BLE_DIR"
[ ! -d "$BLE_DIR/venv" ] && sudo python3 -m venv --system-site-packages "$BLE_DIR/venv"
sudo "$BLE_DIR/venv/bin/pip" install -q bluezero

sudo tee "$BLE_DIR/great_memories_ble_server.py" > /dev/null << 'PYEOF'
#!/usr/bin/env python3
import logging
import socket
from bluezero import adapter, peripheral

SERVICE_UUID = '494d4d49-0000-1000-8000-000000002283'
IP_CHARACTERISTIC_UUID = '494d4d49-0001-1000-8000-000000002283'
LOCAL_NAME = socket.gethostname()

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('great-memories-ble')


def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except OSError:
        return '127.0.0.1'
    finally:
        s.close()


def read_ip():
    ip = get_local_ip()
    log.info('IP leida: %s', ip)
    return list(ip.encode('utf-8'))


def main():
    dongles = list(adapter.Adapter.available())
    if not dongles:
        raise RuntimeError('No se encontro adaptador Bluetooth')
    dongle = dongles[0]
    periph = peripheral.Peripheral(dongle.address, local_name=LOCAL_NAME)
    periph.add_service(srv_id=1, uuid=SERVICE_UUID, primary=True)
    periph.add_characteristic(
        srv_id=1, chr_id=1,
        uuid=IP_CHARACTERISTIC_UUID,
        value=[], notifying=False,
        flags=['read'],
        read_callback=read_ip,
    )
    log.info('Publicando BLE...')
    periph.publish()


if __name__ == '__main__':
    main()
PYEOF

sudo chmod +x "$BLE_DIR/great_memories_ble_server.py"

sudo tee /etc/systemd/system/great-memories-ble.service > /dev/null << EOF
[Unit]
Description=Great Memories BLE discovery
After=bluetooth.target network-online.target
Wants=network-online.target
Requires=bluetooth.service

[Service]
Type=simple
ExecStart=${BLE_DIR}/venv/bin/python ${BLE_DIR}/great_memories_ble_server.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now great-memories-ble

echo ""
echo "=== Verificacion ==="
sleep 4
for svc in avahi-daemon bluetooth great-memories-ble; do
  systemctl is-active "$svc" &>/dev/null && echo "$svc: OK" || echo "$svc: FALLO"
done
curl -sf "http://localhost:${SERVER_PORT}/api/server/ping" && echo "great-memories http: OK" || echo "great-memories http: aun iniciando (esperar 30s)"

echo ""
echo "============================================================"
echo "LISTO. Accesible como $SERVER_HOSTNAME.local"
echo "Reiniciar para verificar arranque automatico: sudo reboot"
echo "============================================================"
