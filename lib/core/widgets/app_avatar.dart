import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_text_style.dart';

/// Inisial untuk kotak avatar produk. Skema `products` tidak punya kolom
/// gambar, jadi v2 memakai inisial — bukan placeholder gambar.
String productInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

/// Kotak 40×40 berisi huruf pertama nama produk. Dipakai Kasir dan Produk.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        productInitial(name),
        style: AppTextStyle.bodyStrong.copyWith(color: AppColor.inkMuted),
      ),
    );
  }
}
