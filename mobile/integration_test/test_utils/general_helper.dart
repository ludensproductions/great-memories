import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/main.dart' as app;
import 'package:immich_mobile/providers/infrastructure/db.provider.dart';
import 'package:immich_mobile/utils/bootstrap.dart';
import 'package:integration_test/integration_test.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';

import 'login_helper.dart';

class GreatMemoriesTestHelper {
  final WidgetTester tester;

  GreatMemoriesTestHelper(this.tester);

  GreatMemoriesTestLoginHelper? _loginHelper;

  GreatMemoriesTestLoginHelper get loginHelper {
    _loginHelper ??= GreatMemoriesTestLoginHelper(tester);
    return _loginHelper!;
  }

  static Future<IntegrationTestWidgetsFlutterBinding> initialize() async {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    // Load hive, localization...
    await app.initApp();

    return binding;
  }

  static Future<void> loadApp(WidgetTester tester) async {
    await EasyLocalization.ensureInitialized();
    // Clear all data from Isar (reuse existing instance if available)
    final (drift, _) = await Bootstrap.initDomain();
    await Store.clear();
    // Load main Widget
    await tester.pumpWidget(
      ProviderScope(overrides: [driftProvider.overrideWith(driftOverride(drift))], child: const app.MainWidget()),
    );
    // Post run tasks
    await EasyLocalization.ensureInitialized();
  }
}

@isTest
void greatMemoriesWidgetTest(String description, Future<void> Function(WidgetTester, GreatMemoriesTestHelper) test) {
  testWidgets(description, (widgetTester) async {
    await GreatMemoriesTestHelper.loadApp(widgetTester);
    await test(widgetTester, GreatMemoriesTestHelper(widgetTester));
  }, semanticsEnabled: false);
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 120),
}) async {
  bool found = false;
  final timer = Timer(timeout, () => throw TimeoutException("Pump until has timed out"));
  while (found != true) {
    await tester.pump();
    found = tester.any(finder);
  }
  timer.cancel();
}
