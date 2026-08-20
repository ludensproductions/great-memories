import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/constants/enums.dart';
import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:great_memories_mobile/presentation/widgets/action_buttons/base_action_button.widget.dart';
import 'package:great_memories_mobile/providers/infrastructure/action.provider.dart';
import 'package:great_memories_mobile/providers/timeline/multiselect.provider.dart';
import 'package:great_memories_mobile/widgets/common/great_memories_toast.dart';

class SetAlbumCoverActionButton extends ConsumerWidget {
  final String albumId;
  final ActionSource source;
  final bool iconOnly;
  final bool menuItem;

  const SetAlbumCoverActionButton({
    super.key,
    required this.albumId,
    required this.source,
    this.iconOnly = false,
    this.menuItem = false,
  });

  void _onTap(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) {
      return;
    }

    final result = await ref.read(actionProvider.notifier).setAlbumCover(source, albumId);
    ref.read(multiSelectProvider.notifier).reset();

    final successMessage = 'album_cover_updated'.t(context: context);

    if (context.mounted) {
      GreatMemoriesToast.show(
        context: context,
        msg: result.success ? successMessage : 'scaffold_body_error_occurred'.t(context: context),
        gravity: ToastGravity.BOTTOM,
        toastType: result.success ? ToastType.success : ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseActionButton(
      iconData: Icons.image_outlined,
      label: 'set_as_album_cover'.t(context: context),
      iconOnly: iconOnly,
      menuItem: menuItem,
      onPressed: () => _onTap(context, ref),
      maxWidth: 100,
    );
  }
}
