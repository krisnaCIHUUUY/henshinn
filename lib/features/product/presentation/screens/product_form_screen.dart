import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/usecases/find_or_create_category.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/injection_container.dart';

/// Tambah produk (`product == null`) atau ubah produk yang sudah ada.
/// Memakai `ProductBloc` dari ancestor — bukan instance baru — supaya list di
/// belakangnya ikut ter-update lewat stream yang sama.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product, this.initialBarcode});

  final ProductEntity? product;

  /// Mengisi field barcode untuk produk baru — dipakai saat scan menemukan
  /// barcode yang belum terdaftar.
  final String? initialBarcode;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// Nilai dropdown untuk opsi "+ Kategori baru". Bukan id di DB — id asli
/// selalu positif, jadi angka negatif tidak bisa bertabrakan dengan kategori.
const _newCategoryOption = -1;

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _costPrice;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;
  late final TextEditingController _newCategoryName;

  int? _categoryId;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(
      text: p?.barcode ?? widget.initialBarcode ?? '',
    );
    _price = TextEditingController(text: p == null ? '' : '${p.price}');
    _costPrice = TextEditingController(text: p == null ? '' : '${p.costPrice}');
    _stock = TextEditingController(text: p == null ? '0' : '${p.stock}');
    _threshold = TextEditingController(text: '${p?.lowStockThreshold ?? 5}');
    _newCategoryName = TextEditingController();
    _categoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;

    context.read<ProductBloc>().add(const ProductEvent.categoriesRequested());
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _barcode,
      _price,
      _costPrice,
      _stock,
      _threshold,
      _newCategoryName,
    ]) {
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

    final categoryId = await _resolveCategoryId();
    if (categoryId == null || !mounted) return;

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
            categoryId: categoryId,
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
            categoryId: categoryId,
          ),
        ),
      );
    }
  }

  /// Kategori baru dibuat di sini, bukan di layar sendiri: PRD §F2 menaruh
  /// kategori sebagai kolom produk, bukan entitas yang dikelola (ADR-038).
  /// `null` = gagal dan pesannya sudah tampil, jadi penyimpanan dibatalkan.
  ///
  /// Kalau produknya batal disimpan setelah ini, kategorinya tetap ada tapi
  /// kosong — dan tab kategori kosong tidak pernah ditampilkan, jadi tidak ada
  /// yang terlihat salah bagi pemilik.
  Future<int?> _resolveCategoryId() async {
    if (_categoryId != _newCategoryOption) return _categoryId;

    final result = await sl<FindOrCreateCategory>()(_newCategoryName.text);
    if (!mounted) return null;
    return result.fold((failure) {
      _showMessage(failure.message);
      return null;
    }, (id) => id);
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
        backgroundColor: AppColor.bg,
        appBar: AppBar(
          backgroundColor: AppColor.bg,
          title: Text(_isEdit ? 'Ubah produk' : 'Tambah produk'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s6),
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
                const SizedBox(height: AppSpacing.s2),
                _CategoryPicker(
                  value: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                if (_categoryId == _newCategoryOption) ...[
                  const SizedBox(height: AppSpacing.s4),
                  _Field(
                    controller: _newCategoryName,
                    label: 'Nama kategori baru',
                    helper: 'Dipakai sebagai tab di daftar produk',
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Nama kategori wajib diisi'
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                // Berdampingan supaya harga jual dan modal terbaca sebagai satu
                // keputusan, bukan dua angka terpisah: laba kotor di bawahnya
                // hanya punya arti kalau keduanya terlihat bersamaan.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _price,
                        label: 'Harga jual',
                        prefix: 'Rp ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: _requiredAmount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: _Field(
                        controller: _costPrice,
                        label: 'Harga modal',
                        prefix: 'Rp ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        validator: _requiredAmount,
                      ),
                    ),
                  ],
                ),
                _MarginNotice(
                  price: _intOf(_price),
                  costPrice: _intOf(_costPrice),
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _stock,
                        label: _isEdit ? 'Stok saat ini' : 'Stok awal',
                        // Saat ubah produk stok hanya tampilan: perubahan stok
                        // wajib lewat Restok/Koreksi supaya ledger tidak bolong.
                        readOnly: _isEdit,
                        helper: _isEdit ? 'Ubah lewat Restok/Koreksi' : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _requiredAmount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: _Field(
                        controller: _threshold,
                        label: 'Ingatkan jika sisa',
                        helper: 'Menipis saat stok segini',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _requiredAmount,
                      ),
                    ),
                  ],
                ),
                // PRD 1.6 diberitahukan di muka, bukan sebagai kejutan saat
                // simpan: sheet PIN yang muncul tanpa peringatan terbaca
                // seperti kerusakan.
                Text(
                  'Mengubah harga jual atau modal nanti perlu PIN pemilik.',
                  style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
                ),
                const SizedBox(height: AppSpacing.s2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: Text('Produk aktif', style: AppTextStyle.body),
                  subtitle: Text(
                    _isActive
                        ? 'Muncul di kasir'
                        : 'Disembunyikan dari kasir, riwayat tetap utuh',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
                  ),
                  activeThumbColor: AppColor.surface,
                  activeTrackColor: AppColor.ink,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
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
              // Tinggi dipatok SizedBox: slot bottomNavigationBar diberi batas
              // longgar setinggi layar oleh Scaffold (ADR-051).
              child: SizedBox(
                height: AppSpacing.tapPrimary,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan produk'),
                ),
              ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
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
          initialValue:
              value == _newCategoryOption ||
                  state.categories.any((c) => c.id == value)
              ? value
              : null,
          decoration: InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
          ),
          items: [
            for (final category in state.categories)
              DropdownMenuItem(value: category.id, child: Text(category.name)),
            const DropdownMenuItem(
              value: _newCategoryOption,
              child: Text('+ Kategori baru'),
            ),
          ],
          onChanged: onChanged,
          validator: (selected) => selected == null ? 'Pilih kategori' : null,
        );
      },
    );
  }
}

/// Baris laba kotor per pcs. Berlatar `primarySoft` karena ini satu-satunya
/// angka di form yang dihitung, bukan diisi — pemilik perlu melihatnya berubah
/// saat mengetik harga.
class _MarginNotice extends StatelessWidget {
  const _MarginNotice({required this.price, required this.costPrice});

  final int price;
  final int costPrice;

  @override
  Widget build(BuildContext context) {
    if (price == 0 && costPrice == 0) return const SizedBox.shrink();

    final margin = price - costPrice;
    final isLoss = margin < 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: isLoss ? AppColor.dangerSoft : AppColor.primarySoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isLoss ? 'Rugi per pcs' : 'Laba kotor per pcs',
              style: AppTextStyle.label.copyWith(
                color: isLoss ? AppColor.danger : AppColor.primary,
              ),
            ),
          ),
          Text(
            formatRupiah(isLoss ? -margin : margin),
            style: AppTextStyle.bodyStrong.copyWith(
              color: isLoss ? AppColor.danger : AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}
