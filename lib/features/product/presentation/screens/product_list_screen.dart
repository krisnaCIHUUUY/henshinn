import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:intl/intl.dart';

import 'dart:developer';

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
    categoryId: 2,
    imagePath: 'assets/images/placeholder_product.png',
  ),
  const _DummyProduct(
    id: 2,
    name: 'Iced Matcha Latte',
    price: 28000,
    stock: 30,
    categoryId: 2,
    imagePath: 'assets/images/placeholder_product.png',
  ),
  const _DummyProduct(
    id: 3,
    name: 'Croissant Butter',
    price: 22000,
    stock: 5,
    categoryId: 3,
  ),
  const _DummyProduct(
    id: 4,
    name: 'Chocolate Cake',
    price: 35000,
    stock: 0,
    categoryId: 3,
  ),
  const _DummyProduct(
    id: 5,
    name: 'Nasi Goreng',
    price: 28000,
    stock: 12,
    categoryId: 3,
  ),
  const _DummyProduct(
    id: 6,
    name: 'Teh Botol',
    price: 8000,
    stock: 50,
    categoryId: 2,
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
                    onDelete: () {
                      log('delete kepencet');
                    },
                    onEdit: () {
                      log('edit kepencet');
                    },
                    imagePath: product.imagePath,
                    name: product.name,
                    price: product.price,
                    category: product.categoryId,
                    stock: product.stock,
                    hpp: 0,
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
        ElevatedButton(
          onPressed: onAddPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColor.onSurface,
            backgroundColor: AppColor.surfaceContainerLowest,
            fixedSize: Size(
              AppSpacing.touchTargetMin,
              AppSpacing.touchTargetMin,
            ),
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
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm + 2),
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
    required this.hpp,
    required this.stock,
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  final String? imagePath;
  final String name;
  final int price;
  final int hpp;
  final int? stock; // null = tanpa batas
  final int category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String stockText = stock == null ? 'Tanpa Batas' : stock.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imagePath != null && imagePath!.isNotEmpty
                ? Image.asset(
                    imagePath!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderImage(),
                  )
                : _PlaceholderImage(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _priceFmt.format(price),
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'HPP: ${_priceFmt.format(hpp)} | Stok: $stockText',
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
                const SizedBox(height: 8),

                _CategoryBadge(category: category),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.black45,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.image_outlined, color: Colors.black26),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final int category;

  @override
  Widget build(BuildContext context) {
    final String label = _categories[category] ?? 'Lainnya';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.discountBadge,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: AppColor.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
