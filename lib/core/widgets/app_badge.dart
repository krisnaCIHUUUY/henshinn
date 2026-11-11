import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_text_style.dart';

/// Warna badge. Satu-satunya pilihan yang dibuka ke pemanggil: isi teksnya
/// milik layar, warnanya milik design system.
enum BadgeTone { neutral, success, warning, danger }

/// Label kecil berlatar lembut: `Sisa 3`, `Habis`, `Selesai`, `Void`.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (AppColor.surfaceMuted, AppColor.inkMuted),
      BadgeTone.success => (AppColor.successSoft, AppColor.success),
      BadgeTone.warning => (AppColor.warningSoft, AppColor.warning),
      BadgeTone.danger => (AppColor.dangerSoft, AppColor.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
