import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for the entire application.
/// Every color, spacing value, radius, shadow, and text style
/// originates from this single file so the design stays cohesive.
class AppTheme {
  AppTheme._();

  // ─── Brand Palette (shared across light & dark) ──────────────────
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color whatsapp = Color(0xFF25D366);

  // ─── Light Palette ───────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color primarySurface = Color(0xFFE8F5E9);
  static const Color accentSurface = Color(0xFFFFF8E1);

  // ─── Dark Palette ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextHint = Color(0xFF666666);
  static const Color darkDivider = Color(0xFF333333);
  static const Color darkPrimarySurface = Color(0xFF1B3D1C);
  static const Color darkAccentSurface = Color(0xFF3D3520);

  // ─── Spacing Scale (multiples of 4) ─────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ─── Border Radius ─────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;

  // ─── Elevation / Shadows ───────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Dark mode uses subtler/no shadows
  static List<BoxShadow> get darkShadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> get darkShadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── ThemeData — Light ─────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primarySurface,
        secondary: accent,
        secondaryContainer: accentSurface,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        outline: divider,
      ),
      textTheme: _buildTextTheme(base, textPrimary, textSecondary, textHint),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: GoogleFonts.cairo(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(background, divider, textHint),
      bottomNavigationBarTheme: _bottomNavTheme(surface, textHint),
      chipTheme: _chipTheme(background, divider),
      dividerTheme: const DividerThemeData(color: divider, space: 1, thickness: 1),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ─── ThemeData — Dark ──────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: darkPrimarySurface,
        secondary: accent,
        secondaryContainer: darkAccentSurface,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        error: error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkTextPrimary,
        onError: Colors.white,
        outline: darkDivider,
      ),
      textTheme: _buildTextTheme(base, darkTextPrimary, darkTextSecondary, darkTextHint),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 22),
        titleTextStyle: GoogleFonts.cairo(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(darkSurfaceVariant, darkDivider, darkTextHint),
      bottomNavigationBarTheme: _bottomNavTheme(darkSurface, darkTextHint),
      chipTheme: _chipTheme(darkSurfaceVariant, darkDivider),
      dividerTheme: const DividerThemeData(color: darkDivider, space: 1, thickness: 1),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ─── Shared builders ───────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base, Color mainColor, Color secondaryColor, Color hintColor) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: mainColor, height: 1.3),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: mainColor, height: 1.3),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: mainColor, height: 1.4),
      titleLarge: base.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: mainColor),
      titleMedium: base.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: mainColor),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: mainColor, height: 1.6),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryColor, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: hintColor),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );

  static OutlinedButtonThemeData get _outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: const BorderSide(color: primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme(Color fill, Color border, Color hint) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: primary, width: 1.5)),
    hintStyle: GoogleFonts.cairo(color: hint, fontSize: 14),
  );

  static BottomNavigationBarThemeData _bottomNavTheme(Color bg, Color unselected) => BottomNavigationBarThemeData(
    backgroundColor: bg,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: primary,
    unselectedItemColor: unselected,
    selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11),
    unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 11),
    showUnselectedLabels: true,
  );

  static ChipThemeData _chipTheme(Color bg, Color border) => ChipThemeData(
    backgroundColor: bg,
    selectedColor: primarySurface,
    labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
    side: BorderSide(color: border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );
}

// ─── Context Extension for theme-aware colors ─────────────────────
/// Use `context.colors` to access theme-aware colors anywhere in widgets.
extension AppColorsExtension on BuildContext {
  _AppColors get colors => _AppColors(Theme.of(this).brightness == Brightness.dark);
}

class _AppColors {
  final bool isDark;
  const _AppColors(this.isDark);
  
  // Brand
  Color get primary => isDark ? AppTheme.primaryLight : AppTheme.primary;
  Color get primaryLight => isDark ? AppTheme.primaryLight : AppTheme.primaryLight;
  Color get primaryDark => isDark ? AppTheme.primaryDark : AppTheme.primaryDark;
  Color get error => AppTheme.error;

  // Surfaces
  Color get background => isDark ? AppTheme.darkBackground : AppTheme.background;
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.surface;
  Color get surfaceVariant => isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant;

  // Text
  Color get textPrimary => isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get textSecondary => isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get textHint => isDark ? AppTheme.darkTextHint : AppTheme.textHint;

  // Divider
  Color get divider => isDark ? AppTheme.darkDivider : AppTheme.divider;

  // Tinted surfaces
  Color get primarySurface => isDark ? AppTheme.darkPrimarySurface : AppTheme.primarySurface;
  Color get accentSurface => isDark ? AppTheme.darkAccentSurface : AppTheme.accentSurface;

  // Shadows
  List<BoxShadow> get shadowSm => isDark ? AppTheme.darkShadowSm : AppTheme.shadowSm;
  List<BoxShadow> get shadowMd => isDark ? AppTheme.darkShadowMd : AppTheme.shadowMd;

  // Shimmer
  Color get shimmerBase => isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!;
  Color get shimmerHighlight => isDark ? const Color(0xFF3A3A3A) : Colors.grey[50]!;

  // Overlays
  Color get overlayLight => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
  Color get overlayMedium => isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

  // Card / Badge backgrounds
  Color get badgeBg => isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.92);
  Color get iconBgSubtle => isDark ? AppTheme.darkSurfaceVariant : const Color(0xFFF5F5F5);
}
