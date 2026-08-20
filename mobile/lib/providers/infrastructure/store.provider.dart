import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/services/store.service.dart';

final storeServiceProvider = Provider((_) => StoreService.I);
