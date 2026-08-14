import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/services/feature_message.service.dart';
import 'package:great_memories_mobile/providers/infrastructure/settings.provider.dart';

final featureMessageServiceProvider = Provider<FeatureMessageService>(
  (ref) => FeatureMessageService(ref.read(settingsProvider)),
);
