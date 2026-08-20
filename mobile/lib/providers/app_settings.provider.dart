import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/services/app_settings.service.dart';

final appSettingsServiceProvider = Provider((_) => const AppSettingsService());
