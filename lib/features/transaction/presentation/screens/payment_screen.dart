import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';
import 'package:henshin/features/transaction/presentation/screens/receipt_preview_screen.dart';

/// Nominal tombol cepat untuk uang diterima.
///
/// Selalu dimulai dengan "Uang pas" (tepat sebesar total), lalu pecahan yang
/// **lebih besar** dari total. Pecahan yang lebih kecil sengaja tidak
/// ditampilkan: menekannya hanya menghasilkan "Masih kurang".
List<int> quickCashOptions(int total) => [
  total,
  for (final nominal in const [25000, 50000, 100000])
    if (nominal > total) nominal,
];

/// Layar bayar. Dipisah dari Kasir di D5 supaya Kasir muat untuk keranjang dan
/// PayBar; `CartBloc`-nya sama, providernya di `main.dart`.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cash = TextEditingController();

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  void _setCash(int amount) {
    // shortcut: isi field tanpa pemisah ribuan — pengelompokan saat mengetik
    // butuh TextInputFormatter sendiri. Naikkan kalau pemilik mengeluh.
    _cash.text = '$amount';
    context.read<CartBloc>().add(CartEvent.paymentChanged(amount));
  }

  /// Transaksi sudah tersimpan saat sampai sini (US-1.4), jadi struk menggantikan
  /// layar bayar: menutup struk mengembalikan kasir ke keranjang yang kosong,
  /// bukan ke layar bayar transaksi yang sudah selesai.
  Future<void> _onCheckedOut(BuildContext context, CartState state) async {
    if (state.status == CartStatus.failure) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.errorMessage)));
      return;
    }
    if (state.status != CartStatus.saved) return;

    final transactionId = state.lastTransactionId;
    if (transactionId == null) return;

    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(transactionId: transactionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SafeArea(
        child: BlocConsumer<CartBloc, CartState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: _onCheckedOut,
          builder: (context, cart) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s6,
              ),
              children: [
                _TotalCard(cart: cart),
                const SizedBox(height: AppSpacing.s6),
                _CashField(controller: _cash, onChanged: _setCash),
                const SizedBox(height: AppSpacing.s2),
                _QuickCash(
                  total: cart.total,
                  selected: cart.paymentAmount,
                  onPick: _setCash,
                ),
                const SizedBox(height: AppSpacing.s6),
                _ChangeCard(cart: cart),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  'Rincian',
                  style: AppTextStyle.heading.copyWith(color: AppColor.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                _Lines(cart: cart),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cart) => _FinishBar(cart: cart),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColor.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total belanja · ${cart.items.length} produk, '
            '${cart.itemCount} pcs',
            style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            formatRupiah(cart.total),
            style: AppTextStyle.amount.copyWith(color: AppColor.ink),
          ),
        ],
      ),
    );
  }
}

class _CashField extends StatelessWidget {
  const _CashField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) => onChanged(parseRupiah(value) ?? 0),
      style: AppTextStyle.stat.copyWith(color: AppColor.ink),
      decoration: InputDecoration(
        labelText: 'Uang diterima (tunai)',
        prefixText: 'Rp ',
        prefixStyle: AppTextStyle.heading.copyWith(color: AppColor.inkMuted),
      ),
    );
  }
}

class _QuickCash extends StatelessWidget {
  const _QuickCash({
    required this.total,
    required this.selected,
    required this.onPick,
  });

  final int total;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final options = quickCashOptions(total);

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: _QuickButton(
              label: i == 0
                  ? 'Uang pas'
                  : formatRupiah(options[i]).replaceFirst('Rp ', ''),
              selected: selected == options[i],
              onTap: () => onPick(options[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primarySoft : AppColor.surface,
      borderRadius: AppRadius.fullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fullAll,
        child: Container(
          height: AppSpacing.tapMin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.fullAll,
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.lineStrong,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.label.copyWith(
              color: selected ? AppColor.primary : AppColor.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final isShort = cart.change < 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: isShort ? AppColor.dangerSoft : AppColor.successSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isShort ? 'Masih kurang' : 'Kembalian',
            style: AppTextStyle.bodyStrong.copyWith(
              color: isShort ? AppColor.danger : AppColor.success,
            ),
          ),
          Text(
            formatRupiah(cart.change.abs()),
            style: AppTextStyle.stat.copyWith(
              color: isShort ? AppColor.danger : AppColor.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColor.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < cart.items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.items[i].product.name,
                          style: AppTextStyle.body.copyWith(
                            color: AppColor.ink,
                          ),
                        ),
                        Text(
                          '${cart.items[i].qty} × '
                          '${formatRupiah(cart.items[i].product.price)}',
                          style: AppTextStyle.label.copyWith(
                            color: AppColor.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    formatRupiah(cart.items[i].subtotal),
                    style: AppTextStyle.bodyStrong.copyWith(
                      color: AppColor.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinishBar extends StatelessWidget {
  const _FinishBar({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final isSaving = cart.status == CartStatus.saving;

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        boxShadow: AppTheme.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: SizedBox(
            height: AppSpacing.tapPrimary,
            child: ElevatedButton(
              onPressed: cart.canCheckout
                  ? () => context.read<CartBloc>().add(
                      const CartEvent.checkedOut(),
                    )
                  : null,
              child: Text(isSaving ? 'Menyimpan...' : 'Selesaikan transaksi'),
            ),
          ),
        ),
      ),
    );
  }
}
