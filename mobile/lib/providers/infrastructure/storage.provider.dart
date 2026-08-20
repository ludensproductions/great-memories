import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/infrastructure/repositories/storage.repository.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) => StorageRepository());
