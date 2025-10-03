import 'package:flutter/material.dart';
import 'package:smart_home/app/core/navigation/root_scaffold.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? floating;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floating,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),           // <<< жинхэнэ menu icon
          onPressed: RootScaffold.openDrawer,     // <<< root Drawer-н нээх
        ),
        title: Text(title),
        actions: actions,
      ),
      body: child,
    );
  }
}
