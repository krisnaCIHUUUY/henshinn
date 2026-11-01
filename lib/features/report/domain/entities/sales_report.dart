import 'package:equatable/equatable.dart';

/// Preset laporan. Rentang bebas sengaja tidak ada: itu garis potong PRD §3.2
/// supaya MVP selesai 8 minggu.
enum ReportPeriod {
  hariIni('Hari ini', 1),
  tujuhHari('7 hari', 7),
  tigaPuluhHari('30 hari', 30);

  const ReportPeriod(this.label, this.days);

  final String label;
  final int days;

  /// Rentang periode dalam waktu **lokal**: dari tengah malam hari pertama
  /// sampai akhir hari ini. Pemilik menghitung "hari ini" sebagai satu hari
  /// kalender, bukan 24 jam ke belakang.
  (DateTime start, DateTime end) rangeFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (
      today.subtract(Duration(days: days - 1)),
      today.add(const Duration(days: 1)).subtract(
        const Duration(microseconds: 1),
      ),
    );
  }
}

class BestSeller extends Equatable {
  const BestSeller({required this.name, required this.qtySold});

  final String name;
  final int qtySold;

  @override
  List<Object?> get props => [name, qtySold];
}

class DailyRevenue extends Equatable {
  const DailyRevenue({required this.date, required this.revenue});

  final DateTime date;
  final int revenue;

  @override
  List<Object?> get props => [date, revenue];
}

/// Angka satu periode. Semuanya **tidak** memasukkan transaksi void: void
/// berarti penjualan itu tidak pernah terjadi (PRD §2.4), jadi omzet dan laba
/// tidak boleh menghitungnya.
class SalesReport extends Equatable {
  const SalesReport({
    required this.period,
    required this.revenue,
    required this.grossProfit,
    required this.transactionCount,
    required this.itemCount,
    required this.bestSellers,
    required this.daily,
  });

  final ReportPeriod period;
  final int revenue;

  /// Jual − modal dari snapshot item, bukan dari harga produk sekarang.
  final int grossProfit;
  final int transactionCount;
  final int itemCount;
  final List<BestSeller> bestSellers;

  /// Satu entri per hari dalam periode, **termasuk** hari tanpa penjualan
  /// (omzet 0), supaya grafiknya tidak memadatkan hari kosong.
  final List<DailyRevenue> daily;

  /// Nilai rata-rata per transaksi; 0 kalau belum ada transaksi.
  int get averageSale =>
      transactionCount == 0 ? 0 : revenue ~/ transactionCount;

  @override
  List<Object?> get props => [
    period,
    revenue,
    grossProfit,
    transactionCount,
    itemCount,
    bestSellers,
    daily,
  ];
}
