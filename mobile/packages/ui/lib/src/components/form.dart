import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_memories_ui/great_memories_ui.dart';
import 'package:great_memories_ui/src/internal.dart';

class GreatMemoriesFormController extends ChangeNotifier {
  GreatMemoriesFormController({this.onSubmit});

  FutureOr<void> Function()? onSubmit;
  final formKey = GlobalKey<FormState>();

  bool _isDisposed = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> submit() async {
    if (_isLoading) {
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await onSubmit?.call();
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
}

class GreatMemoriesForm extends StatefulWidget {
  final FutureOr<void> Function()? onSubmit;
  final Widget Function(BuildContext context, GreatMemoriesFormController form) builder;
  final String? submitText;
  final IconData? submitIcon;

  const GreatMemoriesForm({super.key, this.onSubmit, this.submitText, this.submitIcon, required this.builder});

  @override
  State<GreatMemoriesForm> createState() => _GreatMemoriesFormState();
}

class _GreatMemoriesFormState extends State<GreatMemoriesForm> {
  late final GreatMemoriesFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GreatMemoriesFormController(onSubmit: widget.onSubmit);
  }

  @override
  void didUpdateWidget(GreatMemoriesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.onSubmit = widget.onSubmit;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitText = widget.submitText ?? context.translations.submit;
    return Form(
      key: _controller.formKey,
      child: Column(
        spacing: GreatMemoriesSpacing.md,
        children: [
          widget.builder(context, _controller),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => GreatMemoriesTextButton(
              labelText: submitText,
              icon: widget.submitIcon,
              variant: .filled,
              loading: _controller.isLoading,
              onPressed: _controller.submit,
              disabled: _controller.onSubmit == null,
            ),
          ),
        ],
      ),
    );
  }
}
