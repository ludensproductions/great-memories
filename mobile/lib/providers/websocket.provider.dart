import 'dart:async';

import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/store.model.dart';
import 'package:great_memories_mobile/entities/store.entity.dart';
import 'package:great_memories_mobile/infrastructure/repositories/network.repository.dart';
import 'package:great_memories_mobile/providers/auth.provider.dart';
import 'package:great_memories_mobile/providers/background_sync.provider.dart';
import 'package:great_memories_mobile/providers/backup/offline_upload_queue.provider.dart';
import 'package:great_memories_mobile/providers/infrastructure/settings.provider.dart';
import 'package:great_memories_mobile/providers/server_info.provider.dart';
import 'package:great_memories_mobile/utils/debounce.dart';
import 'package:great_memories_mobile/utils/debug_print.dart';
import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart';

class WebsocketState {
  final Socket? socket;
  final bool isConnected;

  const WebsocketState({this.socket, required this.isConnected});

  WebsocketState copyWith({Socket? socket, bool? isConnected}) {
    return WebsocketState(socket: socket ?? this.socket, isConnected: isConnected ?? this.isConnected);
  }

  @override
  String toString() => 'WebsocketState(socket: $socket, isConnected: $isConnected)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is WebsocketState && other.socket == socket && other.isConnected == isConnected;
  }

  @override
  int get hashCode => socket.hashCode ^ isConnected.hashCode;
}

class WebsocketNotifier extends StateNotifier<WebsocketState> {
  WebsocketNotifier(this._ref) : super(const WebsocketState(socket: null, isConnected: false));

  final _log = Logger('WebsocketNotifier');
  final Ref _ref;

  final Debouncer _batchDebouncer = Debouncer(
    interval: const Duration(seconds: 5),
    maxWaitTime: const Duration(seconds: 10),
  );
  final List<dynamic> _batchedAssetUploadReady = [];

  static const _connectionNotificationId = 2000;
  bool _serverLost = false;

  @override
  void dispose() {
    _batchDebouncer.dispose();
    super.dispose();
  }

  /// Connects websocket to server unless a socket already exists (connected or reconnecting)
  void connect() {
    if (state.socket != null) {
      return;
    }
    final authenticationState = _ref.read(authProvider);

    if (authenticationState.isAuthenticated) {
      try {
        final endpoint = Uri.parse(Store.get(StoreKey.serverEndpoint));
        dPrint(() => "Attempting to connect to websocket");
        // Configure socket transports must be specified
        Socket socket = io(
          endpoint.origin,
          OptionBuilder()
              .setPath("${endpoint.path}/socket.io")
              .setTransports(['websocket'])
              .setWebSocketConnector(NetworkRepository.createWebSocket)
              .enableReconnection()
              .enableForceNew()
              .enableForceNewConnection()
              .enableAutoConnect()
              .build(),
        );
        // Keep the socket while it reconnects so disconnect() can dispose it
        state = WebsocketState(isConnected: false, socket: socket);
        // Events from a socket disposed by disconnect() are intentional, not a lost server
        bool isCurrent() => identical(state.socket, socket);

        socket.onConnect((_) {
          if (!isCurrent()) {
            return;
          }
          dPrint(() => "Established Websocket Connection");
          state = WebsocketState(isConnected: true, socket: socket);
          unawaited(_onServerRestored());
        });

        socket.onDisconnect((_) {
          if (!isCurrent()) {
            return;
          }
          dPrint(() => "Disconnect to Websocket Connection");
          state = WebsocketState(isConnected: false, socket: socket);
          _onServerLost();
        });

        socket.onConnectError((_) {
          if (!isCurrent()) {
            return;
          }
          _onServerLost();
        });

        socket.on('error', (errorMessage) {
          if (!isCurrent()) {
            return;
          }
          _log.severe("Websocket Error - $errorMessage");
          state = WebsocketState(isConnected: false, socket: socket);
        });

        socket.on('AssetUploadReadyV1', _handleSyncAssetUploadReadyV1);
        socket.on('AssetUploadReadyV2', _handleSyncAssetUploadReadyV2);
        socket.on('AssetEditReadyV1', _handleSyncAssetEditReadyV1);
        socket.on('AssetEditReadyV2', _handleSyncAssetEditReadyV2);
        socket.on('on_album_update', _handleAlbumUpdate);
        socket.on('on_config_update', _handleOnConfigUpdate);
      } catch (e) {
        dPrint(() => "[WEBSOCKET] Catch Websocket Error - ${e.toString()}");
      }
    }
  }

  void disconnect() {
    dPrint(() => "Attempting to disconnect from websocket");

    _batchedAssetUploadReady.clear();

    final socket = state.socket;
    state = const WebsocketState(isConnected: false, socket: null);
    socket?.dispose();
  }

  void _onServerLost() {
    if (_serverLost) {
      return;
    }
    _serverLost = true;
    _notifyConnection('server_connection_lost_title'.t(), 'server_connection_lost_body'.t());
  }

  Future<void> _onServerRestored() async {
    if (_serverLost) {
      _serverLost = false;
      _notifyConnection('server_connection_restored_title'.t(), 'server_connection_restored_body'.t());
    }
    final uploaded = await _ref.read(offlineUploadQueueProvider).flush();
    if (uploaded > 0) {
      _notifyConnection(
        'queued_uploads_done_title'.t(),
        'queued_uploads_done_body'.t(args: {'count': uploaded}),
      );
    }
  }

  // Same id so "restored" replaces "lost" instead of stacking
  void _notifyConnection(String title, String body) {
    unawaited(
      FlutterLocalNotificationsPlugin().show(
        _connectionNotificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'great-memories::server_connection',
            'Server connection',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      ),
    );
  }

  Future<void> waitForEvent(String event, bool Function(dynamic)? predicate, Duration timeout) {
    final completer = Completer<void>();

    void handler(dynamic data) {
      if (predicate == null || predicate(data)) {
        completer.complete();
        state.socket?.off(event, handler);
      }
    }

    state.socket?.on(event, handler);

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        state.socket?.off(event, handler);
        completer.completeError(TimeoutException("Timeout waiting for event: $event"));
      },
    );
  }

  void _handleOnConfigUpdate(dynamic _) {
    _ref.read(serverInfoProvider.notifier).getServerFeatures();
    _ref.read(serverInfoProvider.notifier).getServerConfig();
  }

  void _handleSyncAssetUploadReadyV1(dynamic data) {
    _batchedAssetUploadReady.add(data);
    _batchDebouncer.run(_processBatchedAssetUploadReadyV1);
  }

  void _handleSyncAssetUploadReadyV2(dynamic data) {
    _batchedAssetUploadReady.add(data);
    _batchDebouncer.run(_processBatchedAssetUploadReadyV2);
  }

  void _handleSyncAssetEditReadyV1(dynamic data) {
    unawaited(_ref.read(backgroundSyncProvider).syncWebsocketEditV1(data));
  }

  void _handleAlbumUpdate(dynamic _) {
    unawaited(_ref.read(backgroundSyncProvider).syncRemote());
  }

  void _handleSyncAssetEditReadyV2(dynamic data) {
    unawaited(_ref.read(backgroundSyncProvider).syncWebsocketEditV2(data));
  }

  void _processBatchedAssetUploadReadyV1() {
    if (_batchedAssetUploadReady.isEmpty) {
      return;
    }

    final isSyncAlbumEnabled = _ref.read(appConfigProvider).backup.syncAlbums;
    try {
      unawaited(
        _ref.read(backgroundSyncProvider).syncWebsocketBatchV1(_batchedAssetUploadReady.toList()).then((_) {
          if (isSyncAlbumEnabled) {
            _ref.read(backgroundSyncProvider).syncLinkedAlbum();
          }
        }),
      );
    } catch (error) {
      _log.severe("Error processing batched AssetUploadReadyV1 events: $error");
    }

    _batchedAssetUploadReady.clear();
  }

  void _processBatchedAssetUploadReadyV2() {
    if (_batchedAssetUploadReady.isEmpty) {
      return;
    }

    final isSyncAlbumEnabled = _ref.read(appConfigProvider).backup.syncAlbums;
    try {
      unawaited(
        _ref.read(backgroundSyncProvider).syncWebsocketBatchV2(_batchedAssetUploadReady.toList()).then((_) {
          if (isSyncAlbumEnabled) {
            _ref.read(backgroundSyncProvider).syncLinkedAlbum();
          }
        }),
      );
    } catch (error) {
      _log.severe("Error processing batched AssetUploadReadyV2 events: $error");
    }

    _batchedAssetUploadReady.clear();
  }
}

final websocketProvider = StateNotifierProvider<WebsocketNotifier, WebsocketState>((ref) {
  return WebsocketNotifier(ref);
});
