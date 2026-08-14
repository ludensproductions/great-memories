import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_memories_ui/great_memories_ui.dart';
import 'package:great_memories_ui/src/internal.dart';

class GreatMemoriesIconButton extends StatefulWidget {
  final IconData icon;
  final FutureOr<void> Function() onPressed;
  final GreatMemoriesVariant variant;
  final GreatMemoriesColor color;
  final bool disabled;
  final bool? loading;

  const GreatMemoriesIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = .primary,
    this.variant = .filled,
    this.disabled = false,
    this.loading,
  });

  @override
  State<GreatMemoriesIconButton> createState() => _GreatMemoriesIconButtonState();
}

class _GreatMemoriesIconButtonState extends State<GreatMemoriesIconButton> {
  bool _loading = false;
  bool get _isLoading => widget.loading ?? _loading;

  Future<void> _onPressed() async {
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = switch (widget.variant) {
      .filled => switch (widget.color) {
        .primary => colorScheme.primary,
        .secondary => colorScheme.secondary,
      },
      .ghost => Colors.transparent,
    };

    final foreground =
        context.colorOverride ??
        switch (widget.variant) {
          .filled => switch (widget.color) {
            .primary => colorScheme.onPrimary,
            .secondary => colorScheme.onSecondary,
          },
          .ghost => switch (widget.color) {
            .primary => colorScheme.primary,
            .secondary => colorScheme.secondary,
          },
        };

    return IconButton(
      icon: _isLoading
          ? const SizedBox.square(
              dimension: GreatMemoriesIconSize.sm,
              child: CircularProgressIndicator(strokeWidth: GreatMemoriesBorderWidth.md),
            )
          : Icon(widget.icon),
      onPressed: widget.disabled || _isLoading ? null : _onPressed,
      style: IconButton.styleFrom(backgroundColor: background, foregroundColor: foreground),
    );
  }
}
