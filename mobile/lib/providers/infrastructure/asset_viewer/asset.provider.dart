import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/asset/base_asset.model.dart';
import 'package:great_memories_mobile/domain/models/exif.model.dart';
import 'package:great_memories_mobile/providers/infrastructure/asset.provider.dart';

final assetExifProvider = FutureProvider.autoDispose.family<ExifInfo?, BaseAsset>((ref, asset) {
  return ref.watch(assetServiceProvider).getExif(asset);
});
