import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/constants.dart';
import 'package:great_memories_ui/src/internal.dart';

class GreatMemoriesColumnButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final FutureOr<void> Function() onPressed;
  final bool disabled;
  final bool? loading;

  const GreatMemoriesColumnButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.disabled = false,
    this.loading,
  });

  @override
  State<GreatMemoriesColumnButton> createState() => _GreatMemoriesColumnButtonState();
}

class _GreatMemoriesColumnButtonState extends State<GreatMemoriesColumnButton> {
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
    final foreground = context.colorOverride ?? Theme.of(context).colorScheme.onSurface;

    return TextButton(
      onPressed: widget.disabled || _isLoading ? null : _onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        padding: const .symmetric(horizontal: GreatMemoriesSpacing.sm, vertical: GreatMemoriesSpacing.md),
        tapTargetSize: .shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: .all(.circular(GreatMemoriesRadius.xl))),
      ),
      child: ConstrainedBox(
        constraints: const .new(maxWidth: 90),
        child: Column(
          mainAxisSize: .min,
          children: [
            _isLoading
                ? const SizedBox.square(
                    dimension: GreatMemoriesIconSize.md,
                    child: CircularProgressIndicator(strokeWidth: GreatMemoriesBorderWidth.lg),
                  )
                : Icon(widget.icon, size: GreatMemoriesIconSize.md),
            const SizedBox(height: GreatMemoriesSpacing.sm),
            Text(
              widget.label,
              maxLines: 2,
              textAlign: .center,
              overflow: .ellipsis,
              style: const .new(fontSize: GreatMemoriesTextSize.label, fontWeight: .w500),
            ),
          ],
        ),
      ),
    );
  }
}
