#!/usr/bin/env python3
"""Simulador BLE para probar el descubrimiento de la app Immich (Windows).

Convierte esta PC en un periferico BLE (servidor GATT) que anuncia el
Service UUID de Immich y expone la IP local en una caracteristica de
lectura, igual que lo haria el script bluezero en la Raspberry Pi.

Usa la API WinRT de Windows directamente (paquetes winrt-*).

Los UUIDs deben coincidir con los del cliente Flutter
(mobile/lib/services/server_discovery.service.dart).

Uso:  python simular_ble.py
Detener: Ctrl+C
"""

import asyncio
import socket
import uuid

from winrt.windows.devices.bluetooth import BluetoothAdapter
from winrt.windows.devices.bluetooth.genericattributeprofile import (
    GattCharacteristicProperties,
    GattLocalCharacteristicParameters,
    GattServiceProvider,
    GattServiceProviderAdvertisementStatus,
    GattServiceProviderAdvertisingParameters,
)
from winrt.windows.storage.streams import DataWriter

SERVICE_UUID = uuid.UUID("494d4d49-0000-1000-8000-000000002283")
IP_CHARACTERISTIC_UUID = uuid.UUID("494d4d49-0001-1000-8000-000000002283")


def get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


async def main():
    adapter = await BluetoothAdapter.get_default_async()
    if adapter is None:
        raise SystemExit("ERROR: no se encontro ningun adaptador Bluetooth.")
    if not adapter.is_peripheral_role_supported:
        raise SystemExit(
            "ERROR: este adaptador Bluetooth NO soporta el modo periferico "
            "(no puede anunciarse como servidor BLE). Prueba con otro equipo "
            "o simula el periferico con la app nRF Connect en otro telefono."
        )

    ip = get_local_ip()

    result = await GattServiceProvider.create_async(SERVICE_UUID)
    if result.error != 0:  # BluetoothError.success == 0
        raise SystemExit(f"ERROR creando el servicio GATT: {result.error}")
    provider = result.service_provider

    writer = DataWriter()
    writer.write_bytes(ip.encode("utf-8"))

    params = GattLocalCharacteristicParameters()
    params.characteristic_properties = GattCharacteristicProperties.READ
    params.static_value = writer.detach_buffer()

    char_result = await provider.service.create_characteristic_async(IP_CHARACTERISTIC_UUID, params)
    if char_result.error != 0:
        raise SystemExit(f"ERROR creando la caracteristica: {char_result.error}")

    adv = GattServiceProviderAdvertisingParameters()
    adv.is_connectable = True
    adv.is_discoverable = True
    provider.start_advertising_with_parameters(adv)

    # El estado tarda un instante en pasar de CREATED/ABORTED a STARTED.
    await asyncio.sleep(2)
    status = GattServiceProviderAdvertisementStatus(provider.advertisement_status)
    print(f"Estado del advertising: {status.name}")
    if status != GattServiceProviderAdvertisementStatus.STARTED:
        print("ADVERTENCIA: el advertising no arranco correctamente. Verifica que el Bluetooth este encendido.")
    print(f"Anunciando BLE con service UUID {SERVICE_UUID}")
    print(f"La caracteristica de IP devuelve: {ip}")
    print(f"La app deberia autocompletar: http://{ip}:2283")
    print("Ctrl+C para detener")

    try:
        await asyncio.Event().wait()
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        print("Deteniendo...")
        provider.stop_advertising()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
