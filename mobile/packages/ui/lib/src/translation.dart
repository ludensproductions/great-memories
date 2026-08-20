import 'package:flutter/material.dart';

class GreatMemoriesTranslations {
  late String submit;
  late String password;

  GreatMemoriesTranslations({String? submit, String? password}) {
    this.submit = submit ?? 'Submit';
    this.password = password ?? 'Password';
  }
}

class GreatMemoriesTranslationProvider extends InheritedWidget {
  final GreatMemoriesTranslations? translations;

  const GreatMemoriesTranslationProvider({
    super.key,
    this.translations,
    required super.child,
  });

  static GreatMemoriesTranslations of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<GreatMemoriesTranslationProvider>();
    return provider?.translations ?? GreatMemoriesTranslations();
  }

  @override
  bool updateShouldNotify(covariant GreatMemoriesTranslationProvider oldWidget) {
    return oldWidget.translations != translations;
  }
}
