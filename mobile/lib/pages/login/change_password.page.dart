import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/widgets/forms/change_password_form.dart';

@RoutePage()
class ChangePasswordPage extends HookConsumerWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: ChangePasswordForm());
  }
}
