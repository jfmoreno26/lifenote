import 'package:flutter/material.dart';

/// LifeNote design tokens, available via `context.ln`.
@immutable
class LnColors extends ThemeExtension<LnColors> {
  const LnColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.water,
    required this.waterSoft,
    required this.success,
    required this.danger,
    required this.notes,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primarySoft;
  final Color water;
  final Color waterSoft;
  final Color success;
  final Color danger;

  /// Note card backgrounds, indexed by `Note.color`.
  final List<Color> notes;

  static const light = LnColors(
    bg: Color(0xFFF4F5F9),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF0F1F6),
    border: Color(0xFFE6E8EF),
    text: Color(0xFF1B1D29),
    muted: Color(0xFF8A8FA3),
    primary: Color(0xFF4E5BF2),
    primarySoft: Color(0xFFE8EAFE),
    water: Color(0xFF2E9CEA),
    waterSoft: Color(0xFFDDEFFC),
    success: Color(0xFF22A06B),
    danger: Color(0xFFE5484D),
    notes: [
      Color(0xFFFFF4B8), // yellow
      Color(0xFFDCEAFE), // blue
      Color(0xFFE7E3FF), // lavender
      Color(0xFFDDF3DF), // green
      Color(0xFFFFE3C7), // peach
      Color(0xFFFFE1EA), // pink
    ],
  );

  static const dark = LnColors(
    bg: Color(0xFF0F1117),
    surface: Color(0xFF181B24),
    surfaceAlt: Color(0xFF222633),
    border: Color(0xFF2A2F3D),
    text: Color(0xFFECEEF5),
    muted: Color(0xFF8C92A6),
    primary: Color(0xFF6B76FF),
    primarySoft: Color(0xFF262B52),
    water: Color(0xFF3AA8F2),
    waterSoft: Color(0xFF1B3247),
    success: Color(0xFF34C084),
    danger: Color(0xFFF06A6E),
    notes: [
      Color(0xFF3A3520),
      Color(0xFF1E2B40),
      Color(0xFF2B2742),
      Color(0xFF1E3326),
      Color(0xFF3D2D1F),
      Color(0xFF3D2230),
    ],
  );

  Color note(int index) => notes[index.clamp(0, notes.length - 1)];

  @override
  LnColors copyWith() => this;

  @override
  LnColors lerp(ThemeExtension<LnColors>? other, double t) =>
      other is LnColors && t >= 0.5 ? other : this;
}

extension LnContext on BuildContext {
  LnColors get ln => Theme.of(this).extension<LnColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light, LnColors.light);
  static ThemeData dark() => _build(Brightness.dark, LnColors.dark);

  static ThemeData _build(Brightness brightness, LnColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      surface: c.surface,
      error: c.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
    );
    final radius = BorderRadius.circular(14);

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      textTheme: base.textTheme
          .apply(bodyColor: c.text, displayColor: c.text),
      extensions: [c],
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c.border)),
        focusedBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          backgroundColor: c.surface,
          minimumSize: const Size(64, 50),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.muted, textColor: c.text),
    );
  }
}
