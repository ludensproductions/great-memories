import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/asset/base_asset.model.dart';
import 'package:great_memories_mobile/domain/services/store.service.dart';
import 'package:great_memories_mobile/infrastructure/repositories/db.repository.dart';
import 'package:great_memories_mobile/infrastructure/repositories/store.repository.dart';
import 'package:great_memories_mobile/providers/backup/offline_upload_queue.provider.dart';
import 'package:great_memories_mobile/providers/infrastructure/asset.provider.dart';
import 'package:great_memories_mobile/services/foreground_upload.service.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/asset.stub.dart';
import '../../infrastructure/repository.mock.dart';

class MockForegroundUploadService extends Mock implements ForegroundUploadService {}

void main() {
  late MockLocalAssetRepository localRepo;
  late MockForegroundUploadService uploadService;
  late ProviderContainer container;

  setUpAll(() async {
    registerFallbackValue(<LocalAsset>[]);
    registerFallbackValue(const UploadCallbacks());
    final db = Drift(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await StoreService.init(storeRepository: DriftStoreRepository(db));
  });

  setUp(() {
    localRepo = MockLocalAssetRepository();
    uploadService = MockForegroundUploadService();
    container = ProviderContainer(
      overrides: [
        localAssetRepository.overrideWithValue(localRepo),
        foregroundUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );
    addTearDown(container.dispose);
  });

  test('flush keeps failed assets queued and drops uploaded and deleted ones', () async {
    final queue = container.read(offlineUploadQueueProvider);
    await queue.enqueue([LocalAssetStub.image1, LocalAssetStub.image2]);
    await queue.enqueue([LocalAssetStub.image1.copyWith(id: 'deleted-from-device')]);
    expect(queue.ids, {'image1', 'image2', 'deleted-from-device'});

    when(() => localRepo.getById('image1')).thenAnswer((_) async => LocalAssetStub.image1);
    when(() => localRepo.getById('image2')).thenAnswer((_) async => LocalAssetStub.image2);
    when(() => localRepo.getById('deleted-from-device')).thenAnswer((_) async => null);
    // Only image1 uploads, image2 fails
    when(() => uploadService.uploadManual(any(), callbacks: any(named: 'callbacks'))).thenAnswer((inv) async {
      (inv.namedArguments[#callbacks] as UploadCallbacks).onSuccess!('image1', 'remote-1');
    });

    expect(await queue.flush(), 1);

    expect(queue.ids, {'image2'});
    final uploaded = verify(() => uploadService.uploadManual(captureAny(), callbacks: any(named: 'callbacks')))
        .captured
        .single as List<LocalAsset>;
    expect(uploaded.map((a) => a.id), unorderedEquals(['image1', 'image2']));
  });
}
