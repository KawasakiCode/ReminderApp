import 'package:flutter/material.dart';

/// One-UI-flavored Material 3 theme: airy surfaces, big rounded corners,
/// a single calm blue accent, near-black dark mode.
abstract final class AppTheme {
  static const Color seed = Color(0xFF2E6FF2);

  /// Samsung-Calendar-style weekend tints for day numbers.
  static const Color sundayRed = Color(0xFFE54D4D);
  static const Color saturdayBlue = Color(0xFF4D7DE5);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F5F9),
      cardColor: Colors.white,
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0C0D10),
      cardColor: const Color(0xFF17181D),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    // Note: no InkSparkle splashFactory — its fragment shader renders as
    // pixelated artifacts on some Mali/PowerVR GPUs (seen on Galaxy A32).
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: const CircleBorder(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        showDragHandle: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.surface),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 0.7,
      ),
    );
  }
}
