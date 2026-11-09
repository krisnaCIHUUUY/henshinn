import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/transaction/domain/entities/cart_item.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';
import 'package:henshin/features/transaction/presentation/screens/barcode_scanner_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/receipt_preview_screen.dart';
import 'package:henshin/injection_container.dart';

/// Kasir: pilih produk → keranjang → bayar. Keranjangnya di memori sampai
/// tombol Bayar ditekan; penyimpanannya satu transaksi atomik di repository.
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CartBloc>(),
      child: const _CashierView(),
    );
  }
}

class _CashierView extends StatefulWidget {
  const _CashierView();

  @override
  State<_CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<_CashierView> {
  final _search = TextEditingController();
  final _payment = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(
      const ProductEvent.subscriptionRequested(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _payment.dispose();
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

  /// Keranjang hanya di memori, jadi keluar berarti isinya hilang. Konfirmasi
  /// ini mencegah 8 item hasil scan lenyap karena satu ketukan back.
  Future<bool> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari kasir?'),
        content: const Text('Keranjang yang belum dibayar akan dikosongkan.'),
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

  Future<void> _onPaid(BuildContext context, CartState state) async {
    if (state.status == CartStatus.failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
      return;
    }
    if (state.status != CartStatus.saved) return;

    final transactionId = state.lastTransactionId;
    _payment.clear();

    // Transaksi sudah tersimpan; struk hanya tampilan di atasnya. Kalau kasir
    // menutupnya tanpa mencetak, penjualannya tetap utuh (US-1.4).
    if (transactionId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(transactionId: transactionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartBloc>().state;

    return PopScope(
      // Keranjang kosong: boleh langsung keluar. Terisi: tanya dulu.
      canPop: cart.items.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        if (await _confirmExit(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        title: const Text('Kasir'),
        leading: IconButton(
          tooltip: 'Kembali ke dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openScanner(context),
          ),
          BlocBuilder<CartBloc, CartState>(
            buildWhen: (p, c) => p.items.isEmpty != c.items.isEmpty,
            builder: (context, state) => state.items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Kosongkan keranjang',
                    icon: const Icon(Icons.remove_shopping_cart_outlined),
                    onPressed: () =>
                        context.read<CartBloc>().add(const CartEvent.cleared()),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<CartBloc, CartState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: _onPaid,
          builder: (context, cart) {
            return Column(
              children: [
                _ProductPicker(
                  onScanPressed: () => _openScanner(context),
                  controller: _search,
                  keyword: _keyword,
                  onKeywordChanged: (value) =>
                      setState(() => _keyword = value),
                  onPicked: (product) => context.read<CartBloc>().add(
                    CartEvent.itemAdded(product),
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _CartList(cart: cart)),
                _PaymentPanel(cart: cart, controller: _payment),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================= PEMILIH PRODUK =================

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.controller,
    required this.keyword,
    required this.onKeywordChanged,
    required this.onPicked,
    required this.onScanPressed,
  });

  final VoidCallback onScanPressed;
  final TextEditingController controller;
  final String keyword;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<ProductEntity> onPicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onKeywordChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari produk',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              SizedBox(
                height: AppSpacing.tapMin,
                child: FilledButton.icon(
                  onPressed: onScanPressed,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (p, c) => p.products != c.products,
            builder: (context, state) {
              // Produk nonaktif dan stok habis tidak bisa dijual.
              final available = state.products
                  .where(
                    (p) =>
                        p.isActive &&
                        !p.isOutOfStock &&
                        p.name.toLowerCase().contains(keyword.toLowerCase()),
                  )
                  .toList();

              if (available.isEmpty) {
                return Text(
                  keyword.isEmpty
                      ? 'Belum ada produk siap jual.'
                      : 'Tidak ada produk cocok "$keyword".',
                  style: AppTextStyle.label.copyWith(
                    color: AppColor.inkMuted,
                  ),
                );
              }

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: available.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s2),
                  itemBuilder: (context, index) {
                    final product = available[index];
                    return ActionChip(
                      label: Text(
                        '${product.name} · ${formatRupiah(product.price)}',
                      ),
                      onPressed: () => onPicked(product),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================= KERANJANG =================

class _CartList extends StatelessWidget {
  const _CartList({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Text(
            'Keranjang kosong.\nPilih produk di atas untuk mulai.',
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _CartRow(item: cart.items[index]),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColor.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRupiah(item.product.price)} × ${item.qty}',
                  style: AppTextStyle.label.copyWith(
                    color: AppColor.inkMuted,
                  ),
                ),
                if (item.exceedsStock)
                  Text(
                    'Stok tinggal ${item.product.stock}',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.danger,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kurangi',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                bloc.add(CartEvent.qtyChanged(id, item.qty - 1)),
          ),
          Text('${item.qty}', style: AppTextStyle.body),
          IconButton(
            tooltip: 'Tambah',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                bloc.add(CartEvent.qtyChanged(id, item.qty + 1)),
          ),
          SizedBox(
            width: 92,
            child: Text(
              formatRupiah(item.subtotal),
              textAlign: TextAlign.right,
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColor.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: Icon(Icons.close, color: AppColor.inkMuted),
            onPressed: () => bloc.add(CartEvent.itemRemoved(id)),
          ),
        ],
      ),
    );
  }
}

// ================= BAYAR =================

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.cart, required this.controller});

  final CartState cart;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isSaving = cart.status == CartStatus.saving;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s4,
        AppSpacing.s6,
        AppSpacing.s4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.line)),
      ),
      child: Column(
        children: [
          _Line(
            label: 'Total (${cart.itemCount} item)',
            value: formatRupiah(cart.total),
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.s2),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => context.read<CartBloc>().add(
              CartEvent.paymentChanged(parseRupiah(value) ?? 0),
            ),
            decoration: InputDecoration(
              labelText: 'Uang diterima',
              prefixText: 'Rp ',
              isDense: true,
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          _Line(
            label: cart.change < 0 ? 'Masih kurang' : 'Kembalian',
            value: formatRupiah(cart.change.abs()),
            isError: cart.change < 0,
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.tapMin,
            child: ElevatedButton(
              onPressed: cart.canCheckout
                  ? () => context.read<CartBloc>().add(
                      const CartEvent.checkedOut(),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.ink,
                foregroundColor: AppColor.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              child: Text(isSaving ? 'Menyimpan...' : 'Bayar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isError = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? AppTextStyle.stat.copyWith(color: AppColor.ink)
        : AppTextStyle.body.copyWith(
            color: isError ? AppColor.danger : AppColor.ink,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyle.body.copyWith(
            color: isError ? AppColor.danger : AppColor.inkMuted,
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}
