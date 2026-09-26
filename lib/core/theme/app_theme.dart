import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Light and dark themes. Light mode uses navy for primary actions,
/// dark mode uses the brand yellow; "Buy now" style accents always use
/// the yellow (`colorScheme.secondary`).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        Brightness.light,
        ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
          primary: AppColors.navy,
          onPrimary: Colors.white,
          primaryContainer: AppColors.brandYellowSoft,
          onPrimaryContainer: AppColors.navy,
          secondary: AppColors.brandYellow,
          onSecondary: AppColors.navy,
          secondaryContainer: AppColors.brandYellowSoft,
          onSecondaryContainer: AppColors.navy,
          surface: AppColors.lightSurface,
          onSurface: const Color(0xFF111827),
          onSurfaceVariant: const Color(0xFF5B6472),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF9FAFB),
          surfaceContainer: const Color(0xFFF3F4F6),
          surfaceContainerHigh: const Color(0xFFEDEFF2),
          surfaceContainerHighest: const Color(0xFFE6E8EC),
          outline: const Color(0xFFCBD2DC),
          outlineVariant: AppColors.lightOutline,
          error: AppColors.danger,
        ),
        AppColors.lightBackground,
      );

  static ThemeData get dark => _build(
        Brightness.dark,
        ColorScheme.fromSeed(seedColor: AppColors.brandYellow, brightness: Brightness.dark).copyWith(
          primary: AppColors.brandYellow,
          onPrimary: AppColors.navy,
          primaryContainer: const Color(0xFF3A3217),
          onPrimaryContainer: AppColors.brandYellow,
          secondary: AppColors.brandYellow,
          onSecondary: AppColors.navy,
          secondaryContainer: const Color(0xFF3A3217),
          onSecondaryContainer: AppColors.brandYellow,
          surface: AppColors.darkSurface,
          onSurface: const Color(0xFFE6EDF3),
          onSurfaceVariant: const Color(0xFF9AA4B2),
          surfaceContainerLowest: AppColors.darkBackground,
          surfaceContainerLow: const Color(0xFF12171E),
          surfaceContainer: AppColors.darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF252D38),
          surfaceContainerHighest: const Color(0xFF2C3541),
          outline: const Color(0xFF3B4452),
          outlineVariant: AppColors.darkOutline,
          error: const Color(0xFFFF6B6B),
        ),
        AppColors.darkBackground,
      );

  static ThemeData _build(Brightness brightness, ColorScheme scheme, Color background) {
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final text = GoogleFonts.jostTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final isDark = brightness == Brightness.dark;
    final radius = BorderRadius.circular(14);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.brandYellow : AppColors.navy,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? const Color(0xFF3A3217) : AppColors.brandYellow,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isDark ? AppColors.brandYellow : AppColors.navy)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.navy,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.brandYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
