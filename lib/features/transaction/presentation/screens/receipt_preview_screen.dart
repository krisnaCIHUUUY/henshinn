import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
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
      (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message))),
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

    Clipboard.setData(ClipboardData(text: _formatter.formatAsText(receipt)));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Teks struk disalin')));
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
            receipt: r,
            lines: _formatter.format(r),
          ),
        },
      ),
      bottomNavigationBar: receipt == null
          ? null
          : Container(
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
                  child: Column(
                    // Lihat ADR-051: Column di bottomNavigationBar harus min,
                    // kalau tidak barisnya memenuhi layar.
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.tapMin,
                        child: OutlinedButton.icon(
                          onPressed: _isPrinting ? null : _print,
                          icon: const Icon(Icons.ios_share),
                          label: Text(
                            _isPrinting
                                ? 'Menyiapkan...'
                                : sl<PrinterService>().label,
                          ),
                        ),
                      ),
                      // Hanya di struk transaksi baru: dari cetak ulang di
                      // riwayat, "Transaksi baru" tidak ada artinya.
                      if (!widget.isReprint) ...[
                        const SizedBox(height: AppSpacing.s2),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.tapPrimary,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Transaksi baru'),
                          ),
                        ),
                      ],
                    ],
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
  const _ReceiptBody({required this.receipt, required this.lines});

  final Receipt receipt;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final isVoided = receipt.isVoided;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        children: [
          // Notice hijau: satu-satunya tempat kasir diberi tahu bahwa
          // transaksinya benar-benar tersimpan dan stok sudah dikurangi.
          if (!isVoided && !receipt.isReprint) ...[
            _SuccessNotice(change: receipt.change),
            const SizedBox(height: AppSpacing.s4),
          ],
          Container(
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
        ],
      ),
    );
  }
}

class _SuccessNotice extends StatelessWidget {
  const _SuccessNotice({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColor.successSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColor.success),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaksi selesai',
                  style: AppTextStyle.bodyStrong.copyWith(
                    color: AppColor.success,
                  ),
                ),
                Text(
                  'Kembalian ${formatRupiah(change)} · stok sudah dikurangi',
                  style: AppTextStyle.label.copyWith(color: AppColor.success),
                ),
              ],
            ),
          ),
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
