import 'package:flutter/widgets.dart';
import 'package:great_memories_mobile/utils/cache/custom_image_cache.dart';

final class GreatMemoriesWidgetsBinding extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => CustomImageCache();
}
