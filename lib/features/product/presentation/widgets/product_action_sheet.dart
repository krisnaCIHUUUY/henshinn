import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/product/domain/entities/product.dart';

/// Aksi yang bisa dilakukan ke satu produk dari daftar.
enum ProductAction { edit, restock, adjust, delete }

/// Sheet aksi baris produk. Baris produk di desain v2 tidak punya ikon, jadi
/// Ubah/Restok/Koreksi/Hapus tinggal di sini — satu ketukan ke semuanya, dan
/// Hapus tidak bisa tersenggol saat pemilik hanya mau menambah stok (ADR-053).
///
/// Sheet-nya cuma memilih; yang mengerjakan aksinya pemanggil. Itu sengaja:
/// Restok dan Koreksi sudah punya `StockSheet` sendiri, dan menumpuk sheet di
/// dalam sheet membuat yang di bawah tidak pernah tertutup.
class ProductActionSheet extends StatelessWidget {
  const ProductActionSheet({super.key, required this.product});

  final ProductEntity product;

  static Future<ProductAction?> show(
    BuildContext context, {
    required ProductEntity product,
  }) {
    return showModalBottomSheet<ProductAction>(
      context: context,
      builder: (_) => ProductActionSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.s2,
          bottom: AppSpacing.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.line,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyle.heading.copyWith(color: AppColor.ink),
                  ),
                  Text(
                    'Stok sekarang ${product.stock}',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'Ubah produk',
              action: ProductAction.edit,
            ),
            _ActionRow(
              icon: Icons.add_box_outlined,
              label: 'Restok',
              action: ProductAction.restock,
            ),
            _ActionRow(
              icon: Icons.sync_alt,
              label: 'Koreksi stok',
              action: ProductAction.adjust,
            ),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'Hapus',
              action: ProductAction.delete,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final ProductAction action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColor.danger : AppColor.ink;

    return InkWell(
      onTap: () => Navigator.of(context).pop(action),
      child: Container(
        height: AppSpacing.rowMin - AppSpacing.s4,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.s4),
            Text(label, style: AppTextStyle.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
