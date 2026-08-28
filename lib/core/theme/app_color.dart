import 'dart:ui';

class AppColor {
  AppColor._();

  // ── Primary ──────────────────────────────────────────────
  static const Color primary = Color(0xFF006565);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008080);
  static const Color onPrimaryContainer = Color(0xFFE3FFFE);
  static const Color inversePrimary = Color(0xFF76D6D5);
  static const Color surfaceTint = Color(0xFF006A6A);

  // ── Primary Fixed ────────────────────────────────────────
  static const Color primaryFixed = Color(0xFF93F2F2);
  static const Color primaryFixedDim = Color(0xFF76D6D5);
  static const Color onPrimaryFixed = Color(0xFF002020);
  static const Color onPrimaryFixedVariant = Color(0xFF004F4F);

  // ── Secondary ────────────────────────────────────────────
  static const Color secondary = Color(0xFF516161);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD4E6E5);
  static const Color onSecondaryContainer = Color(0xFF576867);

  // ── Secondary Fixed ──────────────────────────────────────
  static const Color secondaryFixed = Color(0xFFD4E6E5);
  static const Color secondaryFixedDim = Color(0xFFB8CAC9);
  static const Color onSecondaryFixed = Color(0xFF0E1E1E);
  static const Color onSecondaryFixedVariant = Color(0xFF3A4A49);

  // ── Tertiary ─────────────────────────────────────────────
  static const Color tertiary = Color(0xFF8B4823);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFA96039);
  static const Color onTertiaryContainer = Color(0xFFFFF9F7);

  // ── Tertiary Fixed ───────────────────────────────────────
  static const Color tertiaryFixed = Color(0xFFFFDBCB);
  static const Color tertiaryFixedDim = Color(0xFFFFB692);
  static const Color onTertiaryFixed = Color(0xFF341100);
  static const Color onTertiaryFixedVariant = Color(0xFF733512);

  // ── Error ────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Surface ──────────────────────────────────────────────
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3E4949);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceVariant = Color(0xFFE0E3E5);

  // ── Surface Container ────────────────────────────────────
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // ── Inverse Surface ──────────────────────────────────────
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);

  // ── Outline ──────────────────────────────────────────────
  static const Color outline = Color(0xFF6E7979);
  static const Color outlineVariant = Color(0xFFBDC9C8);

  // ── Background (alias for surface) ───────────────────────
  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);

  // ── Semantic / POS-specific ──────────────────────────────
  static const Color payButton = primaryContainer;
  static const Color discountBadge = secondaryContainer;
  static const Color inputBackground = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFF1F5F9);
}
