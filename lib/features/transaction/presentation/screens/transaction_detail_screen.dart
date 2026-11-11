import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/presentation/screens/receipt_preview_screen.dart';
import 'package:henshin/features/transaction/presentation/widgets/void_sheet.dart';
import 'package:henshin/injection_container.dart';
import 'package:intl/intl.dart';

/// Detail satu transaksi: item dengan harga snapshot, total, dan aksi cetak
/// ulang + void (US-3.2, US-3.4).
///
/// Detailnya dibaca sebagai `Receipt` — model yang sama dengan struk — supaya
/// angka di layar ini tidak pernah beda dengan angka yang tercetak.
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Receipt? _receipt;
  String? _error;
  bool _voiding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // try/catch, bukan hanya fold: satu exception yang lolos membuat layar
    // macet di spinner tanpa pesan (lihat ADR-026).
    try {
      final result = await sl<TransactionRepository>().buildReceipt(
        widget.transactionId,
      );
      if (!mounted) return;
      result.fold(
        (failure) => setState(() => _error = failure.message),
        (receipt) => setState(() {
          _receipt = receipt;
          _error = null;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat transaksi: $e');
    }
  }

  void _reprint() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(
          transactionId: widget.transactionId,
          isReprint: true,
        ),
      ),
    );
  }

  /// Void wajib lewat PIN **dan** alasan: dua-duanya syarat audit pemilik
  /// (PRD §2.4). Keduanya sekarang di satu sheet bersama ringkasan dampaknya —
  /// pemilik melihat apa yang akan berubah sebelum menyetujui (ADR-054).
  Future<void> _void() async {
    final receipt = _receipt;
    if (receipt == null) return;

    final reason = await VoidSheet.show(
      context,
      transactionId: widget.transactionId,
      total: receipt.total,
      productCount: receipt.lines.length,
    );
    if (reason == null || !mounted) return;

    setState(() => _voiding = true);
    final result = await sl<TransactionRepository>().voidTransaction(
      widget.transactionId,
      reason,
    );
    if (!mounted) return;
    setState(() => _voiding = false);

    result.fold(
      (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi di-void, stok dikembalikan')),
        );
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        title: Text(
          'Transaksi #${widget.transactionId}',
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
      ),
      body: SafeArea(
        child: switch ((receipt, _error)) {
          (_, final String error) => _ErrorView(message: error, onRetry: _load),
          (null, _) => const Center(child: CircularProgressIndicator()),
          (final Receipt r, _) => _DetailBody(receipt: r),
        },
      ),
      bottomNavigationBar: receipt == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppSpacing.tapMin,
                        child: OutlinedButton.icon(
                          onPressed: _reprint,
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Cetak ulang'),
                        ),
                      ),
                    ),
                    if (!receipt.isVoided) ...[
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.tapMin,
                          child: ElevatedButton.icon(
                            onPressed: _voiding ? null : _void,
                            icon: const Icon(Icons.block),
                            label: Text(_voiding ? 'Memproses...' : 'Void'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.danger,
                              foregroundColor: AppColor.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdAll,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: [
        if (receipt.isVoided)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s4),
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: AppColor.dangerSoft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              'Transaksi ini sudah di-void.'
              '${receipt.voidReason == null ? '' : '\nAlasan: ${receipt.voidReason}'}',
              style: AppTextStyle.body.copyWith(color: AppColor.danger),
            ),
          ),
        Text(
          // Format angka, bukan nama bulan: nama bulan lokal butuh data locale
          // intl yang belum diinisialisasi di app ini.
          DateFormat('dd/MM/yyyy HH:mm').format(receipt.dateTime),
          style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
        ),
        const SizedBox(height: AppSpacing.s6),
        for (final line in receipt.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: AppTextStyle.bodyStrong.copyWith(
                          color: AppColor.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${line.qty} x ${formatRupiah(line.unitPrice)}',
                        style: AppTextStyle.label.copyWith(
                          color: AppColor.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(line.subtotal),
                  style: AppTextStyle.bodyStrong.copyWith(color: AppColor.ink),
                ),
              ],
            ),
          ),
        const Divider(color: AppColor.line),
        _TotalRow(label: 'Total', value: receipt.total, emphasized: true),
        _TotalRow(label: 'Bayar', value: receipt.paymentAmount),
        _TotalRow(label: 'Kembali', value: receipt.change),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyle.stat.copyWith(color: AppColor.ink)
        : AppTextStyle.body.copyWith(color: AppColor.inkMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatRupiah(value), style: style),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.body.copyWith(color: AppColor.danger),
            ),
            const SizedBox(height: AppSpacing.s4),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
