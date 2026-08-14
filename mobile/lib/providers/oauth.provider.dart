import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/services/oauth.service.dart';
import 'package:great_memories_mobile/providers/api.provider.dart';

final oAuthServiceProvider = Provider((ref) => OAuthService(ref.watch(apiServiceProvider)));
