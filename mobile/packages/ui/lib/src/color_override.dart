import 'package:flutter/widgets.dart';

class GreatMemoriesColorOverride extends InheritedWidget {
  const GreatMemoriesColorOverride({super.key, required this.color, required super.child});

  final Color? color;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GreatMemoriesColorOverride>()?.color;

  @override
  bool updateShouldNotify(GreatMemoriesColorOverride oldWidget) => color != oldWidget.color;
}
