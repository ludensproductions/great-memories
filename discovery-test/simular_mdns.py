#!/usr/bin/env python3
"""Simulador mDNS para probar el descubrimiento de la app Immich.

Anuncia el servicio _immich._tcp en el puerto 2283 con la IP local de
esta PC, igual que lo haria Avahi en la Raspberry Pi. El telefono debe
estar conectado a la misma red WiFi que esta PC.

Uso:  python simular_mdns.py
Detener: Ctrl+C
"""

import socket
import time

from zeroconf import ServiceInfo, Zeroconf

PORT = 2283
SERVICE_TYPE = "_immich._tcp.local."


def get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    finally:
        s.close()


def main():
    ip = get_local_ip()
    info = ServiceInfo(
        SERVICE_TYPE,
        f"Immich en PC.{SERVICE_TYPE}",
        addresses=[socket.inet_aton(ip)],
        port=PORT,
        server="immich-pc.local.",
    )

    zc = Zeroconf()
    zc.register_service(info)
    print(f"Anunciando _immich._tcp -> {ip}:{PORT}")
    print("La app deberia autocompletar: http://%s:%d" % (ip, PORT))
    print("Ctrl+C para detener")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Deteniendo...")
        zc.unregister_service(info)
        zc.close()


if __name__ == "__main__":
    main()
