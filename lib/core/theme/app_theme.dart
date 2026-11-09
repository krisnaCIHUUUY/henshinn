import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class AppTheme {
  AppTheme._();

  /// Satu-satunya bayangan di desain v2: bottom sheet, dialog, dan PayBar yang
  /// melayang. Kartu dan baris daftar dibatasi [AppColor.line], bukan bayangan.
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color(0x1F172021),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];

  static ThemeData get light {
    // Material tetap butuh ColorScheme lengkap untuk widget bawaan yang tidak
    // kita beri style sendiri. Token v2 dipetakan ke slot terdekat; yang tidak
    // punya padanan (secondary/tertiary) diisi token yang paling tidak
    // mengejutkan, bukan warna baru.
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColor.primary,
      onPrimary: AppColor.onPrimary,
      primaryContainer: AppColor.primarySoft,
      onPrimaryContainer: AppColor.primary,
      secondary: AppColor.primary,
      onSecondary: AppColor.onPrimary,
      secondaryContainer: AppColor.primarySoft,
      onSecondaryContainer: AppColor.primary,
      tertiary: AppColor.warning,
      onTertiary: AppColor.onPrimary,
      tertiaryContainer: AppColor.warningSoft,
      onTertiaryContainer: AppColor.warning,
      error: AppColor.danger,
      onError: AppColor.onPrimary,
      errorContainer: AppColor.dangerSoft,
      onErrorContainer: AppColor.danger,
      surface: AppColor.surface,
      onSurface: AppColor.ink,
      onSurfaceVariant: AppColor.inkMuted,
      surfaceContainerHighest: AppColor.surfaceMuted,
      outline: AppColor.lineStrong,
      outlineVariant: AppColor.line,
      inverseSurface: AppColor.ink,
      onInverseSurface: AppColor.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColor.bg,

      textTheme: const TextTheme(
        displayLarge: AppTextStyle.amount,
        headlineLarge: AppTextStyle.stat,
        titleLarge: AppTextStyle.title,
        titleMedium: AppTextStyle.heading,
        bodyLarge: AppTextStyle.body,
        bodyMedium: AppTextStyle.body,
        labelLarge: AppTextStyle.label,
        labelSmall: AppTextStyle.caption,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.bg,
        foregroundColor: AppColor.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyle.title,
      ),

      cardTheme: const CardThemeData(
        color: AppColor.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.onPrimary,
          minimumSize: const Size(0, AppSpacing.tapPrimary),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyle.bodyStrong,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColor.surfaceMuted,
          foregroundColor: AppColor.ink,
          minimumSize: const Size(0, AppSpacing.tapPrimary),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide.none,
          textStyle: AppTextStyle.bodyStrong,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: AppTextStyle.bodyStrong,
        ),
      ),

      // Field v2 berlatar putih dengan batas `lineStrong` yang terlihat, bukan
      // kotak abu tanpa garis seperti v1.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surface,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColor.lineStrong),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColor.lineStrong),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColor.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColor.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s3,
        ),
        labelStyle: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
        helperStyle: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
        hintStyle: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
        errorStyle: AppTextStyle.label.copyWith(color: AppColor.danger),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColor.line,
        thickness: 1,
        space: 0,
      ),

      chipTheme: const ChipThemeData(
        backgroundColor: AppColor.surface,
        selectedColor: AppColor.primarySoft,
        labelStyle: AppTextStyle.label,
        shape: StadiumBorder(side: BorderSide(color: AppColor.lineStrong)),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: AppColor.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: AppColor.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        titleTextStyle: AppTextStyle.heading,
        contentTextStyle: AppTextStyle.body,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.ink,
        contentTextStyle: AppTextStyle.body.copyWith(color: AppColor.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}
