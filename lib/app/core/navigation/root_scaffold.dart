import 'package:flutter/material.dart';

/// Үндсэн Scaffold (Drawer-той)-ийн key-г глобалаар барина.
class RootScaffold {
  static GlobalKey<ScaffoldState>? key;

  static void openDrawer() {
    key?.currentState?.openDrawer();
  }

  static void closeDrawer() {
    key?.currentState?.closeDrawer();
  }
}
