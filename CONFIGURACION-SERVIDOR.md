# Configuración del servidor (Raspberry Pi) para descubrimiento automático

Esta guía explica, paso a paso, cómo dejar el servidor Immich (Raspberry Pi con
Ubuntu Server) listo para ser **descubierto automáticamente** por la aplicación
móvil de Immich mediante dos mecanismos:

1. **mDNS (WiFi)** — usando Avahi, anunciando el servicio `_immich._tcp` en el
   puerto 2283 y resolviendo el nombre `immich.local`.
2. **BLE (Bluetooth Low Energy)** — usando BlueZ + bluezero, anunciando un
   Service UUID fijo y exponiendo la IP local del host mediante una
   característica de lectura.

No hace falta modificar Immich ni sus contenedores: todo lo que se configura
aquí son servicios del sistema operativo del host.

> ⚠️ **IMPORTANTE — Valores compartidos con la app móvil**
>
> Estos valores están escritos en el código del cliente Flutter
> (`mobile/lib/services/server_discovery.service.dart`) y **deben usarse
> exactamente igual** en el servidor. Si se cambian en un lado, hay que
> cambiarlos en el otro:
>
> | Concepto                        | Valor                                  |
> |---------------------------------|----------------------------------------|
> | Tipo de servicio mDNS           | `_immich._tcp`                         |
> | Hostname mDNS                   | `immich` (resuelve como `immich.local`)|
> | Puerto del servidor             | `2283`                                 |
> | Service UUID (BLE, advertising) | `494d4d49-0000-1000-8000-000000002283` |
> | Characteristic UUID (BLE, IP)   | `494d4d49-0001-1000-8000-000000002283` |

---

## 1. Requisitos previos

- Raspberry Pi (3, 4 o 5) con **Ubuntu Server** instalado y acceso por SSH o
  consola con un usuario con permisos `sudo`.
- **Immich ya corriendo en Docker** y escuchando en el puerto **2283** del host
  (configuración estándar de Immich).
- **Adaptador Bluetooth** funcional. Las Raspberry Pi 3/4/5 lo traen integrado;
  si se usa un adaptador USB, debe ser compatible con BLE (Bluetooth 4.0+).
- La Raspberry Pi y el teléfono deben estar **en la misma red local** para el
  descubrimiento por mDNS. Para BLE solo hace falta estar físicamente cerca
  (unos metros).
- Conexión a internet en la Pi para instalar paquetes.

> 📌 **Nota clave sobre Docker**: tanto Avahi como el script BLE se instalan y
> ejecutan **directamente en el host** (Ubuntu), **fuera de los contenedores
> Docker**. Esto es imprescindible: si corrieran dentro de un contenedor,
> anunciarían la IP interna del contenedor (ej. `172.17.x.x`), que no es
> accesible desde el teléfono. Ejecutándolos en el host se anuncia la IP real
> de la Raspberry Pi en la red local.

---

## 2. Descubrimiento por WiFi (mDNS con Avahi)

### 2.1. Instalar Avahi

```bash
sudo apt update
sudo apt install -y avahi-daemon avahi-utils
```

### 2.2. Habilitar el arranque automático en cada boot

```bash
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
```

### 2.3. Fijar el hostname como "immich"

Avahi anuncia automáticamente el nombre del equipo como `<hostname>.local`.
Para que el servidor resuelva como `immich.local`:

```bash
sudo hostnamectl set-hostname immich
```

Edita también `/etc/hosts` para que el nuevo nombre resuelva localmente:

```bash
sudo nano /etc/hosts
```

Busca la línea que empieza por `127.0.1.1` (o añádela si no existe) y déjala así:

```
127.0.1.1    immich
```

Reinicia Avahi para que tome el nuevo nombre:

```bash
sudo systemctl restart avahi-daemon
```

### 2.4. Anunciar el servicio `_immich._tcp` en el puerto 2283

Crea el archivo de servicio de Avahi:

```bash
sudo nano /etc/avahi/services/immich.service
```

Pega **exactamente** este contenido:

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

Guarda el archivo (en `nano`: `Ctrl+O`, `Enter`, `Ctrl+X`). Avahi detecta y
recarga automáticamente los archivos de `/etc/avahi/services/`, pero puedes
forzar el reinicio para asegurarte:

```bash
sudo systemctl restart avahi-daemon
```

Con esto, cualquier cliente de la red puede descubrir el servicio buscando el
tipo `_immich._tcp` (que es justamente lo que hace la app móvil con la opción
**"Buscar por WiFi (mDNS)"**).

> Si usas el firewall `ufw`, permite el tráfico mDNS y el puerto de Immich:
>
> ```bash
> sudo ufw allow 5353/udp
> sudo ufw allow 2283/tcp
> ```

---

## 3. Descubrimiento por Bluetooth (BLE con BlueZ + bluezero)

### 3.1. Instalar BlueZ y dependencias de Python

```bash
sudo apt update
sudo apt install -y bluetooth bluez python3-venv python3-dbus libdbus-1-dev libglib2.0-dev
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### 3.2. Crear el entorno de Python e instalar bluezero

En versiones recientes de Ubuntu, `pip` no permite instalar paquetes en el
sistema directamente (PEP 668), así que usamos un entorno virtual con acceso
a los paquetes del sistema (necesario para `python3-dbus`):

```bash
sudo mkdir -p /opt/immich-ble
sudo python3 -m venv --system-site-packages /opt/immich-ble/venv
sudo /opt/immich-ble/venv/bin/pip install bluezero
```

### 3.3. Crear el script del periférico BLE (servidor GATT)

Este script:

- Anuncia por BLE el **Service UUID** `494d4d49-0000-1000-8000-000000002283`
  dentro del paquete de *advertising* (la app filtra por este UUID, no por
  nombre, porque iOS no siempre expone el nombre en el advertising).
- Expone una **característica de solo lectura** con UUID
  `494d4d49-0001-1000-8000-000000002283` que devuelve la **IP local del host**
  como texto UTF-8 (ej. `192.168.1.50`). La IP se calcula en cada lectura, por
  lo que siempre está actualizada aunque el router asigne otra IP.

Crea el archivo:

```bash
sudo nano /opt/immich-ble/immich_ble_server.py
```

Pega **exactamente** este contenido:

```python
#!/usr/bin/env python3
"""Periférico BLE de descubrimiento para Immich.

Anuncia el Service UUID de Immich y expone la IP local del host
en una característica de lectura. Debe ejecutarse en el HOST
(fuera de Docker) para reportar la IP real de la Raspberry Pi.

UUIDs compartidos con la app móvil de Immich
(mobile/lib/services/server_discovery.service.dart) — no cambiar
uno sin cambiar el otro.
"""

import logging
import socket

from bluezero import adapter, peripheral

SERVICE_UUID = '494d4d49-0000-1000-8000-000000002283'
IP_CHARACTERISTIC_UUID = '494d4d49-0001-1000-8000-000000002283'
LOCAL_NAME = 'immich'

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('immich-ble')


def get_local_ip() -> str:
    """Devuelve la IP local del host usada para salir a la red.

    No envía tráfico real: solo se usa el socket para que el
    sistema operativo seleccione la interfaz/IP de salida.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except OSError:
        return '127.0.0.1'
    finally:
        s.close()


def read_ip() -> list:
    """Callback de lectura de la característica: IP como bytes UTF-8."""
    ip = get_local_ip()
    log.info('Caracteristica leida, devolviendo IP: %s', ip)
    return list(ip.encode('utf-8'))


def main():
    dongles = list(adapter.Adapter.available())
    if not dongles:
        raise RuntimeError('No se encontro ningun adaptador Bluetooth')

    dongle = dongles[0]
    log.info('Usando adaptador Bluetooth: %s', dongle.address)

    periph = peripheral.Peripheral(
        dongle.address,
        local_name=LOCAL_NAME,
    )

    # Servicio primario: bluezero lo incluye en el advertising.
    periph.add_service(srv_id=1, uuid=SERVICE_UUID, primary=True)

    periph.add_characteristic(
        srv_id=1,
        chr_id=1,
        uuid=IP_CHARACTERISTIC_UUID,
        value=[],
        notifying=False,
        flags=['read'],
        read_callback=read_ip,
    )

    log.info('Publicando periferico BLE (service UUID %s)...', SERVICE_UUID)
    periph.publish()


if __name__ == '__main__':
    main()
```

Guarda el archivo y dale permisos de ejecución:

```bash
sudo chmod +x /opt/immich-ble/immich_ble_server.py
```

### 3.4. Prueba manual (opcional pero recomendada)

Antes de crear el servicio, comprueba que el script funciona:

```bash
sudo /opt/immich-ble/venv/bin/python /opt/immich-ble/immich_ble_server.py
```

Deberías ver el mensaje `Publicando periferico BLE...` y el proceso se queda
en ejecución. Detenlo con `Ctrl+C` cuando termines la prueba.

### 3.5. Servicio systemd con arranque automático y reinicio ante fallos

Crea la unidad de systemd:

```bash
sudo nano /etc/systemd/system/immich-ble.service
```

Pega **exactamente** este contenido:

```ini
[Unit]
Description=Immich BLE discovery (anuncia Service UUID y expone la IP del host)
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
```

Habilítalo y arráncalo:

```bash
sudo systemctl daemon-reload
sudo systemctl enable immich-ble
sudo systemctl start immich-ble
```

Con `Restart=always` y `RestartSec=5`, si el script falla por cualquier motivo
(por ejemplo, el adaptador Bluetooth tarda en estar disponible tras el boot),
systemd lo reintenta automáticamente cada 5 segundos.

---

## 4. Verificación tras un reinicio real

Reinicia la Raspberry Pi para comprobar que todo arranca solo:

```bash
sudo reboot
```

Tras el reinicio, conéctate de nuevo por SSH y ejecuta las siguientes
comprobaciones **en orden**.

### 4.1. Servicios habilitados para el arranque

```bash
systemctl is-enabled avahi-daemon
systemctl is-enabled bluetooth
systemctl is-enabled immich-ble
```

Los tres deben responder `enabled`.

### 4.2. Servicios en ejecución

```bash
systemctl status avahi-daemon --no-pager
systemctl status bluetooth --no-pager
systemctl status immich-ble --no-pager
```

Los tres deben mostrar `Active: active (running)`. Si `immich-ble` falla,
revisa sus logs con:

```bash
journalctl -u immich-ble -n 50 --no-pager
```

### 4.3. Verificar el anuncio mDNS

Desde la propia Pi:

```bash
avahi-browse -rt _immich._tcp
```

Salida esperada (la IP variará según tu red):

```
+ wlan0 IPv4 Immich en immich    _immich._tcp    local
= wlan0 IPv4 Immich en immich    _immich._tcp    local
   hostname = [immich.local]
   address = [192.168.1.50]
   port = [2283]
```

### 4.4. Verificar la resolución de `immich.local`

Desde **otro equipo de la misma red** (portátil, otra Pi, etc.):

```bash
ping immich.local
```

Debe responder con la IP de la Raspberry Pi. También puedes comprobar que
Immich responde:

```bash
curl http://immich.local:2283/api/server/ping
```

Respuesta esperada: `{"res":"pong"}`.

### 4.5. Verificar el advertising BLE

Opción A — desde la propia Pi, captura el tráfico Bluetooth mientras el
servicio anuncia:

```bash
sudo btmon
```

En la salida deberías ver bloques `LE Advertising` que incluyan el UUID
`494d4d49-0000-1000-8000-000000002283`. Sal con `Ctrl+C`.

Opción B — desde un teléfono con la app **nRF Connect** (Android/iOS):
escanea y busca un dispositivo que anuncie el Service UUID
`494d4d49-0000-1000-8000-000000002283` (en Android aparecerá también con el
nombre `immich`). Conéctate, abre el servicio y **lee la característica**
`494d4d49-0001-1000-8000-000000002283`: debe devolver la IP de la Pi como
texto (ej. `192.168.1.50`).

### 4.6. Prueba final con la app móvil de Immich

1. Abre la app y ve a la pantalla de login.
2. Con **"Buscar por WiFi (mDNS)"** seleccionado, pulsa
   **"Buscar servidor automáticamente"**: el campo de URL debe autocompletarse
   con `http://<ip-de-la-pi>:2283`.
3. Borra el campo, cambia a **"Buscar por Bluetooth (BLE)"** y repite: debe
   autocompletarse con la misma URL.

---

## 5. Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| `avahi-browse` no muestra el servicio | Archivo de servicio mal ubicado o con errores | Verifica que `/etc/avahi/services/immich.service` existe y reinicia `avahi-daemon` |
| `ping immich.local` no resuelve | El cliente no soporta mDNS o hay firewall | Permite UDP 5353; en Windows antiguo instala Bonjour |
| La app encuentra el servidor por mDNS pero no conecta | El puerto 2283 está bloqueado o Immich no corre | `docker ps` para verificar Immich y `sudo ufw allow 2283/tcp` |
| `immich-ble` falla al arrancar | Bluetooth aún no disponible al hacer boot | Es normal en el primer intento: `Restart=always` lo reintenta solo; verifica con `systemctl status immich-ble` |
| El teléfono no ve el dispositivo BLE | Adaptador apagado o bloqueado | `sudo rfkill unblock bluetooth` y `sudo systemctl restart bluetooth immich-ble` |
| La característica BLE devuelve `127.0.0.1` | La Pi no tiene salida de red al leer la IP | Verifica la conexión de red de la Pi (`ip addr`) |
