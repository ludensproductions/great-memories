import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/close_button.dart';
import 'package:immich_ui/src/previews.dart';
import 'package:immich_ui/src/types.dart';

void _previewNoop() {}

@GreatMemoriesPreview(group: 'CloseButton', name: 'Variants')
Widget previewCloseButtonVariants() => const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GreatMemoriesCloseButton(onPressed: _previewNoop),
        GreatMemoriesCloseButton(onPressed: _previewNoop, variant: GreatMemoriesVariant.filled),
      ],
    );

@GreatMemoriesPreview(group: 'CloseButton', name: 'Colors')
Widget previewCloseButtonColors() => const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GreatMemoriesCloseButton(onPressed: _previewNoop),
        GreatMemoriesCloseButton(onPressed: _previewNoop, color: GreatMemoriesColor.secondary),
      ],
    );
