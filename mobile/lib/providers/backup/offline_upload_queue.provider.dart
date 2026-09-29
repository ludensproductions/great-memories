import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/asset/base_asset.model.dart';
import 'package:great_memories_mobile/domain/models/store.model.dart';
import 'package:great_memories_mobile/entities/store.entity.dart';
import 'package:great_memories_mobile/providers/api.provider.dart';
import 'package:great_memories_mobile/providers/infrastructure/asset.provider.dart';
import 'package:great_memories_mobile/services/foreground_upload.service.dart';
import 'package:logging/logging.dart';

/// Manual uploads requested while the server was unreachable. Persisted in the
/// Store so they survive app restarts; flushed when the websocket reconnects.
class OfflineUploadQueue {
  OfflineUploadQueue(this._ref);

  final Ref _ref;
  final _log = Logger('OfflineUploadQueue');
  bool _flushing = false;

  Set<String> get ids {
    final raw = Store.tryGet(StoreKey.offlineUploadQueue);
    return raw == null ? {} : (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _save(Set<String> ids) => Store.put(StoreKey.offlineUploadQueue, jsonEncode(ids.toList()));

  Future<void> enqueue(Iterable<LocalAsset> assets) => _save({...ids, ...assets.map((a) => a.id)});

  Future<bool> isServerReachable() async {
    try {
      await _ref.read(apiServiceProvider).serverInfoApi.pingServer().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Uploads the queue and returns how many assets were uploaded
  Future<int> flush() async {
    if (_flushing || ids.isEmpty) {
      return 0;
    }
    _flushing = true;
    try {
      final repo = _ref.read(localAssetRepository);
      final assets = <LocalAsset>[];
      final missing = <String>{};
      for (final id in ids) {
        final asset = await repo.getById(id);
        if (asset == null) {
          missing.add(id);
        } else {
          assets.add(asset);
        }
      }
      // Assets deleted from the device can never be uploaded, drop them
      if (missing.isNotEmpty) {
        await _save(ids.difference(missing));
      }
      if (assets.isEmpty) {
        return 0;
      }

      _log.info('Uploading ${assets.length} queued assets');
      final uploaded = <String>{};
      await _ref
          .read(foregroundUploadServiceProvider)
          .uploadManual(
            assets,
            callbacks: UploadCallbacks(onSuccess: (localId, _) => uploaded.add(localId)),
          );
      // Failed ones stay queued for the next reconnect
      await _save(ids.difference(uploaded));
      return uploaded.length;
    } catch (error, stack) {
      _log.severe('Failed to flush offline upload queue', error, stack);
      return 0;
    } finally {
      _flushing = false;
    }
  }
}

final offlineUploadQueueProvider = Provider((ref) => OfflineUploadQueue(ref));
