import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_memories_ui/great_memories_ui.dart';

class GreatMemoriesTextButton extends StatefulWidget {
  final String labelText;
  final IconData? icon;
  final FutureOr<void> Function() onPressed;
  final GreatMemoriesVariant variant;
  final bool expanded;
  final bool disabled;
  final bool? loading;

  const GreatMemoriesTextButton({
    super.key,
    required this.labelText,
    this.icon,
    required this.onPressed,
    this.variant = .filled,
    this.expanded = true,

    this.disabled = false,
    this.loading,
  });

  @override
  State<GreatMemoriesTextButton> createState() => _GreatMemoriesTextButtonState();
}

class _GreatMemoriesTextButtonState extends State<GreatMemoriesTextButton> {
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
    final Widget? icon = _isLoading
        ? const SizedBox.square(
            dimension: GreatMemoriesIconSize.md,
            child: CircularProgressIndicator(strokeWidth: GreatMemoriesBorderWidth.lg),
          )
        : widget.icon != null
        ? Icon(widget.icon, fontWeight: .w600)
        : null;

    final label = Text(
      widget.labelText,
      style: const .new(fontSize: GreatMemoriesTextSize.body, fontWeight: .bold),
    );
    final style = ElevatedButton.styleFrom(padding: const .symmetric(vertical: GreatMemoriesSpacing.md));
    final onPressed = widget.disabled || _isLoading ? null : _onPressed;

    final button = switch (widget.variant) {
      GreatMemoriesVariant.filled => ElevatedButton.icon(style: style, onPressed: onPressed, icon: icon, label: label),
      GreatMemoriesVariant.ghost => TextButton.icon(style: style, onPressed: onPressed, icon: icon, label: label),
    };

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
