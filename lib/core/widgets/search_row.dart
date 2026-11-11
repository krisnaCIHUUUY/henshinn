import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';

/// Kolom cari + tombol scan di sampingnya. Dipakai Kasir dan Produk; apa yang
/// dilakukan tombol scan-nya berbeda per layar, jadi itu callback.
class SearchRow extends StatelessWidget {
  const SearchRow({
    super.key,
    required this.controller,
    required this.onKeywordChanged,
    required this.onScanPressed,
    this.hintText = 'Cari produk atau barcode',
  });

  final TextEditingController controller;
  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onScanPressed;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onKeywordChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          SizedBox(
            width: AppSpacing.tapMin,
            height: AppSpacing.tapMin,
            child: IconButton(
              tooltip: 'Scan barcode',
              onPressed: onScanPressed,
              style: IconButton.styleFrom(
                backgroundColor: AppColor.surfaceMuted,
                foregroundColor: AppColor.ink,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ),
        ],
      ),
    );
  }
}
