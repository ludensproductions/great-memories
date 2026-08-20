import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/services/search.service.dart';
import 'package:great_memories_mobile/infrastructure/repositories/search_api.repository.dart';
import 'package:great_memories_mobile/providers/api.provider.dart';

final searchApiRepositoryProvider = Provider((ref) => SearchApiRepository(ref.watch(apiServiceProvider).searchApi));

final searchServiceProvider = Provider((ref) => SearchService(ref.watch(searchApiRepositoryProvider)));
