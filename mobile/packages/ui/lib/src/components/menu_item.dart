import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_memories_ui/src/constants.dart';
import 'package:great_memories_ui/src/internal.dart';

class GreatMemoriesMenu extends StatefulWidget {
  final List<Widget> children;
  final MenuAnchorChildBuilder builder;
  final MenuStyle? style;
  final bool consumeOutsideTap;
  final Widget? child;

  const GreatMemoriesMenu({
    super.key,
    required this.children,
    required this.builder,
    this.style,
    this.consumeOutsideTap = false,
    this.child,
  });

  @override
  State<GreatMemoriesMenu> createState() => _GreatMemoriesMenuState();
}

class _GreatMemoriesMenuState extends State<GreatMemoriesMenu> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return _GreatMemoriesMenuScope(
      controller: _controller,
      child: MenuAnchor(
        controller: _controller,
        style: widget.style,
        consumeOutsideTap: widget.consumeOutsideTap,
        menuChildren: widget.children,
        builder: widget.builder,
        child: widget.child,
      ),
    );
  }
}

class _GreatMemoriesMenuScope extends InheritedWidget {
  final MenuController controller;

  const _GreatMemoriesMenuScope({required this.controller, required super.child});

  static MenuController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GreatMemoriesMenuScope>()?.controller;

  @override
  bool updateShouldNotify(_GreatMemoriesMenuScope oldWidget) => controller != oldWidget.controller;
}

class GreatMemoriesMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final FutureOr<void> Function() onPressed;
  final bool disabled;

  const GreatMemoriesMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  State<GreatMemoriesMenuItem> createState() => _GreatMemoriesMenuItemState();
}

class _GreatMemoriesMenuItemState extends State<GreatMemoriesMenuItem> {
  Future<void> _onPressed(MenuController? controller) async {
    try {
      await widget.onPressed();
    } finally {
      controller?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _GreatMemoriesMenuScope.maybeOf(context);
    return MenuItemButton(
      onPressed: widget.disabled ? null : () => _onPressed(controller),
      closeOnActivate: controller == null,
      style: MenuItemButton.styleFrom(
        foregroundColor: context.colorOverride,
        alignment: .centerLeft,
        padding: const .symmetric(horizontal: GreatMemoriesSpacing.lg, vertical: GreatMemoriesSpacing.md),
      ),
      leadingIcon: Icon(widget.icon, size: GreatMemoriesIconSize.sm),
      child: Text(widget.label, style: const .new(fontSize: GreatMemoriesTextSize.body)),
    );
  }
}
