import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/connectivity_api.g.dart',
    swiftOut: 'ios/Runner/Connectivity/Connectivity.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: false),
    kotlinOut: 'android/app/src/main/kotlin/app/alextran/great-memories/connectivity/Connectivity.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.greatmemories.app.connectivity'),
    dartOptions: DartOptions(),
    dartPackageName: 'great_memories_mobile',
  ),
)
enum NetworkCapability { cellular, wifi, vpn, unmetered }

@HostApi()
abstract class ConnectivityApi {
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<NetworkCapability> getCapabilities();
}
