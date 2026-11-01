import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/presentation/screens/receipt_preview_screen.dart';
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
  /// (PRD §2.4). PIN dulu, baru alasan, supaya orang yang tidak berhak tidak
  /// sempat mengetik apa pun.
  Future<void> _void() async {
    if (!await PinGate.require(
      context,
      reason: 'Diperlukan untuk void transaksi',
    )) {
      return;
    }
    if (!mounted) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _VoidReasonDialog(),
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
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
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
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: Text('Transaksi #${widget.transactionId}'),
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppSpacing.touchTargetMin,
                        child: OutlinedButton.icon(
                          onPressed: _reprint,
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Cetak ulang'),
                        ),
                      ),
                    ),
                    if (!receipt.isVoided) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.touchTargetMin,
                          child: ElevatedButton.icon(
                            onPressed: _voiding ? null : _void,
                            icon: const Icon(Icons.block),
                            label: Text(_voiding ? 'Memproses...' : 'Void'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.error,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (receipt.isVoided)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColor.errorContainer,
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              'Transaksi ini sudah di-void.'
              '${receipt.voidReason == null ? '' : '\nAlasan: ${receipt.voidReason}'}',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColor.onErrorContainer,
              ),
            ),
          ),
        Text(
          // Format angka, bukan nama bulan: nama bulan lokal butuh data locale
          // intl yang belum diinisialisasi di app ini.
          DateFormat('dd/MM/yyyy HH:mm').format(receipt.dateTime),
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColor.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final line in receipt.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: AppTextStyle.bodyLg.copyWith(
                          color: AppColor.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${line.qty} x ${formatRupiah(line.unitPrice)}',
                        style: AppTextStyle.labelSm.copyWith(
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(line.subtotal),
                  style: AppTextStyle.bodyLg.copyWith(
                    color: AppColor.onSurface,
                  ),
                ),
              ],
            ),
          ),
        const Divider(color: AppColor.divider),
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
        ? AppTextStyle.headlineMd.copyWith(
            color: AppColor.onSurface,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyle.bodyMd.copyWith(color: AppColor.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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

/// Alasan void wajib terisi, jadi tombolnya mati selama kolomnya kosong —
/// validasi di repository tetap ada sebagai jaring kedua.
class _VoidReasonDialog extends StatefulWidget {
  const _VoidReasonDialog();

  @override
  State<_VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<_VoidReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Alasan void'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Mis. salah input, barang dikembalikan',
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: filled
              ? () => Navigator.of(context).pop(_controller.text)
              : null,
          child: const Text('Void'),
        ),
      ],
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMd.copyWith(color: AppColor.error),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
