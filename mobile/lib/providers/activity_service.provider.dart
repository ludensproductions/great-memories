import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/providers/infrastructure/asset.provider.dart';
import 'package:great_memories_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:great_memories_mobile/repositories/activity_api.repository.dart';
import 'package:great_memories_mobile/services/activity.service.dart';

final activityServiceProvider = Provider.autoDispose<ActivityService>((ref) {
  return ActivityService(
    ref.watch(activityApiRepositoryProvider),
    ref.watch(timelineFactoryProvider),
    ref.watch(assetServiceProvider),
  );
});
