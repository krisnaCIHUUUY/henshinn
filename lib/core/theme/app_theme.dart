import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class AppTheme {
  AppTheme._();

  // ── Elevation Shadows ────────────────────────────────────
  static const List<BoxShadow> elevation0 = [];
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 10)),
  ];

  // ── Light Theme ──────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.primaryContainer,
      primary: AppColor.primary,
      onPrimary: AppColor.onPrimary,
      primaryContainer: AppColor.primaryContainer,
      onPrimaryContainer: AppColor.onPrimaryContainer,
      secondary: AppColor.secondary,
      onSecondary: AppColor.onSecondary,
      secondaryContainer: AppColor.secondaryContainer,
      onSecondaryContainer: AppColor.onSecondaryContainer,
      tertiary: AppColor.tertiary,
      onTertiary: AppColor.onTertiary,
      tertiaryContainer: AppColor.tertiaryContainer,
      onTertiaryContainer: AppColor.onTertiaryContainer,
      error: AppColor.error,
      onError: AppColor.onError,
      errorContainer: AppColor.errorContainer,
      onErrorContainer: AppColor.onErrorContainer,
      surface: AppColor.surface,
      onSurface: AppColor.onSurface,
      onSurfaceVariant: AppColor.onSurfaceVariant,
      outline: AppColor.outline,
      outlineVariant: AppColor.outlineVariant,
      inverseSurface: AppColor.inverseSurface,
      onInverseSurface: AppColor.inverseOnSurface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColor.background,

      // ── Text Theme ─────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: AppTextStyle.displayPrice,
        headlineLarge: AppTextStyle.headlineLg,
        headlineMedium: AppTextStyle.headlineMd,
        bodyLarge: AppTextStyle.bodyLg,
        bodyMedium: AppTextStyle.bodyMd,
        labelSmall: AppTextStyle.labelSm,
      ),

      // ── AppBar Theme ───────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.surface,
        foregroundColor: AppColor.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      // ── Card Theme ─────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColor.surfaceContainerLowest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button ────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryContainer,
          foregroundColor: AppColor.onPrimaryContainer,
          minimumSize: const Size(0, AppSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          textStyle: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColor.secondaryContainer,
          foregroundColor: AppColor.primaryContainer,
          minimumSize: const Size(0, AppSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
          side: BorderSide.none,
          textStyle: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Text Button ────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Input Decoration ───────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColor.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        hintStyle: AppTextStyle.bodyMd.copyWith(color: AppColor.outline),
      ),

      // ── Divider ────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColor.divider,
        thickness: 1,
        space: 0,
      ),

      // ── Chip Theme ─────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.secondaryContainer,
        selectedColor: AppColor.primaryContainer,
        labelStyle: AppTextStyle.labelSm,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),

      // ── Bottom Navigation ──────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColor.surfaceContainerLowest,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── ScaffoldMessenger (Snackbars) ──────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.inverseSurface,
        contentTextStyle: AppTextStyle.bodyMd.copyWith(
          color: AppColor.inverseOnSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}
