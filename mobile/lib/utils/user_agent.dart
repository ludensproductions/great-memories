import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

Future<String> getGreatMemoriesUserAgentString() async {
  final packageInfo = await PackageInfo.fromPlatform();
  String platform;
  if (Platform.isAndroid) {
    platform = 'android';
  } else if (Platform.isIOS) {
    platform = 'ios';
  } else {
    platform = 'unknown';
  }
  return 'great-memories-$platform/${packageInfo.version}';
}

Future<String> getUserAgentString() => getGreatMemoriesUserAgentString();