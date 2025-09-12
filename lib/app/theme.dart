import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFFFE8C00),
    scaffoldBackgroundColor: const Color(0xFF1E1F22),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    inputDecorationTheme: const InputDecorationTheme(),
  );
}
