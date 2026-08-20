import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/color_override.dart';
import 'package:great_memories_ui/src/translation.dart';

extension TranslationHelper on BuildContext {
  GreatMemoriesTranslations get translations => GreatMemoriesTranslationProvider.of(this);
}

extension ColorHelper on BuildContext {
  Color? get colorOverride => GreatMemoriesColorOverride.maybeOf(this);
}
