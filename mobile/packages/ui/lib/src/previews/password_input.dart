import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/components/password_input.dart';
import 'package:great_memories_ui/src/previews.dart';

@GreatMemoriesPreview(group: 'PasswordInput', name: 'With Validator')
Widget previewPasswordInput() => GreatMemoriesPasswordInput(
      label: 'Password',
      hintText: 'Enter your password',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
