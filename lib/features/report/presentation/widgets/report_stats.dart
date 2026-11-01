import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';

/// Kotak angka dan list produk terlaris dipakai dua kali: dashboard (hari ini)
/// dan layar laporan (preset). Satu definisi supaya angkanya tidak pernah
/// ditata beda di dua tempat.
class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColor.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyle.headlineMd.copyWith(
                color: AppColor.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BestSellerList extends StatelessWidget {
  const BestSellerList({super.key, required this.items, required this.empty});

  final List<BestSeller> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          empty,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColor.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColor.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Text(
                    items[i].name,
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColor.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${items[i].qtySold} terjual',
                  style: AppTextStyle.labelSm.copyWith(
                    color: AppColor.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (i != items.length - 1)
            const Divider(height: 1, color: AppColor.divider),
        ],
      ],
    );
  }
}
