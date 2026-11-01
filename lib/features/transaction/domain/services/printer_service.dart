import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';

/// Di balik interface ini ada dua implementasi: PDF/share (sekarang) dan
/// ESC/POS Bluetooth (saat printer tiba, PRD §3.4 spike 1 hari).
///
/// **US-1.4:** transaksi harus tetap tersimpan walau cetak gagal. Karena itu
/// tidak ada method di sini yang menulis ke database — pemanggil menyimpan
/// transaksi lebih dulu, lalu mencetak. Kegagalan cetak hanya dilaporkan
/// sebagai `Left`, tidak pernah membatalkan penjualan.
abstract class PrinterService {
  /// Nama yang ditampilkan di tombol, mis. "Bagikan PDF" atau "Cetak".
  String get label;

  Future<Either<Failure, void>> printReceipt(Receipt receipt);
}
