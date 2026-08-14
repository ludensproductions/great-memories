import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/menu_item.dart';
import 'package:great_memories_ui/src/previews.dart';

void _previewNoop() {}

@GreatMemoriesPreview(group: 'MenuItem', name: 'Default')
Widget previewMenuItemDefault() => const Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    GreatMemoriesMenuItem(onPressed: _previewNoop, icon: Icons.info_outline, label: 'Info'),
    GreatMemoriesMenuItem(onPressed: _previewNoop, icon: Icons.help_outline_rounded, label: 'Troubleshoot'),
    GreatMemoriesMenuItem(onPressed: _previewNoop, icon: Icons.cast_rounded, label: 'Cast'),
  ],
);

@GreatMemoriesPreview(group: 'MenuItem', name: 'Disabled')
Widget previewMenuItemDisabled() =>
    const GreatMemoriesMenuItem(onPressed: _previewNoop, icon: Icons.delete_outline_rounded, label: 'Delete', disabled: true);
