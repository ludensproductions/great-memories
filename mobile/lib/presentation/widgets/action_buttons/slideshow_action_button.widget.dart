import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:great_memories_mobile/presentation/widgets/action_buttons/base_action_button.widget.dart';
import 'package:great_memories_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:great_memories_mobile/routing/router.dart';

class SlideshowActionButton extends ConsumerWidget {
  final bool iconOnly;
  final bool menuItem;

  const SlideshowActionButton({super.key, this.iconOnly = false, this.menuItem = false});

  void _onTap(BuildContext context, WidgetRef ref) {
    if (!context.mounted) {
      return;
    }

    context.pushRoute(DriftSlideshowRoute(timeline: ref.read(timelineServiceProvider)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseActionButton(
      iconData: Icons.slideshow,
      label: "slideshow".t(context: context),
      iconOnly: iconOnly,
      menuItem: menuItem,
      onPressed: () => _onTap(context, ref),
      maxWidth: 100,
    );
  }
}
