# Configuración del servidor Immich (Raspberry Pi / Ubuntu Server)

UUIDs compartidos con la app móvil — **no cambiar**:

| Concepto | Valor |
|---|---|
| Tipo mDNS | `_immich._tcp` |
| Hostname mDNS | `immich` → `immich.local` |
| Puerto | `2283` |
| Service UUID (BLE) | `494d4d49-0000-1000-8000-000000002283` |
| Characteristic UUID (BLE, IP) | `494d4d49-0001-1000-8000-000000002283` |

---

## 0. Desde cero — instalar todo

### 0.1. Sistema base

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget nano
```

### 0.2. Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

Verificar:
```bash
docker --version
docker compose version
```

### 0.3. Clonar el repositorio

```bash
git clone https://github.com/immich-app/immich.git
cd immich/docker
```

### 0.4. Configurar variables de entorno

```bash
cp example.env .env
nano .env
```

Poner las rutas donde guardar fotos y base de datos (usar `/` no `\`):

```env
UPLOAD_LOCATION=/srv/immich/photos
DB_DATA_LOCATION=/srv/immich/db
IMMICH_VERSION=release
DB_PASSWORD=cambia_esto
```

Crear las carpetas:
```bash
sudo mkdir -p /srv/immich/photos /srv/immich/db
sudo chown -R $USER:$USER /srv/immich
```

### 0.5. Arrancar Immich

```bash
docker compose up -d
```

Verificar que corre:
```bash
docker compose ps
curl http://localhost:2283/api/server/ping
# respuesta: {"res":"pong"}
```

Acceder desde el navegador: `http://<ip-de-la-pi>:2283`

---

## 1. WiFi — mDNS con Avahi

```bash
sudo apt install -y avahi-daemon avahi-utils
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
```

Fijar hostname:
```bash
sudo hostnamectl set-hostname immich
```

Editar `/etc/hosts` — buscar línea `127.0.1.1` y dejarla:
```
127.0.1.1    immich
```

```bash
sudo systemctl restart avahi-daemon
```

Crear servicio mDNS:
```bash
sudo nano /etc/avahi/services/immich.service
```

```xml
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Immich en %h</name>
  <service>
    <type>_immich._tcp</type>
    <port>2283</port>
  </service>
</service-group>
```

```bash
sudo systemctl restart avahi-daemon
```

Si usas `ufw`:
```bash
sudo ufw allow 5353/udp
sudo ufw allow 2283/tcp
```

---

## 2. Bluetooth — BLE con BlueZ

### 2.1. Instalar dependencias

```bash
sudo apt install -y bluetooth bluez python3-venv python3-dbus libdbus-1-dev libglib2.0-dev
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### 2.2. Entorno Python

```bash
sudo mkdir -p /opt/immich-ble
sudo python3 -m venv --system-site-packages /opt/immich-ble/venv
sudo /opt/immich-ble/venv/bin/pip install bluezero
```

### 2.3. Archivo de entorno del servidor BLE

```bash
sudo nano /opt/immich-ble/.env
```

```env
BLE_SERVICE_UUID=494d4d49-0000-1000-8000-000000002283
BLE_IP_CHARACTERISTIC_UUID=494d4d49-0001-1000-8000-000000002283
```

```bash
sudo chmod 600 /opt/immich-ble/.env
```

### 2.4. Script del servidor BLE

```bash
sudo nano /opt/immich-ble/immich_ble_server.py
```

```python
#!/usr/bin/env python3
import logging
import os
import socket
from bluezero import adapter, peripheral

SERVICE_UUID = os.environ.get('BLE_SERVICE_UUID', '494d4d49-0000-1000-8000-000000002283')
IP_CHARACTERISTIC_UUID = os.environ.get('BLE_IP_CHARACTERISTIC_UUID', '494d4d49-0001-1000-8000-000000002283')
LOCAL_NAME = 'immich'

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('immich-ble')


def get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except OSError:
        return '127.0.0.1'
    finally:
        s.close()


def read_ip() -> list:
    ip = get_local_ip()
    log.info('IP leida: %s', ip)
    return list(ip.encode('utf-8'))


def main():
    dongles = list(adapter.Adapter.available())
    if not dongles:
        raise RuntimeError('No se encontro adaptador Bluetooth')

    dongle = dongles[0]
    log.info('Adaptador: %s', dongle.address)

    periph = peripheral.Peripheral(dongle.address, local_name=LOCAL_NAME)
    periph.add_service(srv_id=1, uuid=SERVICE_UUID, primary=True)
    periph.add_characteristic(
        srv_id=1, chr_id=1,
        uuid=IP_CHARACTERISTIC_UUID,
        value=[], notifying=False,
        flags=['read'],
        read_callback=read_ip,
    )

    log.info('Publicando BLE (UUID %s)...', SERVICE_UUID)
    periph.publish()


if __name__ == '__main__':
    main()
```

```bash
sudo chmod +x /opt/immich-ble/immich_ble_server.py
```

### 2.5. Servicio systemd

```bash
sudo nano /etc/systemd/system/immich-ble.service
```

```ini
[Unit]
Description=Immich BLE discovery
After=bluetooth.target network-online.target
Wants=network-online.target
Requires=bluetooth.service

[Service]
Type=simple
EnvironmentFile=/opt/immich-ble/.env
ExecStart=/opt/immich-ble/venv/bin/python /opt/immich-ble/immich_ble_server.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable immich-ble
sudo systemctl start immich-ble
```

---

## 3. Compilar la app móvil con UUIDs personalizados

Si cambias los UUIDs del `.env`, hay que pasar los mismos valores al build de Flutter:

```bash
# Desarrollo
flutter run \
  --dart-define=BLE_SERVICE_UUID=494d4d49-0000-1000-8000-000000002283 \
  --dart-define=BLE_IP_CHARACTERISTIC_UUID=494d4d49-0001-1000-8000-000000002283

# Producción
flutter build apk \
  --dart-define=BLE_SERVICE_UUID=494d4d49-0000-1000-8000-000000002283 \
  --dart-define=BLE_IP_CHARACTERISTIC_UUID=494d4d49-0001-1000-8000-000000002283
```

Si no se pasan los `--dart-define`, la app usa los valores por defecto del código (los mismos que el `.env` por defecto).

---

## 4. Verificación post-reinicio

```bash
sudo reboot
```

Tras reconectar:

```bash
# Servicios habilitados
systemctl is-enabled avahi-daemon bluetooth immich-ble

# Estado
systemctl status avahi-daemon bluetooth immich-ble --no-pager

# mDNS
avahi-browse -rt _immich._tcp

# Logs BLE si falla
journalctl -u immich-ble -n 50 --no-pager
```

Desde otro equipo en la red:
```bash
ping immich.local
curl http://immich.local:2283/api/server/ping
```

---

## 5. Problemas comunes

| Síntoma | Solución |
|---|---|
| `avahi-browse` vacío | Verificar `/etc/avahi/services/immich.service` y reiniciar daemon |
| `ping immich.local` no resuelve | `sudo ufw allow 5353/udp` |
| App encuentra Pi pero no conecta | `docker compose ps` + `sudo ufw allow 2283/tcp` |
| `immich-ble` falla al boot | Normal — `Restart=always` lo reintenta; esperar 10s y revisar `systemctl status` |
| BLE devuelve `127.0.0.1` | Pi sin red al leer IP; verificar con `ip addr` |
| Error path en `.env` (Windows) | Usar `/` en vez de `\` en rutas |
