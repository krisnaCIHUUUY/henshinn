import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';

enum StockSheetMode {
  /// Barang masuk: stok ditambah sebanyak yang diisi.
  restock,

  /// Koreksi: stok diset ke hasil hitung fisik.
  adjust,
}

/// Satu sheet untuk restok dan koreksi — bedanya hanya label dan event yang
/// dikirim. Keduanya menulis baris `stock_movements` di repository.
class StockSheet extends StatefulWidget {
  const StockSheet({
    super.key,
    required this.product,
    required this.mode,
  });

  final ProductEntity product;
  final StockSheetMode mode;

  static Future<void> show(
    BuildContext context, {
    required ProductEntity product,
    required StockSheetMode mode,
  }) {
    final bloc = context.read<ProductBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: StockSheet(product: product, mode: mode),
      ),
    );
  }

  @override
  State<StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<StockSheet> {
  final _qty = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  bool get _isRestock => widget.mode == StockSheetMode.restock;

  @override
  void initState() {
    super.initState();
    if (!_isRestock) _qty.text = '${widget.product.stock}';
  }

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_qty.text.trim());
    if (value == null) {
      setState(() => _error = 'Isi angka dulu');
      return;
    }
    if (_isRestock && value <= 0) {
      setState(() => _error = 'Jumlah masuk harus lebih dari 0');
      return;
    }
    if (!_isRestock && value < 0) {
      setState(() => _error = 'Stok tidak boleh negatif');
      return;
    }

    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    context.read<ProductBloc>().add(
      _isRestock
          ? ProductEvent.restocked(widget.product.id, value, note: note)
          : ProductEvent.stockAdjusted(widget.product.id, value, note: note),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    final preview = _isRestock
        ? widget.product.stock + qty
        : qty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRestock ? 'Restok' : 'Koreksi Stok',
            style: AppTextStyle.headlineLg.copyWith(color: AppColor.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.product.name} · stok sekarang ${widget.product.stock}',
            style: AppTextStyle.bodyMd.copyWith(color: AppColor.outline),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _qty,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: _isRestock ? 'Jumlah masuk' : 'Stok hasil hitung',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isRestock
                ? 'Stok jadi $preview'
                : 'Selisih ${preview - widget.product.stock} dari stok sekarang',
            style: AppTextStyle.labelSm.copyWith(color: AppColor.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              helperText: _isRestock
                  ? 'Mis. nama supplier atau nomor nota'
                  : 'Mis. alasan selisih stok',
              border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.touchTargetMin,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.onSurface,
                foregroundColor: AppColor.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              child: Text(_isRestock ? 'Simpan restok' : 'Simpan koreksi'),
            ),
          ),
        ],
      ),
    );
  }
}
