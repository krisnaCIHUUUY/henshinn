import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';

/// Kartu putih berisi baris-baris, dipisah garis `line`. Satu-satunya bentuk
/// daftar di desain v2.
///
/// Garis pemisah ditambahkan di sini, bukan oleh pemanggil: dua layar yang
/// masing-masing menyisipkan `Divider` sendiri sudah terbukti beda satu piksel.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.children, this.margin});

  final List<Widget> children;

  /// Default margin tepi layar. Beri `EdgeInsets.zero` kalau kartunya sudah
  /// berada di dalam padding lain.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColor.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}
