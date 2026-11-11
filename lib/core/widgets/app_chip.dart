import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

/// Baris chip yang bisa digeser ke samping. Tingginya tetap supaya chip di
/// luar layar tidak memaksa `Column` induknya tumbuh.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 + AppSpacing.s3,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          0,
        ),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Chip filter: satu baris pilihan yang saling menggantikan. Dipakai Kasir
/// (kategori), Produk (Semua / Perlu restok / kategori), Riwayat (rentang),
/// dan sheet void (alasan).
///
/// Tingginya 40, bukan `tapMin` 48: chip selalu berbaris di area yang juga
/// punya jarak s3 di atasnya, jadi sasaran ketuk efektifnya tetap ≥48.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primarySoft : AppColor.surface,
      borderRadius: AppRadius.fullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fullAll,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.fullAll,
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.lineStrong,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.label.copyWith(
              color: selected ? AppColor.primary : AppColor.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
