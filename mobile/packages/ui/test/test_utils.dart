import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:great_memories_ui/src/snackbar.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpTestWidget(Widget widget) {
    return pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: Scaffold(body: widget),
      ),
    );
  }
}
