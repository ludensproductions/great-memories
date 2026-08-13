import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/icon_button.dart';
import 'package:immich_ui/src/types.dart';

class GreatMemoriesCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final GreatMemoriesVariant variant;
  final GreatMemoriesColor color;

  const GreatMemoriesCloseButton({
    super.key,
    this.onPressed,
    this.color = GreatMemoriesColor.primary,
    this.variant = GreatMemoriesVariant.ghost,
  });

  @override
  Widget build(BuildContext context) => GreatMemoriesIconButton(
    icon: Icons.close,
    color: color,
    variant: variant,
    onPressed: onPressed ?? () => Navigator.of(context).pop(),
  );
}
