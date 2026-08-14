import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/ocr.model.dart';
import 'package:great_memories_mobile/domain/services/ocr.service.dart';
import 'package:great_memories_mobile/infrastructure/repositories/ocr.repository.dart';
import 'package:great_memories_mobile/providers/infrastructure/db.provider.dart';

final ocrRepositoryProvider = Provider<OcrRepository>((ref) => OcrRepository(ref.watch(driftProvider)));

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService(ref.watch(ocrRepositoryProvider)));

final ocrAssetProvider = FutureProvider.autoDispose.family<List<Ocr>?, String>((ref, assetId) async {
  final service = ref.watch(ocrServiceProvider);
  return service.get(assetId);
});
