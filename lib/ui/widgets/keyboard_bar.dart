import 'package:flutter/material.dart';

/// Keeps bottom actions above the keyboard and system navigation area.
class KeyboardBar extends StatelessWidget {
  const KeyboardBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(top: false, child: child),
  );
}
