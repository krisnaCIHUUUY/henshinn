import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

const Map<int, String> _categoryNameById = {1: 'Minuman', 2: 'Makanan'};

final NumberFormat _priceFmt = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class _DummyProduct {
  final int id;
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final String? imagePath;

  const _DummyProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imagePath,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock <= 5 && stock > 0;
}

final List<_DummyProduct> _dummyProducts = [
  const _DummyProduct(
    id: 1,
    name: 'Cappuccino',
    price: 25000,
    stock: 45,
    categoryId: 1,
    imagePath: 'assets/images/placeholder_product.png',
  ),
  const _DummyProduct(
    id: 2,
    name: 'Iced Matcha Latte',
    price: 28000,
    stock: 30,
    categoryId: 1,
    imagePath: 'assets/images/placeholder_product.png',
  ),
  const _DummyProduct(
    id: 3,
    name: 'Croissant Butter',
    price: 22000,
    stock: 5,
    categoryId: 2,
  ),
  const _DummyProduct(
    id: 4,
    name: 'Chocolate Cake',
    price: 35000,
    stock: 0,
    categoryId: 2,
  ),
];

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.unit,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceContainerHighest,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: AppColor.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text("Kategori", style: AppTextStyle.bodyMd),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: AppColor.onPrimary),
                label: const Text(
                  'Tambah',
                  style: TextStyle(color: AppColor.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryContainer,
                  foregroundColor: AppColor.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            itemCount: _dummyProducts.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _ProductCard(product: _dummyProducts[index]),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _DummyProduct product;

  @override
  Widget build(BuildContext context) {
    final String? categoryName = _categoryNameById[product.categoryId];
    final bool isOutOfStock = product.isOutOfStock;
    final bool isLowStock = product.isLowStock;
    final Color stockColor = isOutOfStock || isLowStock
        ? AppColor.error
        : AppColor.onSurface;
    final String stockText = isOutOfStock ? 'Habis' : product.stock.toString();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppTheme.elevation1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ProductImage(imagePath: product.imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColor.onSurface,
                          ),
                        ),
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(width: 8),
                        _CategoryBadge(label: categoryName),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _priceFmt.format(product.price),
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stok: $stockText',
                    style: AppTextStyle.labelSm.copyWith(color: stockColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColor.surfaceContainerLow,
                    child: Icon(Icons.edit, size: 14, color: AppColor.outline),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColor.surfaceContainerLow,
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: AppColor.outline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    const double size = 68;
    final String? path = imagePath;

    if (path == null || path.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColor.surfaceContainerLow,
          borderRadius: AppRadius.mdAll,
        ),
        child: const Icon(Icons.image_outlined, color: AppColor.outline),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColor.surfaceContainerLow,
            borderRadius: AppRadius.mdAll,
          ),
          child: const Icon(Icons.image_outlined, color: AppColor.outline),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isMakanan = label.toLowerCase() == 'makanan';
    final Color bg = isMakanan
        ? AppColor.tertiaryFixed
        : AppColor.secondaryContainer;
    final Color fg = isMakanan
        ? AppColor.onTertiaryFixed
        : AppColor.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullAll),
      child: Text(label, style: AppTextStyle.labelSm.copyWith(color: fg)),
    );
  }
}
