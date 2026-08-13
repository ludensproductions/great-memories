# Configuracion del servidor Great Memories (Raspberry Pi / Ubuntu Server)

Ambas opciones se ejecutan **desde dentro de la Pi**.

---

## OpciÃ³n A â€” Con script

Instalar git, clonar el repo y correr el script. Hace todo automÃ¡ticamente.

### 1. Instalar git

```bash
sudo apt update
sudo apt install -y git
```

### 2. Clonar el repo

```bash
git clone https://github.com/ludensproductions/immich.git
cd immich
```

### 3. Correr el script

```bash
bash deploy.sh
```

Hostname personalizado (default: `mipi`):

```bash
SERVER_HOSTNAME=miservidor bash deploy.sh
```

---

## OpciÃ³n B â€” Manual paso a paso

### Sistema base

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git curl wget nano
```

### Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### Clonar e iniciar Great Memories

```bash
git clone https://github.com/ludensproductions/immich.git
cd immich/docker
cp example.env .env
nano .env   # ajustar UPLOAD_LOCATION y DB_DATA_LOCATION
sudo mkdir -p /srv/immich/photos /srv/immich/db
sudo chown -R $USER:$USER /srv/immich
newgrp docker
docker compose up -d
curl http://localhost:2283/api/server/ping   # {"res":"pong"}
```

### mDNS (WiFi)

```bash
sudo apt install -y avahi-daemon avahi-utils
sudo systemctl enable --now avahi-daemon
sudo hostnamectl set-hostname mipi
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
echo '127.0.1.1    mipi' | sudo tee -a /etc/hosts
sudo tee /etc/avahi/services/immich.service > /dev/null << 'EOF'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Great Memories en %h</name>
  <service>
    <type>_immich._tcp</type>
    <port>2283</port>
  </service>
</service-group>
EOF
sudo systemctl restart avahi-daemon
sudo ufw allow 5353/udp
sudo ufw allow 2283/tcp
sudo ufw reload
```

### BLE (Bluetooth)

```bash
sudo apt install -y bluetooth bluez python3-venv python3-dbus
sudo systemctl enable --now bluetooth
sudo mkdir -p /opt/immich-ble
sudo python3 -m venv --system-site-packages /opt/immich-ble/venv
sudo /opt/immich-ble/venv/bin/pip install bluezero
```

Crear el servidor BLE:

```bash
sudo tee /opt/immich-ble/immich_ble_server.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import logging
import socket
from bluezero import adapter, peripheral

SERVICE_UUID = '494d4d49-0000-1000-8000-000000002283'
IP_CHARACTERISTIC_UUID = '494d4d49-0001-1000-8000-000000002283'
LOCAL_NAME = socket.gethostname()

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('immich-ble')

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
EOF
sudo chmod +x /opt/immich-ble/immich_ble_server.py
```

Crear el servicio systemd:

```bash
sudo tee /etc/systemd/system/immich-ble.service > /dev/null << 'EOF'
[Unit]
Description=Great Memories BLE discovery
After=bluetooth.target network-online.target
Wants=network-online.target
Requires=bluetooth.service

[Service]
Type=simple
ExecStart=/opt/immich-ble/venv/bin/python /opt/immich-ble/immich_ble_server.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now immich-ble
```

---

## VerificaciÃ³n

```bash
systemctl is-active avahi-daemon bluetooth immich-ble
curl http://localhost:2283/api/server/ping
avahi-browse -rt _immich._tcp
journalctl -u immich-ble -n 30 --no-pager
```

---

## Cambiar hostname

Default: `mipi` â†’ accesible como `mipi.local`.

```bash
SERVER_HOSTNAME=otronombre bash deploy.sh
```

O manualmente:

```bash
sudo hostnamectl set-hostname otronombre
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
echo '127.0.1.1    otronombre' | sudo tee -a /etc/hosts
sudo systemctl restart avahi-daemon
```

---

## Constantes de protocolo (no configurables)

| Constante | Valor |
|---|---|
| mDNS service type | `_immich._tcp` |
| Puerto Great Memories | `2283` |
| BLE service UUID | `494d4d49-0000-1000-8000-000000002283` |
| BLE IP characteristic UUID | `494d4d49-0001-1000-8000-000000002283` |

Los UUIDs BLE estÃ¡n hardcodeados en la app y en el servidor â€” igual que `_immich._tcp` y el puerto 2283. Son identificadores de protocolo, no secretos: BLE advertising es pÃºblico y cualquier scanner puede verlos. MÃºltiples Raspberry Pi con el mismo UUID no se interfieren porque cada dispositivo tiene un MAC address BLE Ãºnico.

---

## Problemas comunes

| SÃ­ntoma | SoluciÃ³n |
|---|---|
| `docker compose up` â€” permission denied | `newgrp docker` y repetir |
| `avahi-browse` vacÃ­o | `sudo systemctl restart avahi-daemon` |
| `ping mipi.local` no resuelve | `sudo ufw allow 5353/udp` |
| App no conecta al servidor | `docker compose ps` + `sudo ufw allow 2283/tcp` |
| `immich-ble` falla al boot | `journalctl -u immich-ble -n 30 --no-pager` |
| BLE devuelve `127.0.0.1` | Pi sin red; verificar `ip addr` |
| Paquetes rotos al instalar bluetooth | `sudo apt full-upgrade -y` antes del install |
| Path invÃ¡lido en `.env` (Windows dev) | Usar `/` en vez de `\` en rutas |
