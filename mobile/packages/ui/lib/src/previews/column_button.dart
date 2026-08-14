import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/column_button.dart';
import 'package:great_memories_ui/src/previews.dart';

void _previewNoop() {}

@GreatMemoriesPreview(group: 'ColumnButton', name: 'Default')
Widget previewColumnButtonDefault() => const Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    GreatMemoriesColumnButton(onPressed: _previewNoop, icon: Icons.favorite_border_rounded, label: 'Favorite'),
    GreatMemoriesColumnButton(onPressed: _previewNoop, icon: Icons.archive_outlined, label: 'Archive'),
    GreatMemoriesColumnButton(onPressed: _previewNoop, icon: Icons.delete_outline_rounded, label: 'Delete'),
  ],
);

@GreatMemoriesPreview(group: 'ColumnButton', name: 'Loading')
Widget previewColumnButtonLoading() => GreatMemoriesColumnButton(
  onPressed: () => Future<void>.delayed(const .new(seconds: 2)),
  icon: Icons.download,
  label: 'Download',
);

@GreatMemoriesPreview(group: 'ColumnButton', name: 'Disabled')
Widget previewColumnButtonDisabled() =>
    const GreatMemoriesColumnButton(onPressed: _previewNoop, icon: Icons.ios_share_rounded, label: 'Share', disabled: true);
