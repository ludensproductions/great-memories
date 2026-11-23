# Configuracion del servidor Great Memories (Raspberry Pi / Ubuntu Server)

Ambas opciones se ejecutan **desde dentro de la Pi**.

> Aplica igual a una PC con Ubuntu Server: donde diga "la Pi", léase "el servidor".

---

## Requisitos

| Requisito | Detalle |
|---|---|
| Sistema operativo | Linux **64 bits** con `apt` (Ubuntu Server 22.04/24.04 o Raspberry Pi OS 64-bit). Las imágenes solo existen para `amd64` y `arm64`; Raspberry Pi OS de 32 bits **no funciona**. |
| RAM | Mínimo 4 GB (recomendado 6–8 GB; el contenedor de machine learning es el que más consume). |
| Disco | SSD recomendado para la base de datos. Espacio para fotos según uso. |
| Red | Misma red local que los celulares. Recomendado reservar la IP del servidor en el DHCP del router. |
| Bluetooth | Solo necesario para el descubrimiento BLE. Se controla con la flag `BLE` de `deploy.sh` (ver paso 3). |
| Usuario | Usuario con `sudo` (no ejecutar como `root`). |
| Firewall | Los comandos usan `ufw`. Ubuntu Server lo trae; en Raspberry Pi OS instalarlo antes: `sudo apt install -y ufw`. |

> ⚠️ Si activas `ufw` (`sudo ufw enable`), primero permite SSH (`sudo ufw allow OpenSSH`) o te quedarás sin acceso remoto. Los comandos de esta guía solo agregan reglas; no activan el firewall.

---

> **Servidor remoto (VPS / dedicado en datacenter):** mDNS y BLE solo sirven en la red local de los celulares; ahí no aplican. Con script: `SERVER_HOSTNAME=$(hostname) BLE=no bash deploy.sh`. A mano: basta con la parte de Docker de la Opción B (sistema base, Docker, clonar e iniciar). El puerto `2283` habla HTTP sin cifrar: publicarlo detrás de un reverse proxy con HTTPS (nginx, Caddy, Traefik) y no abrir `2283` directo a internet.

---

## Opción A — Con script

Instalar git, clonar el repo y correr el script. Hace todo automáticamente.

### 1. Instalar git

```bash
sudo apt update
sudo apt install -y git
```

### 2. Clonar el repo

```bash
git clone https://github.com/ludensproductions/great-memories.git
cd great-memories
```

El repo se puede clonar en cualquier ruta.

### 2.1 `.env` (opcional)

Si no existe `docker/.env`, el script lo crea desde `docker/example.env` con `GREAT_MEMORIES_VERSION=main` (la etiqueta `v3` todavía no existe en GHCR) y un `DB_PASSWORD` aleatorio. Si ya existe, lo respeta. Para fijar la zona horaria, prepararlo antes:

```bash
cp docker/example.env docker/.env
sed -i 's|^GREAT_MEMORIES_VERSION=.*|GREAT_MEMORIES_VERSION=main|' docker/.env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)|" docker/.env
nano docker/.env   # descomentar TZ, p. ej. TZ=America/Mexico_City
```

### 3. Correr el script

> ⚠️ El script **cambia el hostname** del equipo (default: `mipi`). En un servidor que ya tiene nombre, conservarlo:
>
> ```bash
> SERVER_HOSTNAME=$(hostname) bash deploy.sh
> ```

```bash
bash deploy.sh
```

Hostname personalizado:

```bash
SERVER_HOSTNAME=miservidor bash deploy.sh
```

Bluetooth (descubrimiento BLE desde la app):

| Flag | Cuándo usarlo |
|---|---|
| `BLE=auto` (default) | Instala BLE solo si el equipo tiene adaptador Bluetooth. |
| `BLE=si` | Raspberry Pi o mini PC en la red local. |
| `BLE=no` | Servidor virtual / datacenter. |

```bash
# Servidor virtual
SERVER_HOSTNAME=$(hostname) BLE=no bash deploy.sh

# Raspberry Pi / mini PC
BLE=si bash deploy.sh
```

Al terminar, reiniciar para confirmar que todo arranca solo: `sudo reboot`.

---

## Opción B — Manual paso a paso

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

> `newgrp docker` abre una sub-shell: si pegas varios bloques de golpe, lo que sigue no se ejecuta. Pega cada bloque por separado, o cierra sesión y vuelve a entrar.

### Clonar e iniciar Great Memories

```bash
git clone https://github.com/ludensproductions/great-memories.git
cd great-memories/docker
cp example.env .env
nano .env   # ajustar UPLOAD_LOCATION y DB_DATA_LOCATION
sudo mkdir -p /srv/great-memories/photos /srv/great-memories/db
sudo chown -R $USER:$USER /srv/great-memories
newgrp docker
docker compose up -d
curl http://localhost:2283/api/server/ping   # {"res":"pong"}
```

Valores de `.env` a ajustar:

```ini
UPLOAD_LOCATION=/srv/great-memories/photos
DB_DATA_LOCATION=/srv/great-memories/db
GREAT_MEMORIES_VERSION=main        # v3 todavía no existe en GHCR
DB_PASSWORD=<aleatorio, solo A-Za-z0-9>
# TZ=America/Mexico_City
```

El primer `docker compose up -d` descarga varios GB; el `ping` puede tardar 1–2 minutos en responder.

### mDNS (WiFi)

```bash
sudo apt install -y avahi-daemon avahi-utils
sudo systemctl enable --now avahi-daemon
sudo hostnamectl set-hostname mipi
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
echo '127.0.1.1    mipi' | sudo tee -a /etc/hosts
sudo tee /etc/avahi/services/great-memories.service > /dev/null << 'EOF'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Great Memories en %h</name>
  <service>
    <type>_great_memories._tcp</type>
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
sudo apt install -y bluetooth bluez python3-venv python3-dbus python3-gi python3-cairo
sudo systemctl enable --now bluetooth
sudo mkdir -p /opt/great-memories-ble
sudo python3 -m venv --system-site-packages /opt/great-memories-ble/venv
sudo /opt/great-memories-ble/venv/bin/pip install bluezero
```

Crear el servidor BLE:

```bash
sudo tee /opt/great-memories-ble/great_memories_ble_server.py > /dev/null << 'EOF'
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
EOF
sudo chmod +x /opt/great-memories-ble/great_memories_ble_server.py
```

Crear el servicio systemd:

```bash
sudo tee /etc/systemd/system/great-memories-ble.service > /dev/null << 'EOF'
[Unit]
Description=Great Memories BLE discovery
After=bluetooth.target network-online.target
Wants=network-online.target
Requires=bluetooth.service

[Service]
Type=simple
ExecStart=/opt/great-memories-ble/venv/bin/python /opt/great-memories-ble/great_memories_ble_server.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now great-memories-ble
```

---

## Verificación

```bash
bash check.sh
```

O manualmente:

```bash
systemctl is-active avahi-daemon bluetooth great-memories-ble
curl http://localhost:2283/api/server/ping
avahi-browse -rt _great_memories._tcp
journalctl -u great-memories-ble -n 30 --no-pager
```

---

## Primer acceso

1. Desde un navegador en la misma red: `http://mipi.local:2283` (o `http://<IP>:2283`; la IP se ve con `hostname -I`).
2. El **primer usuario que se registra queda como administrador**. Hacerlo inmediatamente después de instalar.
3. En la app móvil, el servidor se detecta solo por mDNS/BLE; si no, capturar `http://<IP>:2283` a mano.

---

## Cambiar hostname

Default: `mipi` → accesible como `mipi.local`.

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

## Actualizar

```bash
cd <ruta-del-repo>
git pull
cd docker
docker compose pull
docker compose up -d
```

`git pull` no toca `docker/.env` (no está versionado). Revisar si `example.env` agregó variables nuevas: `diff example.env .env`.

---

## Respaldos

Todo el estado vive en `/srv/great-memories` (fotos y base de datos) y en `docker/.env` (contraseña de la BD).

```bash
# Dump de la base de datos (con el servidor corriendo)
docker exec -t great_memories_postgres pg_dumpall --clean --if-exists --username=postgres \
  | gzip > ~/great-memories-db-$(date +%F).sql.gz
```

Copiar ese archivo, `/srv/great-memories/photos` y `docker/.env` a otro disco. No copiar `/srv/great-memories/db` en caliente: usar el dump.

---

## Desinstalar

```bash
bash <ruta-del-repo>/cleanup.sh
```

⚠️ Borra **todo**: contenedores, fotos, base de datos y el repo. Respaldar antes.

---

## Constantes de protocolo (no configurables)

| Constante | Valor |
|---|---|
| mDNS service type | `_great_memories._tcp` |
| Puerto Great Memories | `2283` |
| BLE service UUID | `494d4d49-0000-1000-8000-000000002283` |
| BLE IP characteristic UUID | `494d4d49-0001-1000-8000-000000002283` |

Los UUIDs BLE están hardcodeados en la app y en el servidor — igual que `_great_memories._tcp` y el puerto 2283. Son identificadores de protocolo, no secretos: BLE advertising es público y cualquier scanner puede verlos. Múltiples Raspberry Pi con el mismo UUID no se interfieren porque cada dispositivo tiene un MAC address BLE único.

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `docker compose up` — permission denied | `newgrp docker` y repetir |
| `avahi-browse` vacío | `sudo systemctl restart avahi-daemon` |
| `ping mipi.local` no resuelve | `sudo ufw allow 5353/udp` |
| App no conecta al servidor | `docker compose ps` + `sudo ufw allow 2283/tcp` |
| `great-memories-ble` falla al boot | `journalctl -u great-memories-ble -n 30 --no-pager` |
| BLE devuelve `127.0.0.1` | Pi sin red; verificar `ip addr` |
| `pip install bluezero` falla compilando `pycairo` | Faltan `python3-gi python3-cairo` de apt; instalarlos, borrar `/opt/great-memories-ble/venv` y repetir |
| Paquetes rotos al instalar bluetooth | `sudo apt full-upgrade -y` antes del install |
| Path inválido en `.env` (Windows dev) | Usar `/` en vez de `\` en rutas |
| `manifest unknown` / `not found` al hacer pull | `GREAT_MEMORIES_VERSION=main` en `docker/.env` (ver paso 2.1) |
| `no matching manifest for linux/arm/v7` | SO de 32 bits; reinstalar con Raspberry Pi OS / Ubuntu de 64 bits |
| `deploy.sh` se corta en `sudo: ufw: command not found` | `sudo apt install -y ufw` y volver a correr el script |
| `mipi.local` no resuelve desde Windows | Usar la IP directa, o instalar Bonjour en esa PC |
| Contenedor `great_memories_machine_learning` reinicia en bucle | Falta de RAM; revisar `docker stats` / `free -h` |
