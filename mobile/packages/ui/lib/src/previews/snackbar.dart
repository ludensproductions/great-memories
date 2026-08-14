import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/constants.dart';
import 'package:great_memories_ui/src/previews.dart';
import 'package:great_memories_ui/src/snackbar.dart';

@GreatMemoriesPreview(group: 'Snackbar', name: 'Types')
Widget previewSnackbarTypes() => const _SnackbarDemo();

class _SnackbarDemo extends StatelessWidget {
  const _SnackbarDemo();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Wrap(
            spacing: GreatMemoriesSpacing.md,
            runSpacing: GreatMemoriesSpacing.md,
            children: [
              ElevatedButton(onPressed: () => snackbar.info('Info message'), child: const Text('Info')),
              ElevatedButton(onPressed: () => snackbar.success('Saved'), child: const Text('Success')),
              ElevatedButton(onPressed: () => snackbar.error('Something failed'), child: const Text('Error')),
            ],
          ),
        ),
      ),
    );
  }
}
