import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/text_input.dart';
import 'package:immich_ui/src/internal.dart';

class GreatMemoriesPasswordInput extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String value)? onSubmit;
  final TextInputAction? keyboardAction;

  const GreatMemoriesPasswordInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.validator,
    this.onSubmit,
    this.keyboardAction,
  });

  @override
  State createState() => _GreatMemoriesPasswordInputState();
}

class _GreatMemoriesPasswordInputState extends State<GreatMemoriesPasswordInput> {
  bool _visible = false;

  void _toggleVisibility() {
    setState(() {
      _visible = !_visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GreatMemoriesTextInput(
      key: widget.key,
      label: widget.label ?? context.translations.password,
      hintText: widget.hintText,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onSubmit: widget.onSubmit,
      keyboardAction: widget.keyboardAction,
      obscureText: !_visible,
      suffixIcon: IconButton(
        onPressed: _toggleVisibility,
        icon: Icon(_visible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
      ),
      autofillHints: [AutofillHints.password],
    );
  }
}
