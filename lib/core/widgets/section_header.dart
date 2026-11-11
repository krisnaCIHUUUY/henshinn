import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

/// Judul bagian di dalam layar ("Keranjang · 2 produk", "Hari ini · 24
/// transaksi"), dengan aksi atau keterangan opsional di kanan.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        0,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.heading.copyWith(color: AppColor.ink),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
