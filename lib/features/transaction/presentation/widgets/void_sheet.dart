import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/widgets/app_chip.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_bloc.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_event.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_state.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/features/setting/presentation/widgets/pin_pad.dart';
import 'package:henshin/injection_container.dart';

/// Tiga alasan baku. `Lainnya` tetap membuka kolom teks: `voidReason` wajib
/// terisi dan alasan di luar tiga ini harus tetap bisa dicatat.
const _reasonOptions = ['Salah input', 'Pembeli batal'];

/// Satu sheet untuk seluruh void: ringkasan dampak, alasan, dan PIN.
///
/// Sebelumnya dua langkah terpisah (sheet PIN dulu, lalu dialog alasan). Void
/// mengubah stok dan uang, jadi pemilik harus melihat dampaknya, alasannya, dan
/// gerbang PIN-nya dalam satu tampilan — bukan menyetujui PIN untuk sesuatu yang
/// baru dijelaskan di layar berikutnya (ADR-054).
///
/// Pop alasan yang dipilih **hanya** kalau PIN-nya benar; `null` berarti batal.
/// Yang mengerjakan void tetap pemanggilnya: repository sudah menolak alasan
/// kosong dan transaksi yang sudah void, dan di sanalah pesan hasilnya tampil.
class VoidSheet extends StatelessWidget {
  const VoidSheet({
    super.key,
    required this.transactionId,
    required this.total,
    required this.productCount,
  });

  final int transactionId;
  final int total;

  /// Banyak baris produk yang stoknya akan dikembalikan.
  final int productCount;

  /// `null` kalau batal atau PIN belum pernah dibuat.
  static Future<String?> show(
    BuildContext context, {
    required int transactionId,
    required int total,
    required int productCount,
  }) async {
    if (!await PinGate.hasPinOrWarn(context)) return null;
    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VoidSheet(
        transactionId: transactionId,
        total: total,
        productCount: productCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PinBloc>()..add(const PinEvent.statusRequested()),
      child: _VoidView(
        transactionId: transactionId,
        total: total,
        productCount: productCount,
      ),
    );
  }
}

class _VoidView extends StatefulWidget {
  const _VoidView({
    required this.transactionId,
    required this.total,
    required this.productCount,
  });

  final int transactionId;
  final int total;
  final int productCount;

  @override
  State<_VoidView> createState() => _VoidViewState();
}

class _VoidViewState extends State<_VoidView> {
  static const _length = PinRepository.pinLength;

  /// null = belum ada chip yang dipilih. String kosong = chip "Lainnya".
  String? _reason;
  final _otherReason = TextEditingController();

  String _input = '';
  Timer? _unlockTimer;

  bool get _isOther => _reason != null && _reason!.isEmpty;

  /// Alasan yang akan dikirim. Kosong berarti belum sah.
  String get _resolvedReason =>
      _isOther ? _otherReason.text.trim() : (_reason ?? '');

  @override
  void dispose() {
    _unlockTimer?.cancel();
    _otherReason.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_input.length >= _length) return;
    // Sengaja tidak auto-submit saat angka ke-6: tombol "Void transaksi" yang
    // memicu, supaya alasan tidak bisa terlewat dan pemilik masih bisa batal
    // setelah mengetik PIN.
    setState(() => _input += digit);
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _scheduleUnlock(Duration remaining) {
    _unlockTimer?.cancel();
    _unlockTimer = Timer(remaining, () {
      if (mounted) {
        context.read<PinBloc>().add(const PinEvent.statusRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinBloc, PinState>(
      listener: (context, state) {
        switch (state.status) {
          // PIN benar: sheet tutup membawa alasannya, pemanggil yang mem-void.
          case PinStatus.success:
            Navigator.of(context).pop(_resolvedReason);
          case PinStatus.wrong:
          case PinStatus.failure:
            setState(() => _input = '');
          case PinStatus.locked:
            setState(() => _input = '');
            final remaining = state.lockedFor;
            if (remaining != null) _scheduleUnlock(remaining);
          case PinStatus.initial:
          case PinStatus.loading:
            break;
        }
      },
      builder: (context, state) {
        final isLocked = state.status == PinStatus.locked;
        final isBusy = state.status == PinStatus.loading;
        final canVoid =
            _resolvedReason.isNotEmpty &&
            _input.length == _length &&
            !isLocked &&
            !isBusy;

        return PopScope(
          // Sedang memverifikasi: back tidak boleh membatalkan di tengah jalan,
          // karena hitungan salah sudah tercatat.
          canPop: !isBusy,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s2,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColor.line,
                          borderRadius: AppRadius.fullAll,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Void transaksi #${widget.transactionId}',
                      style: AppTextStyle.heading.copyWith(
                        color: AppColor.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      '${formatRupiah(widget.total)} · stok '
                      '${widget.productCount} produk dikembalikan. '
                      'Transaksi tetap tercatat di riwayat.',
                      style: AppTextStyle.label.copyWith(
                        color: AppColor.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Alasan',
                      style: AppTextStyle.label.copyWith(color: AppColor.ink),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: [
                        for (final option in _reasonOptions)
                          AppChip(
                            label: option,
                            selected: _reason == option,
                            onTap: () => setState(() => _reason = option),
                          ),
                        AppChip(
                          label: 'Lainnya',
                          selected: _isOther,
                          onTap: () => setState(() => _reason = ''),
                        ),
                      ],
                    ),
                    if (_isOther) ...[
                      const SizedBox(height: AppSpacing.s3),
                      TextField(
                        controller: _otherReason,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Tulis alasannya',
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s4),
                    PinPad(
                      title: 'PIN pemilik',
                      subtitle: 'Void hanya bisa dilakukan pemilik',
                      filled: _input.length,
                      errorText: state.errorMessage.isEmpty
                          ? null
                          : state.errorMessage,
                      enabled: !isLocked && !isBusy,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppSpacing.tapPrimary,
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(
                          child: SizedBox(
                            height: AppSpacing.tapPrimary,
                            child: ElevatedButton(
                              onPressed: canVoid
                                  ? () => context.read<PinBloc>().add(
                                      PinEvent.submitted(_input),
                                    )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.danger,
                                foregroundColor: AppColor.onPrimary,
                              ),
                              child: Text(
                                isBusy ? 'Memproses...' : 'Void transaksi',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
