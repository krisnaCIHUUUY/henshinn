import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/receipt_formatter.dart';
import 'package:henshin/features/transaction/domain/services/printer_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Fallback cetak selama printer thermal belum ada (PRD §2.8 dan garis potong
/// §3.2). Memakai baris teks yang sama dengan preview, dirender dengan font
/// Courier bawaan PDF yang lebarnya seragam — jadi 32 karakter tetap lurus
/// tanpa perlu aset font.
class PdfPrinterService implements PrinterService {
  PdfPrinterService({
    ReceiptFormatter? formatter,
    Future<Directory> Function()? outputDirectory,
  }) : _formatter = formatter ?? const ReceiptFormatter(),
       // getTemporaryDirectory, BUKAN Directory.systemTemp: di Android
       // systemTemp menunjuk ke /tmp yang tidak ada dan tidak bisa ditulis
       // aplikasi, jadi penulisan file-nya gagal.
       _outputDirectory = outputDirectory ?? getTemporaryDirectory;

  final ReceiptFormatter _formatter;
  final Future<Directory> Function() _outputDirectory;

  @override
  String get label => 'Bagikan PDF';

  /// Dipisah dari [printReceipt] supaya bisa diuji tanpa share sheet.
  Future<List<int>> buildPdf(Receipt receipt) async {
    final document = pw.Document();

    document.addPage(
      pw.Page(
        // roll57 = rol 57mm, tinggi mengikuti isi
        pageFormat: PdfPageFormat.roll57,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (final line in _formatter.format(receipt))
              pw.Text(
                _toLatin1(line),
                style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9),
              ),
          ],
        ),
      ),
    );

    return document.save();
  }

  /// Courier hanya mendukung Latin-1. Nama produk dengan karakter di luar itu
  /// diganti '?' supaya PDF tetap terbentuk, bukan gagal atau tergambar kosong.
  /// shortcut: ganti dengan font Unicode sebagai aset kalau nanti ada katalog
  /// yang memakai karakter non-Latin.
  static String _toLatin1(String text) => String.fromCharCodes(
    text.codeUnits.map((unit) => unit <= 0xFF ? unit : 0x3F),
  );

  @override
  Future<Either<Failure, void>> printReceipt(Receipt receipt) async {
    try {
      final bytes = await buildPdf(receipt);
      final dir = await _outputDirectory();
      final file = File(p.join(dir.path, 'struk-${receipt.transactionId}.pdf'));
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Struk #${receipt.transactionId}',
        ),
      );
      return const Right(null);
    } catch (e, stackTrace) {
      // Ikut di-log supaya bisa diambil lewat `adb logcat -s flutter:*`;
      // pesan snackbar saja tidak pernah sampai ke log.
      debugPrint('[struk] gagal membagikan PDF: $e');
      debugPrint('$stackTrace');

      // Penjualan sudah tersimpan sebelum ini dipanggil (US-1.4), jadi
      // kegagalan di sini aman dilaporkan sebagai pesan saja.
      return Left(PrintFailure('Gagal membuat atau membagikan PDF: $e'));
    }
  }
}
