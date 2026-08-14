import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/icon_button.dart';
import 'package:great_memories_ui/src/previews.dart';
import 'package:great_memories_ui/src/types.dart';

void _previewNoop() {}

@GreatMemoriesPreview(group: 'IconButton', name: 'Variants')
Widget previewIconButtonVariants() => const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GreatMemoriesIconButton(icon: Icons.add, onPressed: _previewNoop),
        GreatMemoriesIconButton(icon: Icons.edit, onPressed: _previewNoop, variant: GreatMemoriesVariant.ghost),
      ],
    );

@GreatMemoriesPreview(group: 'IconButton', name: 'Colors')
Widget previewIconButtonColors() => const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GreatMemoriesIconButton(icon: Icons.favorite, onPressed: _previewNoop),
        GreatMemoriesIconButton(icon: Icons.delete, onPressed: _previewNoop, color: GreatMemoriesColor.secondary),
      ],
    );

@GreatMemoriesPreview(group: 'IconButton', name: 'Disabled')
Widget previewIconButtonDisabled() => const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GreatMemoriesIconButton(icon: Icons.settings, onPressed: _previewNoop, disabled: true),
        GreatMemoriesIconButton(
          icon: Icons.settings,
          onPressed: _previewNoop,
          disabled: true,
          variant: GreatMemoriesVariant.ghost,
        ),
      ],
    );
