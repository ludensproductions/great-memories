import 'package:great_memories_mobile/platform/view_intent_api.g.dart';
import 'package:great_memories_mobile/providers/view_intent/view_intent_handler.provider.dart';

class StubViewIntentHandler implements ViewIntentHandler {
  const StubViewIntentHandler();

  @override
  void init() {}

  @override
  Future<void> onAppResumed() async {}

  @override
  Future<void> flushDeferredViewIntent() async {}

  @override
  Future<void> handle(ViewIntentPayload attachment) async {}
}
