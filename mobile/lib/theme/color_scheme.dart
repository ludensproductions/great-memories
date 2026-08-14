import 'package:flutter/material.dart';
import 'package:great_memories_mobile/constants/colors.dart';
import 'package:great_memories_mobile/theme/theme_data.dart';

final Map<GreatMemoriesColorPreset, GreatMemoriesTheme> _themePresets = {
  GreatMemoriesColorPreset.indigo: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(
      seedColor: greatMemoriesBrandColorLight,
    ).copyWith(primary: greatMemoriesBrandColorLight, onSurface: const Color.fromARGB(255, 34, 31, 32)),
    dark: ColorScheme.fromSeed(
      seedColor: greatMemoriesBrandColorDark,
      brightness: Brightness.dark,
    ).copyWith(primary: greatMemoriesBrandColorDark),
  ),
  GreatMemoriesColorPreset.deepPurple: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFF6F43C0)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFFD3BBFF), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.pink: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFFED79B5)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFFED79B5), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.red: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFFC51C16)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFFD3302F), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.orange: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(
      seedColor: const Color(0xffff5b01),
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ),
    dark: ColorScheme.fromSeed(
      seedColor: const Color(0xFFCC6D08),
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ),
  ),
  GreatMemoriesColorPreset.yellow: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB400)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB400), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.lime: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFFCDDC39)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFFCDDC39), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.green: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFF18C249)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFF18C249), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.cyan: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFF00BCD4)),
    dark: ColorScheme.fromSeed(seedColor: const Color(0xFF00BCD4), brightness: Brightness.dark),
  ),
  GreatMemoriesColorPreset.slateGray: GreatMemoriesTheme(
    light: ColorScheme.fromSeed(seedColor: const Color(0xFF696969), dynamicSchemeVariant: DynamicSchemeVariant.neutral),
    dark: ColorScheme.fromSeed(
      seedColor: const Color(0xff696969),
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    ),
  ),
};

extension GreatMemoriesColorModeExtension on GreatMemoriesColorPreset {
  GreatMemoriesTheme get themeOfPreset => _themePresets[this]!;
}
