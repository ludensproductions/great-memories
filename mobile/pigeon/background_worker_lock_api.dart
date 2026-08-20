import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/background_worker_lock_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/app/alextran/great-memories/background/BackgroundWorkerLock.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.greatmemories.app.background', includeErrorClass: false),
    dartOptions: DartOptions(),
    dartPackageName: 'great_memories_mobile',
  ),
)
@HostApi()
abstract class BackgroundWorkerLockApi {
  void lock();

  void unlock();
}
