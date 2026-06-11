import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 2050 design tokens. All visuals in the app reference these so
/// themes can be re-skinned by changing one file.
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────
  static const Color brand = Color(0xFFDC2626);
  static const Color brandDark = Color(0xFF991B1B);
  static const Color brandDarker = Color(0xFF7F1D1D);
  static const Color brandLight = Color(0xFFFEE2E2);
  static const Color brandSoft = Color(0xFFFEF2F2);
  static const Color brandGlow = Color(0xFFFF6B6B);

  // ── Accent (slate / graphite) ───────────────────────────────────────
  static const Color accent = Color(0xFF0F172A);
  static const Color accentSoft = Color(0xFF1E293B);
  static const Color accentMuted = Color(0xFF334155);

  // ── Surfaces (light) ───────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFAFAFB);
  static const Color background = Color(0xFFF7F7F9);
  static const Color overlay = Color(0xFF0F172A);

  // ── Surfaces (dark) ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111114);
  static const Color darkSurfaceMuted = Color(0xFF1C1C1F);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkOverlay = Color(0xFF000000);

  // ── Text (light) ────────────────────────────────────────────────────
  static const Color text = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF475569);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Text (dark) ─────────────────────────────────────────────────────
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextBody = Color(0xFFEBEBF0);
  static const Color darkTextMuted = Color(0xFF98989D);
  static const Color darkTextSubtle = Color(0xFF636366);

  // ── Borders / hairlines ────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFF1F5F9);

  // dark borders — iOS style, very subtle
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkBorderStrong = Color(0xFF3A3A3C);
  static const Color darkDivider = Color(0xFF1C1C1F);

  // ── Semantic ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldSoft = Color(0xFFFEF3C7);

  // Dark variants
  static const Color darkSuccess = Color(0xFF30D158);
  static const Color darkSuccessSoft = Color(0xFF0F2A1B);
  static const Color darkWarning = Color(0xFFFFD60A);
  static const Color darkWarningSoft = Color(0xFF2C2104);
  static const Color darkInfo = Color(0xFF0A84FF);
  static const Color darkInfoSoft = Color(0xFF0A1F3D);
  static const Color darkDanger = Color(0xFFFF453A);
  static const Color darkDangerSoft = Color(0xFF2C0A0A);

  // Apple Intelligence signature gradient — pink → purple → indigo
  static const Gradient appleIntelligenceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFD79A8),
      Color(0xFFA29BFE),
      Color(0xFF6C5CE7),
      Color(0xFF0984E3),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );

  // ── Gradients ──────────────────────────────────────────────────────
  static const Gradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
    stops: [0.0, 0.6, 1.0],
  );
  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFF7F1D1D), Color(0xFF450A0A)],
  );
  static const Gradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
  );
  static const Gradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
  );
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF059669)],
  );
  static const Gradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF2563EB)],
  );
  static const Gradient meshHero = RadialGradient(
    center: Alignment(-0.3, -0.5),
    radius: 1.4,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFDC2626),
      Color(0xFF7F1D1D),
      Color(0xFF1F0A0A),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );
}

/// Spacing scale. Use these everywhere instead of raw numbers.
class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double xxxxl = 32;
  static const double huge = 48;
  static const double jumbo = 64;
}

/// Border radius scale.
class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

/// Elevation. Subtle, modern shadows. Tinted toward brand in dark mode.
class AppElevation {
  static List<BoxShadow> get xs => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];
}

/// Build context extensions that return theme-aware colours so individual
/// screens can flip between light and dark without hard-coding.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surfaces
  Color get bgColor =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor =>
      isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfaceMutedColor =>
      isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
  Color get surfaceElevatedColor =>
      isDark ? AppColors.darkSurfaceElevated : AppColors.surface;

  // Text
  Color get textColor => isDark ? AppColors.darkText : AppColors.text;
  Color get textBodyColor =>
      isDark ? AppColors.darkTextBody : AppColors.textBody;
  Color get textMutedColor =>
      isDark ? AppColors.darkTextMuted : AppColors.textMuted;
  Color get textSubtleColor =>
      isDark ? AppColors.darkTextSubtle : AppColors.textSubtle;

  // Borders
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;
  Color get borderStrongColor =>
      isDark ? AppColors.darkBorderStrong : AppColors.borderStrong;
  Color get dividerColor =>
      isDark ? AppColors.darkDivider : AppColors.divider;

  // Semantic
  Color get successColor =>
      isDark ? AppColors.darkSuccess : AppColors.success;
  Color get successSoftColor =>
      isDark ? AppColors.darkSuccessSoft : AppColors.successSoft;
  Color get warningColor =>
      isDark ? AppColors.darkWarning : AppColors.warning;
  Color get warningSoftColor =>
      isDark ? AppColors.darkWarningSoft : AppColors.warningSoft;
  Color get infoColor => isDark ? AppColors.darkInfo : AppColors.info;
  Color get infoSoftColor =>
      isDark ? AppColors.darkInfoSoft : AppColors.infoSoft;
  Color get dangerColor =>
      isDark ? AppColors.darkDanger : AppColors.danger;
  Color get dangerSoftColor =>
      isDark ? AppColors.darkDangerSoft : AppColors.dangerSoft;

  /// iOS elevation that adapts to dark mode.
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ]
      : AppElevation.sm;
}

/// App-wide theme. Material 3 with Inter typography and a refined
/// AirPak colour palette. Supports both light and dark mode.
class AppTheme {
  static const String _family = 'Inter';

  static TextTheme _textTheme(Color text, Color textMuted, Color textBody) {
    final inter = GoogleFonts.interTextTheme();
    return inter.copyWith(
      displayLarge: inter.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
        color: text,
      ),
      displayMedium: inter.displayMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: text,
      ),
      displaySmall: inter.displaySmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.4,
        color: text,
      ),
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: text,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: text,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: textBody,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: textBody,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.45,
        color: textMuted,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }

  static ThemeData light() {
    final textTheme =
        _textTheme(AppColors.text, AppColors.textMuted, AppColors.textBody);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: textTheme.labelMedium,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.brand,
        thumbColor: AppColors.brand,
        overlayColor: Color(0x20DC2626),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _textTheme(
      AppColors.darkText,
      AppColors.darkTextMuted,
      AppColors.darkTextBody,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _family,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        secondary: AppColors.darkInfo,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.darkDanger,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.darkTextMuted),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.darkTextSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.darkDanger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        labelStyle: textTheme.labelMedium,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.brand,
        thumbColor: AppColors.brand,
        overlayColor: Color(0x20DC2626),
      ),
    );
  }
}
