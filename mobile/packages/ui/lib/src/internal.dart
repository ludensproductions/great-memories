import 'package:flutter/material.dart';
import 'package:immich_ui/src/color_override.dart';
import 'package:immich_ui/src/translation.dart';

extension TranslationHelper on BuildContext {
  GreatMemoriesTranslations get translations => GreatMemoriesTranslationProvider.of(this);
}

extension ColorHelper on BuildContext {
  Color? get colorOverride => GreatMemoriesColorOverride.maybeOf(this);
}
