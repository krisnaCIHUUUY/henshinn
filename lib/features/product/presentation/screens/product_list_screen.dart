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

/// Kategori yang punya minimal satu produk aktif.
///
/// Tab kategori kosong tidak ditampilkan: tidak ada hapus atau ganti nama
/// kategori di aplikasi ini, jadi ini yang membuat salah ketik hilang sendiri
/// begitu produknya dipindah. Produk nonaktif tidak dihitung — kategori
/// gunanya alat cari, dan kasir tidak mencari produk nonaktif (ADR-038).
///
/// Fungsi lepas, bukan di dalam `build`, supaya bisa diuji dengan async nyata:
/// di `testWidgets` stream Drift tidak pernah maju (ADR-012).
List<CategoryEntity> categoriesWithActiveProducts(
  List<CategoryEntity> categories,
  List<ProductEntity> products,
) {
  final used = {
    for (final product in products)
      if (product.isActive) product.categoryId,
  };
  return categories.where((c) => used.contains(c.id)).toList();
}

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
          '${product.name} akan dihapus. Produk yang pernah terjual tidak '
          'bisa dihapus karena riwayat penjualannya ikut hilang — '
          'nonaktifkan saja produknya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Hapus', style: TextStyle(color: AppColor.danger)),
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
      backgroundColor: AppColor.bg,
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
            final visibleCategories = categoriesWithActiveProducts(
              state.categories,
              state.products,
            );

            // Tab yang sedang dipilih bisa lenyap saat produk terakhirnya
            // dipindah; tanpa ini daftarnya jadi kosong tanpa tab yang aktif.
            final selectedCategoryId =
                visibleCategories.any((c) => c.id == _selectedCategoryId)
                ? _selectedCategoryId
                : null;

            final products = selectedCategoryId == null
                ? state.products
                : state.products
                      .where((p) => p.categoryId == selectedCategoryId)
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s6,
                    AppSpacing.s4,
                    AppSpacing.s6,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderRow(onAddPressed: _openForm),
                      const SizedBox(height: AppSpacing.s6 - 4),
                      _CategoryTabs(
                        categories: visibleCategories,
                        selectedId: selectedCategoryId,
                        onSelected: (id) =>
                            setState(() => _selectedCategoryId = id),
                      ),
                      const SizedBox(height: AppSpacing.s2),
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
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Text(
            'Belum ada produk di sini.\nTekan + untuk menambah produk pertama.',
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
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
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
        ElevatedButton(
          onPressed: onAddPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColor.ink,
            backgroundColor: AppColor.surface,
            fixedSize: Size(
              AppSpacing.tapMin,
              AppSpacing.tapMin,
            ),
            padding: EdgeInsets.zero,
            shape: CircleBorder(
              side: BorderSide(color: AppColor.line),
            ),
          ),
          child: Icon(Icons.add, color: AppColor.ink),
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
      height: AppSpacing.tapMin,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2 + 2),
        itemBuilder: (context, index) {
          final (id, label) = tabs[index];
          final selected = id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColor.ink
                    : AppColor.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: selected
                      ? AppColor.ink
                      : AppColor.lineStrong,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyle.label.copyWith(
                  color: selected ? AppColor.onPrimary : AppColor.ink,
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
                    style: AppTextStyle.body.copyWith(color: AppColor.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(product.price),
                    style: AppTextStyle.bodyStrong.copyWith(
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'HPP: ${formatRupiah(product.costPrice)} | Stok: ${product.stock}',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
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
                      color: AppColor.inkMuted,
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
                    color: AppColor.inkMuted,
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
                        style: TextStyle(color: AppColor.danger),
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
      color: AppColor.surfaceMuted,
      child: const Icon(Icons.image_outlined, color: AppColor.inkMuted),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (product) {
      _ when !product.isActive =>
        ('Nonaktif', AppColor.surfaceMuted, AppColor.inkMuted),
      _ when product.isOutOfStock =>
        ('Habis', AppColor.dangerSoft, AppColor.danger),
      _ when product.isLowStock =>
        ('Stok menipis', AppColor.warningSoft, AppColor.warning),
      _ => ('Stok aman', AppColor.successSoft, AppColor.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: AppTextStyle.caption.copyWith(color: foreground),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      // Tidak bisa diketuk lagi: LowStockScreen dihapus di D2 dan chip
      // "Perlu restok" penggantinya lahir di D6.
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColor.warningSoft,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColor.warning),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '$count produk perlu restok',
                style: AppTextStyle.bodyStrong.copyWith(
                  color: AppColor.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
