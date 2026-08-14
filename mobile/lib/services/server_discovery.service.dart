import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:permission_handler/permission_handler.dart';

final serverDiscoveryServiceProvider = Provider((ref) => ServerDiscoveryService());

/// Shared constants between this client and the server configuration
/// documented in CONFIGURACION-SERVIDOR.md. Both sides must match exactly.
class ServerDiscoveryConstants {
  const ServerDiscoveryConstants._();

  /// mDNS service type announced by Avahi on the server.
  static const String mdnsServiceType = '_great_memories._tcp';
  static const String mdnsServiceDomain = '_great_memories._tcp.local';

  /// Port where the Great Memories server listens.
  static const int serverPort = 2283;

  // Hardcodeados como constantes de protocolo — igual que _great_memories._tcp y el
  // puerto 2283. El UUID identifica el tipo de servicio BLE, no es un secreto:
  // BLE advertising es público y cualquier scanner puede verlo.
  // Múltiples Great Memories en la misma red no se interfieren porque cada
  // dispositivo tiene un MAC address BLE único.
  static final Guid bleServiceUuid = Guid('494d4d49-0000-1000-8000-000000002283');
  static final Guid bleIpCharacteristicUuid = Guid('494d4d49-0001-1000-8000-000000002283');

  static const Duration scanTimeout = Duration(seconds: 10);
}

enum ServerDiscoveryErrorType { timeout, notFound, permissionDenied, bluetoothOff, unknown }

class ServerDiscoveryException implements Exception {
  final ServerDiscoveryErrorType type;
  final String message;

  const ServerDiscoveryException(this.type, this.message);

  @override
  String toString() => 'ServerDiscoveryException($type): $message';
}

class DiscoveredServer {
  final String name;
  final String ip;
  final int port;

  const DiscoveredServer({required this.name, required this.ip, required this.port});

  String get url => 'http://$ip:$port';
}

/// A BLE peripheral advertising the Great Memories service UUID, found during a scan.
/// The server IP is not known yet: it requires connecting and reading the
/// characteristic via [ServerDiscoveryService.readBleServerIp].
class BleServerDevice {
  final BluetoothDevice device;
  final String advertisedName;

  const BleServerDevice({required this.device, required this.advertisedName});

  String get name => advertisedName.isEmpty ? 'Great Memories' : advertisedName;

  String get id => device.remoteId.str;
}

class ServerDiscoveryService {
  final _log = Logger('ServerDiscoveryService');

  /// Browses the local network for `_great_memories._tcp` services.
  ///
  /// Returns every distinct server found within the scan window. Throws
  /// [ServerDiscoveryException] with [ServerDiscoveryErrorType.notFound]
  /// when the scan window elapses without any result.
  Future<List<DiscoveredServer>> discoverViaMdns() async {
    final client = MDnsClient();
    final found = <String, DiscoveredServer>{};

    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(ServerDiscoveryConstants.mdnsServiceDomain),
        timeout: ServerDiscoveryConstants.scanTimeout,
      )) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: const Duration(seconds: 3),
        )) {
          await for (final IPAddressResourceRecord addr in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
            timeout: const Duration(seconds: 3),
          )) {
            // multicast_dns may return a hostname string instead of a numeric IP.
            // Resolve it via system DNS (which handles .local on mobile) as fallback.
            String? ip = addr.address.address;
            if (InternetAddress.tryParse(ip) == null) {
              try {
                final resolved = await InternetAddress.lookup(ip, type: InternetAddressType.IPv4);
                ip = resolved.firstOrNull?.address;
              } catch (_) {
                ip = null;
              }
            }
            if (ip == null) continue;

            final name = ptr.domainName
                .replaceAll('.${ServerDiscoveryConstants.mdnsServiceDomain}', '')
                .replaceAll(ServerDiscoveryConstants.mdnsServiceDomain, '');
            found[ip] = DiscoveredServer(
              name: name.isEmpty ? srv.target : name,
              ip: ip,
              port: srv.port,
            );
          }
        }
      }
    } on SocketException catch (e) {
      _log.warning('mDNS socket error', e);
      throw const ServerDiscoveryException(
        ServerDiscoveryErrorType.unknown,
        'No se pudo iniciar la búsqueda mDNS. Verifica que estés conectado a la red WiFi.',
      );
    } finally {
      client.stop();
    }

    if (found.isEmpty) {
      throw const ServerDiscoveryException(
        ServerDiscoveryErrorType.notFound,
        'No se encontró ningún servidor Great Memories en la red (tiempo de espera agotado).',
      );
    }

    return found.values.toList();
  }

  /// Scans during the whole [ServerDiscoveryConstants.scanTimeout] window and
  /// returns every distinct BLE peripheral advertising the Great Memories service UUID.
  Future<List<BleServerDevice>> scanForBleServers() async {
    await _ensureBlePermissions();
    await _ensureBluetoothOn();

    final found = <String, BleServerDevice>{};

    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        found[result.device.remoteId.str] = BleServerDevice(
          device: result.device,
          advertisedName: result.advertisementData.advName,
        );
      }
    });

    try {
      // Filter by service UUID instead of name: iOS does not always expose
      // the peripheral name in the advertising packet.
      await FlutterBluePlus.startScan(
        withServices: [ServerDiscoveryConstants.bleServiceUuid],
        timeout: ServerDiscoveryConstants.scanTimeout,
      );

      // Wait for the scan window to finish so every nearby server is collected.
      await FlutterBluePlus.isScanning
          .where((scanning) => !scanning)
          .first
          .timeout(ServerDiscoveryConstants.scanTimeout + const Duration(seconds: 2));
    } on TimeoutException {
      // Scan did not report completion; fall through with whatever was found.
    } finally {
      await subscription.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _log.warning('Failed to stop BLE scan', e);
      }
    }

    if (found.isEmpty) {
      throw const ServerDiscoveryException(
        ServerDiscoveryErrorType.timeout,
        'No se encontró el servidor por Bluetooth (tiempo de espera agotado). '
        'Verifica que el servidor esté encendido y cerca.',
      );
    }

    return found.values.toList();
  }

  /// Connects to a previously scanned server and reads the characteristic
  /// containing the host IP.
  Future<DiscoveredServer> readBleServerIp(BleServerDevice server) async {
    final device = server.device;

    await device.connect(timeout: ServerDiscoveryConstants.scanTimeout);
    try {
      final services = await device.discoverServices();
      final service = services.where((s) => s.uuid == ServerDiscoveryConstants.bleServiceUuid).firstOrNull;
      if (service == null) {
        throw const ServerDiscoveryException(
          ServerDiscoveryErrorType.notFound,
          'El dispositivo encontrado no expone el servicio Great Memories.',
        );
      }

      final characteristic = service.characteristics
          .where((c) => c.uuid == ServerDiscoveryConstants.bleIpCharacteristicUuid)
          .firstOrNull;
      if (characteristic == null) {
        throw const ServerDiscoveryException(
          ServerDiscoveryErrorType.notFound,
          'El servidor no expone la característica con la dirección IP.',
        );
      }

      final bytes = await characteristic.read();
      final ip = utf8.decode(bytes).trim();
      if (ip.isEmpty || InternetAddress.tryParse(ip) == null) {
        throw ServerDiscoveryException(
          ServerDiscoveryErrorType.unknown,
          'El servidor devolvió una dirección IP inválida: "$ip".',
        );
      }

      return DiscoveredServer(name: server.name, ip: ip, port: ServerDiscoveryConstants.serverPort);
    } finally {
      try {
        await device.disconnect();
      } catch (e) {
        _log.warning('Failed to disconnect BLE device', e);
      }
    }
  }

  Future<void> _ensureBlePermissions() async {
    if (!Platform.isAndroid) {
      // iOS shows its own Bluetooth permission prompt on first use; a denied
      // permission surfaces as an adapter state other than "on".
      return;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied);
    if (denied) {
      throw const ServerDiscoveryException(
        ServerDiscoveryErrorType.permissionDenied,
        'Permisos de Bluetooth o ubicación denegados. Habilítalos en los ajustes del sistema.',
      );
    }
  }

  Future<void> _ensureBluetoothOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .where((state) => state != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 5));

      if (state == BluetoothAdapterState.unauthorized) {
        throw const ServerDiscoveryException(
          ServerDiscoveryErrorType.permissionDenied,
          'Permiso de Bluetooth denegado. Habilítalo en los ajustes del sistema.',
        );
      }
      if (state != BluetoothAdapterState.on) {
        throw const ServerDiscoveryException(
          ServerDiscoveryErrorType.bluetoothOff,
          'El Bluetooth está apagado. Enciéndelo e inténtalo de nuevo.',
        );
      }
    } on TimeoutException {
      throw const ServerDiscoveryException(
        ServerDiscoveryErrorType.bluetoothOff,
        'No se pudo determinar el estado del Bluetooth.',
      );
    }
  }

}
