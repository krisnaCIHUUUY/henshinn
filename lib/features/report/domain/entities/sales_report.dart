import 'package:equatable/equatable.dart';

/// Preset laporan. Rentang bebas sengaja tidak ada: itu garis potong PRD §3.2
/// supaya MVP selesai 8 minggu — chip "Pilih" di mockup v2 tidak dibangun.
enum ReportPeriod {
  hariIni('Hari ini'),
  tujuhHari('7 hari'),

  /// Bulan **kalender** berjalan: tanggal 1 sampai akhir hari ini. Menggantikan
  /// "30 hari" bergulir atas keputusan pemilik — pembukuan warung dihitung per
  /// bulan, jadi "30 hari" selalu mencampur sisa bulan lalu (ADR-056).
  bulanIni('Bulan ini');

  const ReportPeriod(this.label);

  final String label;

  /// Rentang periode dalam waktu **lokal**: dari tengah malam hari pertama
  /// sampai akhir hari ini. Pemilik menghitung "hari ini" sebagai satu hari
  /// kalender, bukan 24 jam ke belakang.
  ///
  /// Panjangnya tidak lagi bisa disimpan sebagai satu angka `days`: bulan
  /// kalender panjangnya 28–31 hari dan berubah tiap tanggal. Yang butuh
  /// jumlah hari menghitungnya dari rentang ini.
  (DateTime start, DateTime end) rangeFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    return switch (this) {
      ReportPeriod.hariIni => (today, end),
      ReportPeriod.tujuhHari => (
        today.subtract(const Duration(days: 6)),
        end,
      ),
      ReportPeriod.bulanIni => (DateTime(now.year, now.month), end),
    };
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
