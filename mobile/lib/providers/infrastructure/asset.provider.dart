import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/services/asset.service.dart';
import 'package:great_memories_mobile/infrastructure/repositories/local_asset.repository.dart';
import 'package:great_memories_mobile/infrastructure/repositories/remote_asset.repository.dart';
import 'package:great_memories_mobile/infrastructure/repositories/trashed_local_asset.repository.dart';
import 'package:great_memories_mobile/providers/infrastructure/db.provider.dart';
import 'package:great_memories_mobile/providers/user.provider.dart';
import 'package:great_memories_mobile/repositories/asset_api.repository.dart';

final localAssetRepository = Provider<DriftLocalAssetRepository>(
  (ref) => DriftLocalAssetRepository(ref.watch(driftProvider)),
);

final remoteAssetRepositoryProvider = Provider<RemoteAssetRepository>(
  (ref) => RemoteAssetRepository(ref.watch(driftProvider)),
);

final trashedLocalAssetRepository = Provider<DriftTrashedLocalAssetRepository>(
  (ref) => DriftTrashedLocalAssetRepository(ref.watch(driftProvider)),
);

final assetServiceProvider = Provider(
  (ref) => AssetService(
    remoteRepository: ref.watch(remoteAssetRepositoryProvider),
    localRepository: ref.watch(localAssetRepository),
    apiRepository: ref.watch(assetApiRepositoryProvider),
  ),
);

final placesProvider = FutureProvider<List<(String, String)>>((ref) {
  final assetService = ref.watch(assetServiceProvider);
  final auth = ref.watch(currentUserProvider);

  if (auth == null) {
    return Future.value(const []);
  }

  return assetService.getPlaces(auth.id);
});
