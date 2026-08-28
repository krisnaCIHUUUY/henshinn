import 'package:flutter/material.dart';

class AppTextStyle {
  AppTextStyle._();

  static const String _fontFamily = 'Inter';

  // ── Display Price ────────────────────────────────────────
  static const TextStyle displayPrice = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 56 / 48,
    letterSpacing: -0.02,
  );

  // ── Headline Large ───────────────────────────────────────
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
  );

  // ── Headline Medium ──────────────────────────────────────
  static const TextStyle headlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  // ── Headline Large Mobile ────────────────────────────────
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  // ── Body Large ───────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
  );

  // ── Body Medium ──────────────────────────────────────────
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  // ── Label Small ──────────────────────────────────────────
  static const TextStyle labelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 16 / 13,
    letterSpacing: 0.01,
  );
}
