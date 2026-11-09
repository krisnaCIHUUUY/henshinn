import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/receipt_formatter.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/domain/services/printer_service.dart';
import 'package:henshin/injection_container.dart';

/// Preview struk dari transaksi yang **sudah tersimpan**. Dibuka setelah bayar
/// dan nanti dari riwayat untuk cetak ulang (US-3.4).
///
/// Preview merender baris teks yang sama dengan PDF dan nanti ESC/POS, jadi apa
/// yang dilihat kasir sama dengan yang tercetak (PRD §2.8).
class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({
    super.key,
    required this.transactionId,
    this.isReprint = false,
  });

  final int transactionId;
  final bool isReprint;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  static const _formatter = ReceiptFormatter();

  Receipt? _receipt;
  String? _error;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // try/catch wajib: tanpa ini satu exception membuat `_receipt` dan
    // `_error` tetap null, dan layar macet di spinner tanpa jalan keluar.
    try {
      final result = await sl<TransactionRepository>().buildReceipt(
        widget.transactionId,
        isReprint: widget.isReprint,
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
      setState(() => _error = 'Gagal memuat struk: $e');
    }
  }

  /// Transaksi sudah tersimpan sebelum layar ini terbuka (US-1.4), jadi gagal
  /// cetak hanya memunculkan pesan — tidak ada yang perlu dibatalkan.
  Future<void> _print() async {
    final receipt = _receipt;
    if (receipt == null) return;

    setState(() => _isPrinting = true);
    final result = await sl<PrinterService>().printReceipt(receipt);
    if (!mounted) return;
    setState(() => _isPrinting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      // Selesai dibagikan/dicetak: struk tidak ada gunanya lagi di layar, jadi
      // kembali ke kasir / detail transaksi. Catatan: di Android share_plus
      // tidak bisa diandalkan membedakan "dibagikan" dari "share sheet
      // ditutup", jadi menutup sheet juga menutup layar ini.
      (_) => Navigator.of(context).pop(),
    );
  }

  void _copyText() {
    final receipt = _receipt;
    if (receipt == null) return;

    Clipboard.setData(
      ClipboardData(text: _formatter.formatAsText(receipt)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teks struk disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        title: Text(widget.isReprint ? 'Cetak Ulang Struk' : 'Struk'),
        actions: [
          if (receipt != null)
            IconButton(
              tooltip: 'Salin teks struk',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: _copyText,
            ),
        ],
      ),
      body: SafeArea(
        child: switch ((receipt, _error)) {
          (_, final String error) => _ErrorView(message: error, onRetry: _load),
          (null, _) => const Center(child: CircularProgressIndicator()),
          (final Receipt r, _) => _ReceiptBody(
            lines: _formatter.format(r),
            isVoided: r.isVoided,
          ),
        },
      ),
      bottomNavigationBar: receipt == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: SizedBox(
                  height: AppSpacing.tapMin,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _print,
                    icon: const Icon(Icons.ios_share),
                    label: Text(
                      _isPrinting
                          ? 'Menyiapkan...'
                          : sl<PrinterService>().label,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.ink,
                      foregroundColor: AppColor.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Kertas struk ditampilkan apa adanya dengan font monospace supaya kolomnya
/// lurus persis seperti hasil cetak.
class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.lines, required this.isVoided});

  final List<String> lines;
  final bool isVoided;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isVoided ? AppColor.danger : AppColor.line,
            ),
          ),
          child: Text(
            lines.join('\n'),
            style: AppTextStyle.receipt.copyWith(color: AppColor.ink),
          ),
        ),
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
