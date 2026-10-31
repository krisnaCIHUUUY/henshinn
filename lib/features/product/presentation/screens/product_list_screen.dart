import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/product/presentation/screens/product_form_screen.dart';
import 'package:henshin/features/product/presentation/widgets/stock_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/utils/page_routes.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  /// null = tab "Semua". Tab lain memakai id kategori asli.
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>()
      ..add(const ProductEvent.subscriptionRequested())
      ..add(const ProductEvent.categoriesRequested())
      ..add(const ProductEvent.lowStockRequested());
  }

  /// Form dibuka dengan `ProductBloc` yang sama (lewat BlocProvider.value)
  /// supaya penyimpanan langsung terlihat di list ini.
  Future<void> _openForm([ProductEntity? product]) async {
    final bloc = context.read<ProductBloc>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ProductFormScreen(product: product),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductEntity product) async {
    final bloc = context.read<ProductBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text(
          '${product.name} akan dihapus. Produk yang sudah dipakai di '
          'transaksi tidak bisa dihapus — nonaktifkan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Hapus', style: TextStyle(color: AppColor.error)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(ProductEvent.deleted(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: BlocConsumer<ProductBloc, ProductState>(
          listenWhen: (previous, current) =>
              current.status == ProductStatus.failure &&
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage)));
          },
          builder: (context, state) {
            final products = _selectedCategoryId == null
                ? state.products
                : state.products
                      .where((p) => p.categoryId == _selectedCategoryId)
                      .toList();

            return Column(
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
                      _HeaderRow(onAddPressed: _openForm),
                      const SizedBox(height: AppSpacing.lg - 4),
                      _CategoryTabs(
                        categories: state.categories,
                        selectedId: _selectedCategoryId,
                        onSelected: (id) =>
                            setState(() => _selectedCategoryId = id),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.lowStockProducts.isNotEmpty)
                        _LowStockBanner(count: state.lowStockProducts.length),
                    ],
                  ),
                ),
                Expanded(
                  child: _ProductListBody(
                    status: state.status,
                    products: products,
                    onEdit: _openForm,
                    onDelete: _confirmDelete,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({
    required this.status,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductStatus status;
  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onEdit;
  final ValueChanged<ProductEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (status == ProductStatus.loading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Belum ada produk di sini.\nTekan + untuk menambah produk pertama.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMd.copyWith(color: AppColor.outline),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductTile(
          product: product,
          onEdit: () => onEdit(product),
          onDelete: () => onDelete(product),
          onRestock: () => StockSheet.show(
            context,
            product: product,
            mode: StockSheetMode.restock,
          ),
          onAdjust: () => StockSheet.show(
            context,
            product: product,
            mode: StockSheetMode.adjust,
          ),
        );
      },
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
  final List<CategoryEntity> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Tab pertama "Semua" diwakili id null, sisanya kategori dari DB.
    final tabs = <(int?, String)>[
      (null, 'Semua'),
      for (final category in categories) (category.id, category.name),
    ];

    return SizedBox(
      height: AppSpacing.touchTargetMin,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (context, index) {
          final (id, label) = tabs[index];
          final selected = id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(id),
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
                label,
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
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onRestock,
    this.onAdjust,
  });

  final ProductEntity product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestock;
  final VoidCallback? onAdjust;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath;

    return Opacity(
      // Produk nonaktif tetap terlihat di manajemen, hanya diredam.
      opacity: product.isActive ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imagePath != null && imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(product.price),
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'HPP: ${formatRupiah(product.costPrice)} | Stok: ${product.stock}',
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 8),
                  _StockBadge(product: product),
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
                PopupMenuButton<VoidCallback?>(
                  tooltip: 'Aksi stok',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.black45,
                  ),
                  onSelected: (action) => action?.call(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: onRestock,
                      child: const Text('Restok'),
                    ),
                    PopupMenuItem(
                      value: onAdjust,
                      child: const Text('Koreksi stok'),
                    ),
                    PopupMenuItem(
                      value: onDelete,
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: AppColor.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (product) {
      _ when !product.isActive => ('Nonaktif', AppColor.outlineVariant),
      _ when product.isOutOfStock => ('Stok habis', AppColor.errorContainer),
      _ when product.isLowStock => ('Stok menipis', AppColor.discountBadge),
      _ => ('Stok aman', AppColor.discountBadge),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
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

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => context.push(PageRoutes.perluRestok),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColor.errorContainer,
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColor.onSurface),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$count produk perlu restok',
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColor.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColor.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
