import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/services/api.service.dart';

final apiServiceProvider = Provider((_) => ApiService());
