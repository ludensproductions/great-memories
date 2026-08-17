import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/url_input.dart';
import 'package:great_memories_ui/src/previews.dart';

@GreatMemoriesPreview(group: 'URLInput', name: 'Basic')
Widget previewUrlInput() => const _PreviewUrlInput();

class _PreviewUrlInput extends StatefulWidget {
  const _PreviewUrlInput();

  @override
  State<_PreviewUrlInput> createState() => _PreviewUrlInputState();
}

class _PreviewUrlInputState extends State<_PreviewUrlInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GreatMemoriesURLInput(label: 'Server URL', hintText: 'https://demo.great-memories.com', controller: _controller);
  }
}
