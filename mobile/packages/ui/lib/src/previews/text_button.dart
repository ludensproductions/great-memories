import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/text_button.dart';
import 'package:great_memories_ui/src/previews.dart';
import 'package:great_memories_ui/src/types.dart';

void _previewNoop() {}

@GreatMemoriesPreview(group: 'TextButton', name: 'Variants')
Widget previewTextButtonVariants() => const Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    GreatMemoriesTextButton(onPressed: _previewNoop, labelText: 'Filled', expanded: false),
    GreatMemoriesTextButton(onPressed: _previewNoop, labelText: 'Ghost', variant: GreatMemoriesVariant.ghost, expanded: false),
  ],
);

@GreatMemoriesPreview(group: 'TextButton', name: 'With Icons')
Widget previewTextButtonWithIcons() => const Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    GreatMemoriesTextButton(onPressed: _previewNoop, labelText: 'With Icon', icon: Icons.add, expanded: false),
    GreatMemoriesTextButton(
      onPressed: _previewNoop,
      labelText: 'Download',
      icon: Icons.download,
      variant: GreatMemoriesVariant.ghost,
      expanded: false,
    ),
  ],
);

@GreatMemoriesPreview(group: 'TextButton', name: 'Loading')
Widget previewTextButtonLoading() => GreatMemoriesTextButton(
  onPressed: () => Future<void>.delayed(const Duration(seconds: 2)),
  labelText: 'Click me',
  expanded: false,
);

@GreatMemoriesPreview(group: 'TextButton', name: 'Disabled')
Widget previewTextButtonDisabled() => const Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    GreatMemoriesTextButton(onPressed: _previewNoop, labelText: 'Disabled', disabled: true, expanded: false),
    GreatMemoriesTextButton(
      onPressed: _previewNoop,
      labelText: 'Disabled Ghost',
      variant: GreatMemoriesVariant.ghost,
      disabled: true,
      expanded: false,
    ),
  ],
);
