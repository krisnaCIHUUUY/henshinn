import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/widgets/app_avatar.dart';
import 'package:henshin/core/widgets/app_card.dart';
import 'package:henshin/core/widgets/app_chip.dart';
import 'package:henshin/core/widgets/search_row.dart';
import 'package:henshin/core/widgets/section_header.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/usecases/watch_frequent_products.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';
import 'package:henshin/features/transaction/presentation/screens/barcode_scanner_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/payment_screen.dart';
import 'package:henshin/injection_container.dart';

/// Kasir: pilih produk → keranjang → bayar. Keranjangnya di memori sampai
/// tombol Bayar ditekan; penyimpanannya satu transaksi atomik di repository.
///
/// `CartBloc` **tidak** dibuat di sini — providernya di `main.dart`, di atas
/// shell navigasi, supaya keranjang bertahan saat pemilik pindah tab di tengah
/// transaksi (ADR-048). Membuatnya di sini lagi berarti keranjang kosong setiap
/// kembali ke tab Kasir.
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) => const _CashierView();
}

class _CashierView extends StatefulWidget {
  const _CashierView();

  @override
  State<_CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<_CashierView> {
  final _search = TextEditingController();
  String _keyword = '';

  /// null = chip "Semua".
  int? _categoryId;

  /// Dibuat sekali supaya StreamBuilder tidak berlangganan ulang tiap build.
  late final Stream<List<ProductEntity>> _frequent;

  @override
  void initState() {
    super.initState();
    _frequent = sl<WatchFrequentProducts>()();
    context.read<ProductBloc>().add(const ProductEvent.subscriptionRequested());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Scanner dibuka dengan `BlocProvider.value` supaya memakai CartBloc yang
  /// sama — produk hasil scan langsung masuk keranjang ini.
  Future<void> _openScanner(BuildContext context) async {
    final cart = context.read<CartBloc>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cart,
          child: const BarcodeScannerScreen(),
        ),
      ),
    );
  }

  /// Kasir sekarang tab pertama, jadi tombol back di sini menutup aplikasi —
  /// dan keranjang hanya di memori. Konfirmasi ini mencegah 8 item hasil scan
  /// lenyap karena satu ketukan back.
  Future<bool> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tutup aplikasi?'),
        content: const Text('Keranjang yang belum dibayar akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Lanjut transaksi'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Keluar', style: TextStyle(color: AppColor.danger)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartBloc>().state;

    return PopScope(
      // Keranjang kosong: boleh langsung keluar. Terisi: tanya dulu.
      canPop: cart.items.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        // Tab pertama: tidak ada rute di bawahnya untuk di-pop, jadi
        // keluarnya lewat SystemNavigator.
        if (await _confirmExit(context)) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColor.bg,
        appBar: AppBar(
          title: Text(
            'Kasir',
            style: AppTextStyle.title.copyWith(color: AppColor.ink),
          ),
          // backgroundColor: AppColor.bg,
        ),
        body: SafeArea(
          child: Column(
            children: [
              SearchRow(
                controller: _search,
                onKeywordChanged: (value) => setState(() => _keyword = value),
                onScanPressed: () => _openScanner(context),
              ),
              _CategoryChips(
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s4,
                    bottom: AppSpacing.s6,
                  ),
                  children: [
                    if (cart.items.isNotEmpty) _CartSection(cart: cart),
                    _ProductSection(
                      keyword: _keyword,
                      categoryId: _categoryId,
                      frequent: _frequent,
                      onPicked: (product) => context.read<CartBloc>().add(
                        CartEvent.itemAdded(product),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // PayBar melayang di atas bottom nav, dan hanya ada kalau keranjang
        // terisi — tombol Bayar mati tidak berguna di layar sekecil ini.
        bottomNavigationBar: cart.items.isEmpty ? null : _PayBar(cart: cart),
      ),
    );
  }
}

// ================= CHIP KATEGORI =================

/// Kategori yang punya produk siap jual (aktif + stok ada). Kategori yang
/// semua produknya habis tidak ditampilkan: chip-nya hanya akan membuka daftar
/// kosong. Aturannya sama dengan layar Produk (ADR-038), bedanya di sini stok
/// ikut dihitung karena yang habis tidak bisa masuk keranjang.
List<CategoryEntity> categoriesWithSellableProducts(
  List<CategoryEntity> categories,
  List<ProductEntity> products,
) {
  final used = {
    for (final product in products)
      if (product.isActive && !product.isOutOfStock) product.categoryId,
  };
  return categories.where((c) => used.contains(c.id)).toList();
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selectedId, required this.onSelected});

  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) =>
          p.products != c.products || p.categories != c.categories,
      builder: (context, state) {
        final categories = categoriesWithSellableProducts(
          state.categories,
          state.products,
        );
        if (categories.isEmpty) return const SizedBox.shrink();

        // Pilihan bisa ikut hilang kalau produk terakhir di kategori itu habis;
        // jatuh kembali ke "Semua" supaya daftarnya tidak kosong tanpa sebab.
        final selected = categories.any((c) => c.id == selectedId)
            ? selectedId
            : null;

        return ChipRow(
          children: [
            AppChip(
              label: 'Semua',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories)
              AppChip(
                label: category.name,
                selected: selected == category.id,
                onTap: () => onSelected(category.id),
              ),
          ],
        );
      },
    );
  }
}

// ================= KERANJANG =================

class _CartSection extends StatelessWidget {
  const _CartSection({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Keranjang · ${cart.items.length} produk',
          trailing: TextButton(
            onPressed: () =>
                context.read<CartBloc>().add(const CartEvent.cleared()),
            child: const Text('Kosongkan'),
          ),
        ),
        AppCard(children: [for (final item in cart.items) _CartRow(item: item)]),
        const SizedBox(height: AppSpacing.s6),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    final id = item.product.id;

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.rowMin),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s3,
        AppSpacing.s2,
        AppSpacing.s2,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          AppAvatar(name: item.product.name),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.copyWith(color: AppColor.ink),
                ),
                Text(
                  formatRupiah(item.subtotal),
                  style: AppTextStyle.bodyStrong.copyWith(
                    color: AppColor.primary,
                  ),
                ),
                if (item.exceedsStock)
                  Text(
                    'Stok tinggal ${item.product.stock}',
                    style: AppTextStyle.label.copyWith(color: AppColor.danger),
                  ),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove,
            tooltip: 'Kurangi',
            onPressed: () => bloc.add(CartEvent.qtyChanged(id, item.qty - 1)),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyStrong.copyWith(color: AppColor.ink),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            tooltip: 'Tambah',
            onPressed: () => bloc.add(CartEvent.qtyChanged(id, item.qty + 1)),
          ),
        ],
      ),
    );
  }
}

/// 44×48: lebih kecil dari 48 lebar supaya dua tombol + angka muat di 390px,
/// tingginya tetap penuh sehingga area ketuknya masih 48px ke atas-bawah.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.smAll,
          child: SizedBox(
            width: 44,
            height: AppSpacing.tapMin,
            child: Icon(icon, size: 20, color: AppColor.ink),
          ),
        ),
      ),
    );
  }
}

// ================= DAFTAR PRODUK =================

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.keyword,
    required this.categoryId,
    required this.frequent,
    required this.onPicked,
  });

  final String keyword;
  final int? categoryId;
  final Stream<List<ProductEntity>> frequent;
  final ValueChanged<ProductEntity> onPicked;

  @override
  Widget build(BuildContext context) {
    final isFiltering = keyword.trim().isNotEmpty || categoryId != null;

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) =>
          p.products != c.products || p.categories != c.categories,
      builder: (context, state) {
        // Produk nonaktif dan stok habis tidak bisa dijual.
        final sellable = state.products
            .where((p) => p.isActive && !p.isOutOfStock)
            .toList();

        if (!isFiltering) {
          return StreamBuilder<List<ProductEntity>>(
            stream: frequent,
            builder: (context, snapshot) {
              final frequentProducts = snapshot.data ?? const [];
              // Toko baru belum punya riwayat penjualan, jadi daftar terlaris
              // kosong. Tanpa fallback ini kasir tidak punya apa pun untuk
              // diketuk sampai transaksi pertama selesai.
              if (frequentProducts.isEmpty) {
                return _ProductList(
                  title: 'Produk siap jual',
                  products: sellable,
                  onPicked: onPicked,
                  emptyMessage: 'Belum ada produk siap jual.',
                );
              }
              return _ProductList(
                title: 'Sering dibeli',
                products: frequentProducts,
                onPicked: onPicked,
                emptyMessage: 'Belum ada produk siap jual.',
              );
            },
          );
        }

        final needle = keyword.trim().toLowerCase();
        final filtered = sellable
            .where(
              (p) =>
                  (categoryId == null || p.categoryId == categoryId) &&
                  (needle.isEmpty ||
                      p.name.toLowerCase().contains(needle) ||
                      (p.barcode ?? '').toLowerCase().contains(needle)),
            )
            .toList();

        final category = state.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;

        return _ProductList(
          title: needle.isNotEmpty
              ? 'Hasil cari'
              : (category?.name ?? 'Produk siap jual'),
          products: filtered,
          onPicked: onPicked,
          emptyMessage: needle.isEmpty
              ? 'Tidak ada produk siap jual di kategori ini.'
              : 'Tidak ada produk cocok "$keyword".',
        );
      },
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.title,
    required this.products,
    required this.onPicked,
    required this.emptyMessage,
  });

  final String title;
  final List<ProductEntity> products;
  final ValueChanged<ProductEntity> onPicked;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Text(
              emptyMessage,
              style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
            ),
          )
        else
          AppCard(
            children: [
              for (final product in products)
                _ProductRow(product: product, onTap: () => onPicked(product)),
            ],
          ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                  Text(
                    'Stok ${product.stock}',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Text(
              formatRupiah(product.price),
              style: AppTextStyle.bodyStrong.copyWith(color: AppColor.ink),
            ),
            const SizedBox(width: AppSpacing.s2),
            Icon(Icons.add, color: AppColor.primary),
          ],
        ),
      ),
    );
  }
}

// ================= PAYBAR =================

class _PayBar extends StatelessWidget {
  const _PayBar({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        boxShadow: AppTheme.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  // Wajib min: Scaffold memberi bottomNavigationBar batas
                  // longgar setinggi layar, jadi Column max akan memakan
                  // seluruh layar dan body-nya jadi 0 px (ADR-051).
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total · ${cart.itemCount} pcs',
                      style: AppTextStyle.label.copyWith(
                        color: AppColor.inkMuted,
                      ),
                    ),
                    Text(
                      formatRupiah(cart.total),
                      style: AppTextStyle.amount.copyWith(color: AppColor.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              SizedBox(
                width: 148,
                height: AppSpacing.tapPrimary,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
                  ),
                  child: const Text('Bayar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
