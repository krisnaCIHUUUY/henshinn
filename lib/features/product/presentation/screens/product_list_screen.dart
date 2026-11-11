import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/widgets/app_avatar.dart';
import 'package:henshin/core/widgets/app_badge.dart';
import 'package:henshin/core/widgets/app_card.dart';
import 'package:henshin/core/widgets/app_chip.dart';
import 'package:henshin/core/widgets/search_row.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/product/presentation/screens/product_form_screen.dart';
import 'package:henshin/features/product/presentation/widgets/product_action_sheet.dart';
import 'package:henshin/features/product/presentation/widgets/stock_sheet.dart';
import 'package:henshin/features/transaction/presentation/screens/barcode_scanner_screen.dart';

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

/// Produk yang terlihat untuk satu kombinasi chip + kata kunci.
///
/// `lowStock` datang dari `ProductState.lowStockProducts` — query yang sudah
/// ada, bukan hitungan ulang di sini. Isinya sengaja **tidak** sama dengan
/// getter `isLowStock` di entity: query itu juga memasukkan stok 0, dan chip
/// "Perlu restok" memang harus memuat yang sudah habis (ADR-052).
List<ProductEntity> visibleProducts({
  required List<ProductEntity> products,
  required List<ProductEntity> lowStock,
  required bool lowStockOnly,
  int? categoryId,
  String keyword = '',
}) {
  final base = lowStockOnly ? lowStock : products;
  final needle = keyword.trim().toLowerCase();
  return base.where((p) {
    if (categoryId != null && p.categoryId != categoryId) return false;
    if (needle.isEmpty) return true;
    return p.name.toLowerCase().contains(needle) ||
        (p.barcode ?? '').toLowerCase().contains(needle);
  }).toList();
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  String _keyword = '';

  /// null = chip "Semua" atau "Perlu restok"; selain itu id kategori asli.
  int? _categoryId;

  /// Chip "Perlu restok" aktif. Saling menggantikan dengan `_categoryId`:
  /// dua filter sekaligus tidak ada di desain v2.
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>()
      ..add(const ProductEvent.subscriptionRequested())
      ..add(const ProductEvent.categoriesRequested())
      ..add(const ProductEvent.lowStockRequested());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  /// Scanner di sini hanya mengembalikan barcode-nya — layar Produk tidak punya
  /// `CartBloc`, dan yang dicari pemilik di sini produknya, bukan penjualan.
  /// Barcode yang belum terdaftar pun berguna: hasilnya "tidak ada produk
  /// cocok", yang memang jawabannya.
  Future<void> _scanIntoSearch() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(returnsCode: true),
      ),
    );
    if (code == null || !mounted) return;
    _search.text = code;
    setState(() => _keyword = code);
  }

  /// Satu sheet untuk semua aksi baris: baris produk di desain v2 tidak punya
  /// ikon, jadi Ubah/Restok/Koreksi/Hapus tidak punya tempat lain (ADR-053).
  Future<void> _openActions(ProductEntity product) async {
    final action = await ProductActionSheet.show(context, product: product);
    if (action == null || !mounted) return;

    switch (action) {
      case ProductAction.edit:
        await _openForm(product);
      case ProductAction.restock:
        await StockSheet.show(
          context,
          product: product,
          mode: StockSheetMode.restock,
        );
      case ProductAction.adjust:
        await StockSheet.show(
          context,
          product: product,
          mode: StockSheetMode.adjust,
        );
      case ProductAction.delete:
        await _confirmDelete(product);
    }
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
      appBar: AppBar(
        title: Text(
          'Produk',
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
        actions: [
          BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (p, c) => p.products.length != c.products.length,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s4),
              child: Center(
                child: Text(
                  '${state.products.length} produk',
                  style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
                ),
              ),
            ),
          ),
        ],
      ),
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

            // Chip yang sedang dipilih bisa lenyap saat produk terakhirnya
            // dipindah; tanpa ini daftarnya jadi kosong tanpa chip yang aktif.
            final categoryId =
                visibleCategories.any((c) => c.id == _categoryId)
                ? _categoryId
                : null;
            final lowStockOnly =
                _lowStockOnly && state.lowStockProducts.isNotEmpty;

            final products = visibleProducts(
              products: state.products,
              lowStock: state.lowStockProducts,
              lowStockOnly: lowStockOnly,
              categoryId: categoryId,
              keyword: _keyword,
            );

            final categoryNames = {
              for (final category in state.categories)
                category.id: category.name,
            };

            return Column(
              children: [
                SearchRow(
                  controller: _search,
                  onKeywordChanged: (value) =>
                      setState(() => _keyword = value),
                  onScanPressed: _scanIntoSearch,
                ),
                ChipRow(
                  children: [
                    AppChip(
                      label: 'Semua',
                      selected: categoryId == null && !lowStockOnly,
                      onTap: () => setState(() {
                        _categoryId = null;
                        _lowStockOnly = false;
                      }),
                    ),
                    if (state.lowStockProducts.isNotEmpty)
                      AppChip(
                        label:
                            'Perlu restok · ${state.lowStockProducts.length}',
                        selected: lowStockOnly,
                        onTap: () => setState(() {
                          _lowStockOnly = true;
                          _categoryId = null;
                        }),
                      ),
                    for (final category in visibleCategories)
                      AppChip(
                        label: category.name,
                        selected: categoryId == category.id,
                        onTap: () => setState(() {
                          _categoryId = category.id;
                          _lowStockOnly = false;
                        }),
                      ),
                  ],
                ),
                Expanded(
                  child: _ProductListBody(
                    status: state.status,
                    products: products,
                    categoryNames: categoryNames,
                    onTapProduct: _openActions,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Tombol melayang di atas bottom nav shell, sama seperti PayBar di Kasir.
      bottomNavigationBar: _AddProductBar(onPressed: _openForm),
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({
    required this.status,
    required this.products,
    required this.categoryNames,
    required this.onTapProduct,
  });

  final ProductStatus status;
  final List<ProductEntity> products;
  final Map<int, String> categoryNames;
  final ValueChanged<ProductEntity> onTapProduct;

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
            'Belum ada produk di sini.\n'
            'Tekan "Tambah produk" untuk menambah produk pertama.',
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.s4,
        bottom: AppSpacing.s6,
      ),
      children: [
        AppCard(
          children: [
            for (final product in products)
              _ProductRow(
                product: product,
                categoryName: categoryNames[product.categoryId],
                onTap: () => onTapProduct(product),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.categoryName,
    required this.onTap,
  });

  final ProductEntity product;
  final String? categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // Produk nonaktif tetap terlihat di manajemen, hanya diredam.
      opacity: product.isActive ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.rowMin),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              AppAvatar(name: product.name),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body.copyWith(color: AppColor.ink),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${categoryName ?? 'Tanpa kategori'} · '
                            'Stok ${product.stock}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.label.copyWith(
                              color: AppColor.inkMuted,
                            ),
                          ),
                        ),
                        ?_badgeFor(product),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                formatRupiah(product.price),
                style: AppTextStyle.bodyStrong.copyWith(color: AppColor.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hanya keadaan yang perlu tindakan yang dapat badge. "Stok aman" dulu ikut
  /// diberi badge hijau, dan di daftar 86 produk hasilnya 86 badge hijau yang
  /// menenggelamkan 4 yang benar-benar penting.
  Widget? _badgeFor(ProductEntity product) {
    final badge = switch (product) {
      _ when !product.isActive => const AppBadge(
        label: 'Nonaktif',
        tone: BadgeTone.neutral,
      ),
      _ when product.isOutOfStock => const AppBadge(
        label: 'Habis',
        tone: BadgeTone.danger,
      ),
      _ when product.isLowStock => AppBadge(
        label: 'Sisa ${product.stock}',
        tone: BadgeTone.warning,
      ),
      _ => null,
    };
    if (badge == null) return null;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s2),
      child: badge,
    );
  }
}

class _AddProductBar extends StatelessWidget {
  const _AddProductBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.bg,
        boxShadow: AppTheme.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s3,
          ),
          // Tinggi dipatok: Column tanpa batas di slot bottomNavigationBar
          // memakan seluruh layar (ADR-051). Di sini satu tombol saja, tapi
          // SizedBox-nya tetap yang menahan tingginya.
          child: SizedBox(
            height: AppSpacing.tapPrimary,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: const Text('Tambah produk'),
            ),
          ),
        ),
      ),
    );
  }
}
