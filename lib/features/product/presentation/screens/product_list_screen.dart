import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:intl/intl.dart';


final Map<int, String> _categories = {
  1: 'Semua',
  2: 'Minuman',
  3: 'Makanan',
  4: 'Merchandise',
};

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
  const _DummyProduct(
    id: 5,
    name: 'Nasi Goreng',
    price: 28000,
    stock: 12,
    categoryId: 2,
  ),
  const _DummyProduct(
    id: 6,
    name: 'Teh Botol',
    price: 8000,
    stock: 50,
    categoryId: 1,
  ),
  const _DummyProduct(
    id: 7,
    name: 'Kaos Henshin',
    price: 95000,
    stock: 15,
    categoryId: 4,
  ),
];

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _selectedCategoryIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(
                    onAddPressed: () {
                      // navigasi ke Add/Edit product screen
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg - 4),
                  _CategoryTabs(
                    categories: _categories.values.toList(),
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: (index) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _dummyProducts.length,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                separatorBuilder: (_, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final product = _dummyProducts[index];
                  return _ProductTile(
                    imagePath: product.imagePath,
                    name: product.name,
                    price: product.price,
                    category: product.categoryId,
                    stock: product.stock,
                    isLowStock: product.isLowStock,
                    isOutOfStock: product.isOutOfStock,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HEADER ROW 

class _HeaderRow extends StatelessWidget {
  final VoidCallback onAddPressed;
  const _HeaderRow({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Produk',
          style: AppTextStyle.headlineLg.copyWith(color: AppColor.onSurface),
        ),
        // GestureDetector(
        //   onTap: onAddPressed,
        //   child: Container(
        //     width: AppSpacing.touchTargetMin,
        //     height: AppSpacing.touchTargetMin,
        //     decoration: BoxDecoration(
        //       color: AppColor.surfaceContainerLowest,
        //       borderRadius: AppRadius.mdAll,
        //       border: Border.all(color: AppColor.outlineVariant),
        //     ),
        //     child: Icon(Icons.add, color: AppColor.onSurface),
        //   ),
        // ),
        ElevatedButton(
          onPressed: onAddPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColor.onSurface,
            backgroundColor: AppColor.surfaceContainerLowest,
            fixedSize: Size(AppSpacing.touchTargetMin, AppSpacing.touchTargetMin),
            padding: EdgeInsets.zero,
            shape: CircleBorder(
              side: BorderSide(color: AppColor.outlineVariant),
            ),
          ),
          child: Icon(Icons.add, color: AppColor.onSurface),
        ),
      ],
    );
  }
}

//  CATEGORY TABS

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.touchTargetMin,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColor.onSurface
                    : AppColor.surfaceContainerLowest,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: selected
                      ? AppColor.onSurface
                      : AppColor.outlineVariant,
                ),
              ),
              child: Text(
                categories[index],
                style: AppTextStyle.labelSm.copyWith(
                  color: selected ? AppColor.onPrimary : AppColor.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// PRODUCT TILE 

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.imagePath,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    required this.isLowStock,
    required this.isOutOfStock,
    this.onEdit,
    this.onDelete,
  });

  final String? imagePath;
  final String name;
  final int price;
  final int category;
  final int? stock; // null = stok tanpa batas
  final bool isLowStock;
  final bool isOutOfStock;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final Color stockColor = isOutOfStock || isLowStock
        ? AppColor.error
        : AppColor.onSurface;
    final String stockText = isOutOfStock
        ? 'Habis'
        : stock == null
        ? 'Tanpa batas'
        : stock.toString();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppTheme.elevation1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md - 4),
        child: Row(
          children: [
            _ProductImage(imagePath: imagePath),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColor.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CategoryBadge(label: _categories[category] ?? 'Lainnya'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    _priceFmt.format(price),
                    style: AppTextStyle.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Stok: $stockText',
                    style: AppTextStyle.labelSm.copyWith(color: stockColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    
                    disabledBackgroundColor: AppColor.surfaceContainerLow,
                    shape: CircleBorder()
                  ),
                  onPressed: onEdit,
                  child: Icon(Icons.edit, size: 14, color: AppColor.outline),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColor.surfaceContainerLow,
                    shape: CircleBorder()
                  ),
                  onPressed: onDelete,
                  child: Icon(Icons.delete_outline, size: 14, color: AppColor.outline),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullAll),
      child: Text(label, style: AppTextStyle.labelSm.copyWith(color: fg)),
    );
  }
}

