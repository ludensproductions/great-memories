import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';

class GreatMemoriesTitleText extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const GreatMemoriesTitleText({super.key, this.fontSize = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Great Memories',
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? context.primaryColor,
        letterSpacing: -0.8,
      ),
    );
  }
}