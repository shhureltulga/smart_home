import 'package:flutter/material.dart';

/// Дизайн токенууд (dark)
class AppTokens extends ThemeExtension<AppTokens> {
  final Color accent;        // онцлох товч, график
  final Color success;       // амжилт
  final Color warning;       // анхааруулга
  final Color surfaceCard;   // карточ фон
  final Color surfaceElev;   // бага зэрэг өргөгдсөн фон

  const AppTokens({
    required this.accent,
    required this.success,
    required this.warning,
    required this.surfaceCard,
    required this.surfaceElev,
  });

  @override
  AppTokens copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? surfaceCard,
    Color? surfaceElev,
  }) {
    return AppTokens(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElev: surfaceElev ?? this.surfaceElev,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color _l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      accent: _l(accent, other.accent),
      success: _l(success, other.success),
      warning: _l(warning, other.warning),
      surfaceCard: _l(surfaceCard, other.surfaceCard),
      surfaceElev: _l(surfaceElev, other.surfaceElev),
    );
  }
}

class AppTheme {
  static ThemeData get dark {
    // Гол өнгө (coffee/amber vibe)
    const seed = Color(0xFFDAC0A3);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        primary: const Color(0xFFE1C3A0),
        secondary: const Color(0xFFB08968),
        surface: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF1E1E1E),
        surfaceContainerHigh: const Color(0xFF191919),
      ),

      scaffoldBackgroundColor: const Color(0xFF111213),

      // Typography
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: Colors.white.withOpacity(.92),
        displayColor: Colors.white.withOpacity(.92),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),

      // M3-д cardTheme нь CardThemeData байдаг (зарим сууринд CardTheme гэдэг алдаа гарч байсан!)
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(.06),
        thickness: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
          selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
      ),

      extensions: const [
        AppTokens(
          accent: Color(0xFFE8B680),
          success: Color(0xFF7BD88F),
          warning: Color(0xFFFFC766),
          surfaceCard: Color(0xFF1E1E1E),
          surfaceElev: Color(0xFF232323),
        ),
      ],
    );
  }
}
