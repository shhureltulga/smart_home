import 'package:flutter/material.dart';

class RootScaffold extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const RootScaffold({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static ScaffoldState? stateOf(BuildContext context) {
    final holder = context.dependOnInheritedWidgetOfExactType<RootScaffold>();
    return holder?.scaffoldKey.currentState;
  }

  static void openDrawer(BuildContext context) {
    stateOf(context)?.openDrawer();
  }

  @override
  bool updateShouldNotify(RootScaffold oldWidget) =>
      scaffoldKey != oldWidget.scaffoldKey;
}
