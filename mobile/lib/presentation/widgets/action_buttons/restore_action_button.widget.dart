import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/constants/enums.dart';
import 'package:great_memories_mobile/domain/models/events.model.dart';
import 'package:great_memories_mobile/domain/utils/event_stream.dart';
import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:great_memories_mobile/presentation/widgets/action_buttons/base_action_button.widget.dart';
import 'package:great_memories_mobile/providers/infrastructure/action.provider.dart';
import 'package:great_memories_mobile/providers/timeline/multiselect.provider.dart';
import 'package:great_memories_mobile/widgets/common/great_memories_toast.dart';

class RestoreActionButton extends ConsumerWidget {
  final ActionSource source;
  final bool iconOnly;
  final bool menuItem;

  const RestoreActionButton({super.key, required this.source, this.iconOnly = false, this.menuItem = false});

  void _onTap(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) {
      return;
    }

    final result = await ref.read(actionProvider.notifier).restoreTrash(source);
    ref.read(multiSelectProvider.notifier).reset();

    if (source == ActionSource.viewer) {
      EventStream.shared.emit(const ViewerReloadAssetEvent());
    }

    final successMessage = 'assets_restored_count'.t(context: context, args: {'count': result.count.toString()});

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
      iconData: Icons.history_rounded,
      label: 'restore'.t(context: context),
      iconOnly: iconOnly,
      menuItem: menuItem,
      onPressed: () => _onTap(context, ref),
      maxWidth: 100.0,
    );
  }
}
