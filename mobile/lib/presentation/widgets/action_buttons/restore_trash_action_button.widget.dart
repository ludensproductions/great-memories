import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/constants/enums.dart';
import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:great_memories_mobile/providers/infrastructure/action.provider.dart';
import 'package:great_memories_mobile/providers/timeline/multiselect.provider.dart';
import 'package:great_memories_mobile/widgets/common/great_memories_toast.dart';

class RestoreTrashActionButton extends ConsumerWidget {
  final ActionSource source;

  const RestoreTrashActionButton({super.key, required this.source});

  void _onTap(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) {
      return;
    }

    final result = await ref.read(actionProvider.notifier).restoreTrash(source);
    ref.read(multiSelectProvider.notifier).reset();

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
    return TextButton.icon(
      icon: const Icon(Icons.history_rounded),
      label: Text('restore'.t(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      onPressed: () => _onTap(context, ref),
    );
  }
}
