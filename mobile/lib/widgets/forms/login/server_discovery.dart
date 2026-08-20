import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/extensions/build_context_extensions.dart';
import 'package:great_memories_mobile/services/server_discovery.service.dart';
import 'package:great_memories_mobile/widgets/common/great_memories_toast.dart';
import 'package:great_memories_ui/great_memories_ui.dart';

enum DiscoveryMethod { mdns, ble }

/// Selector shown on the login screen to automatically discover the Great Memories
/// server on the local network, either via mDNS (WiFi) or BLE (Bluetooth).
///
/// On success, [onServerFound] receives the URL as `http://<ip>:2283`.
class ServerDiscovery extends HookConsumerWidget {
  final void Function(String url) onServerFound;

  const ServerDiscovery({super.key, required this.onServerFound});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = useState(DiscoveryMethod.mdns);
    final isSearching = useState(false);

    void showError(String message) {
      GreatMemoriesToast.show(context: context, msg: message, toastType: ToastType.error, gravity: ToastGravity.TOP);
    }

    void applyServer(DiscoveredServer server) {
      onServerFound(server.url);
      GreatMemoriesToast.show(
        context: context,
        msg: 'Servidor encontrado: ${server.url}',
        toastType: ToastType.success,
        gravity: ToastGravity.TOP,
      );
    }

    Future<T?> pickFromList<T>({
      required List<T> items,
      required IconData icon,
      required String Function(T item) titleOf,
      required String Function(T item) subtitleOf,
    }) {
      return showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Se encontraron varios servidores. Elige uno:',
                  style: context.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      ListTile(
                        leading: Icon(icon),
                        title: Text(titleOf(item)),
                        subtitle: Text(subtitleOf(item)),
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> search() async {
      if (isSearching.value) {
        return;
      }
      isSearching.value = true;

      final discoveryService = ref.read(serverDiscoveryServiceProvider);

      try {
        if (method.value == DiscoveryMethod.mdns) {
          final servers = await discoveryService.discoverViaMdns();
          if (!context.mounted) {
            return;
          }
          DiscoveredServer? selected = servers.first;
          if (servers.length > 1) {
            selected = await pickFromList(
              items: servers,
              icon: Icons.dns_outlined,
              titleOf: (server) => server.name,
              subtitleOf: (server) => server.url,
            );
          }
          if (selected != null) {
            applyServer(selected);
          }
        } else {
          final devices = await discoveryService.scanForBleServers();
          if (!context.mounted) {
            return;
          }
          BleServerDevice? selected = devices.first;
          if (devices.length > 1) {
            selected = await pickFromList(
              items: devices,
              icon: Icons.bluetooth,
              titleOf: (device) => device.name,
              subtitleOf: (device) => device.id,
            );
          }
          if (selected != null) {
            final server = await discoveryService.readBleServerIp(selected);
            if (!context.mounted) {
              return;
            }
            applyServer(server);
          }
        }
      } on ServerDiscoveryException catch (e) {
        if (context.mounted) {
          showError(e.message);
        }
      } catch (e) {
        if (context.mounted) {
          showError('Error inesperado durante la búsqueda del servidor.');
        }
      } finally {
        isSearching.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GreatMemoriesSpacing.md),
        SegmentedButton<DiscoveryMethod>(
          segments: const [
            ButtonSegment(
              value: DiscoveryMethod.mdns,
              label: Text('Buscar por WiFi (mDNS)', style: TextStyle(fontSize: 12)),
              icon: Icon(Icons.wifi),
            ),
            ButtonSegment(
              value: DiscoveryMethod.ble,
              label: Text('Buscar por Bluetooth (BLE)', style: TextStyle(fontSize: 12)),
              icon: Icon(Icons.bluetooth),
            ),
          ],
          selected: {method.value},
          onSelectionChanged: isSearching.value ? null : (selection) => method.value = selection.first,
        ),
        const SizedBox(height: GreatMemoriesSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: isSearching.value ? null : search,
          icon: isSearching.value
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search_rounded),
          label: Text(isSearching.value ? 'Buscando servidor...' : 'Buscar servidor automáticamente'),
        ),
      ],
    );
  }
}
