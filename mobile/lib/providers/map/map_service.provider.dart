import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/providers/api.provider.dart';
import 'package:great_memories_mobile/services/map.service.dart';

final mapServiceProvider = Provider.autoDispose<MapService>((ref) => MapService(ref.watch(apiServiceProvider)));
