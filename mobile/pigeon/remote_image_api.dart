import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/remote_image_api.g.dart',
    swiftOut: 'ios/Runner/Images/RemoteImages.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: false),
    kotlinOut: 'android/app/src/main/kotlin/app/alextran/great-memories/images/RemoteImages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.greatmemories.app.images', includeErrorClass: false),
    dartOptions: DartOptions(),
    dartPackageName: 'great_memories_mobile',
  ),
)
@HostApi()
abstract class RemoteImageApi {
  @async
  Map<String, int>? requestImage(String url, {required int requestId, required bool preferEncoded});

  void cancelRequest(int requestId);

  @async
  int clearCache();
}
