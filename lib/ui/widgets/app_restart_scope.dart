import 'package:flutter/material.dart';

class AppRestartScope extends StatefulWidget {
  const AppRestartScope({required this.child, super.key});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartScopeState>()?.restartApp();
  }

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _subtreeKey = UniqueKey();

  void restartApp() {
    setState(() => _subtreeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _subtreeKey, child: widget.child);
  }
}
