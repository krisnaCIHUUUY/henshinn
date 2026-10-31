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
import 'package:henshin/features/setting/presentation/pin_gate.dart';

/// Tambah produk (`product == null`) atau ubah produk yang sudah ada.
/// Memakai `ProductBloc` dari ancestor — bukan instance baru — supaya list di
/// belakangnya ikut ter-update lewat stream yang sama.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductEntity? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _costPrice;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;

  int? _categoryId;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _price = TextEditingController(text: p == null ? '' : '${p.price}');
    _costPrice = TextEditingController(text: p == null ? '' : '${p.costPrice}');
    _stock = TextEditingController(text: p == null ? '0' : '${p.stock}');
    _threshold = TextEditingController(text: '${p?.lowStockThreshold ?? 5}');
    _categoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;

    context.read<ProductBloc>().add(const ProductEvent.categoriesRequested());
  }

  @override
  void dispose() {
    for (final c in [_name, _barcode, _price, _costPrice, _stock, _threshold]) {
      c.dispose();
    }
    super.dispose();
  }

  int _intOf(TextEditingController c, {int fallback = 0}) =>
      parseRupiah(c.text) ?? fallback;

  /// PRD §1.6: ubah harga jual atau harga modal pada produk yang sudah ada
  /// wajib PIN. Produk baru tidak digate — belum ada harga yang diubah.
  bool get _needsPin {
    final p = widget.product;
    if (p == null) return false;
    return _intOf(_price) != p.price || _intOf(_costPrice) != p.costPrice;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_needsPin) {
      final allowed = await PinGate.require(
        context,
        reason: 'Diperlukan untuk mengubah harga atau modal produk',
      );
      if (!allowed) return;
    }
    if (!mounted) return;

    setState(() => _saving = true);

    final bloc = context.read<ProductBloc>();
    if (_isEdit) {
      bloc.add(
        ProductEvent.updated(
          widget.product!.copyWith(
            name: _name.text,
            barcode: _barcode.text,
            price: _intOf(_price),
            costPrice: _intOf(_costPrice),
            stock: _intOf(_stock),
            lowStockThreshold: _intOf(_threshold, fallback: 5),
            isActive: _isActive,
            categoryId: _categoryId,
          ),
        ),
      );
    } else {
      bloc.add(
        ProductEvent.added(
          NewProduct(
            name: _name.text,
            barcode: _barcode.text,
            price: _intOf(_price),
            costPrice: _intOf(_costPrice),
            stock: _intOf(_stock),
            lowStockThreshold: _intOf(_threshold, fallback: 5),
            isActive: _isActive,
            categoryId: _categoryId!,
          ),
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (previous, current) =>
          _saving && previous.writeCount != current.writeCount,
      listener: (context, state) {
        if (state.status == ProductStatus.failure) {
          setState(() => _saving = false);
          _showMessage(state.errorMessage);
        } else if (state.status == ProductStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.surface,
        appBar: AppBar(
          backgroundColor: AppColor.surface,
          title: Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _Field(
                  controller: _name,
                  label: 'Nama produk',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Nama produk wajib diisi'
                      : null,
                ),
                _Field(
                  controller: _barcode,
                  label: 'Barcode (opsional)',
                  helper: 'Kosongkan kalau produk tidak punya barcode',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CategoryPicker(
                  value: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Field(
                  controller: _price,
                  label: 'Harga jual',
                  prefix: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: _requiredAmount,
                ),
                _Field(
                  controller: _costPrice,
                  label: 'Harga modal',
                  prefix: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: _requiredAmount,
                ),
                _MarginHint(
                  price: _intOf(_price),
                  costPrice: _intOf(_costPrice),
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(
                  controller: _stock,
                  label: _isEdit ? 'Stok saat ini' : 'Stok awal',
                  // Saat ubah produk stok hanya tampilan: perubahan stok wajib
                  // lewat Restok/Koreksi supaya ledger tidak bolong.
                  readOnly: _isEdit,
                  helper: _isEdit
                      ? 'Ubah lewat Restok atau Koreksi Stok di daftar produk'
                      : null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _requiredAmount,
                ),
                _Field(
                  controller: _threshold,
                  label: 'Batas stok menipis',
                  helper: 'Produk ditandai menipis saat stok <= angka ini',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _requiredAmount,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: Text('Produk aktif', style: AppTextStyle.bodyMd),
                  subtitle: Text(
                    _isActive
                        ? 'Muncul di kasir'
                        : 'Disembunyikan dari kasir, riwayat tetap utuh',
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.outline,
                    ),
                  ),
                  activeThumbColor: AppColor.surfaceContainerLowest,
                  activeTrackColor: AppColor.onSurface,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: AppSpacing.touchTargetMin,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.onSurface,
                      foregroundColor: AppColor.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll,
                      ),
                    ),
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredAmount(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Wajib diisi';
    // Nilai negatif tidak mungkin: input sudah dibatasi digitsOnly.
    return parseRupiah(value!) == null ? 'Angka tidak valid' : null;
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.helper,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        validator: validator,
        onChanged: onChanged,
        readOnly: readOnly,
        decoration: InputDecoration(
          filled: readOnly,
          labelText: label,
          helperText: helper,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories,
      builder: (context, state) {
        return DropdownButtonFormField<int>(
          initialValue: state.categories.any((c) => c.id == value)
              ? value
              : null,
          decoration: InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
          ),
          items: [
            for (final category in state.categories)
              DropdownMenuItem(value: category.id, child: Text(category.name)),
          ],
          onChanged: onChanged,
          validator: (selected) => selected == null ? 'Pilih kategori' : null,
        );
      },
    );
  }
}

class _MarginHint extends StatelessWidget {
  const _MarginHint({required this.price, required this.costPrice});

  final int price;
  final int costPrice;

  @override
  Widget build(BuildContext context) {
    if (price == 0 && costPrice == 0) return const SizedBox.shrink();

    final margin = price - costPrice;
    final isLoss = margin < 0;

    return Text(
      isLoss
          ? 'Rugi ${formatRupiah(-margin)} per unit — modal lebih besar dari harga jual'
          : 'Laba ${formatRupiah(margin)} per unit',
      style: AppTextStyle.labelSm.copyWith(
        color: isLoss ? AppColor.error : AppColor.outline,
      ),
    );
  }
}
