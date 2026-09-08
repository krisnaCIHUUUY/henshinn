import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fix: Hilangkan Expanded + Column karena parent (StatefulNavigationShell / IndexedStack)
    // bukan Flex sehingga Expanded memicu "Incorrect use of ParentDataWidget".
    // Solusi tanpa Scaffold: gunakan CustomScrollView + Slivers, tidak butuh Expanded.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Chip(
                  label: Text(
                    "Hari Ini",
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: AppColor.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                ),
                Chip(
                  label: Text(
                    "7 Hari",
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: AppColor.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                ),
                Chip(
                  label: Text(
                    "30 Hari",
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: AppColor.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                ),
                Chip(
                  label: Text(
                    "Semua",
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: AppColor.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.separated(
            itemCount: 10,
            itemBuilder: (context, index) => transactionList(),
            separatorBuilder: (context, index) =>
                SizedBox(height: AppSpacing.gutter),
          ),
        ),
      ],
    );
  }
}

ListTile transactionList() {
  return ListTile(
    tileColor: AppColor.surfaceContainerLowest,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.containerPadding,
      vertical: AppSpacing.sm,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    title: Row(
      children: [
        Text(
          "#1",
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColor.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: AppSpacing.gutter),
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            color: AppColor.primaryFixed.withValues(alpha: 0.2),
          ),
          child: Text(
            "TUNAI",
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.primaryFixedDim,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: AppSpacing.unit),
      child: Text(
        "10 June 2023",
        style: AppTextStyle.bodyMd.copyWith(color: AppColor.outlineVariant),
      ),
    ),
    trailing: Icon(
      size: 16,
      Icons.arrow_forward_ios,
      color: AppColor.outlineVariant,
    ),
  );
}
