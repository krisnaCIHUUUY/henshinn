import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_history_screen.dart';

/// Chip rentang di Riwayat. Satu aturan yang mudah dilanggar perubahan
/// berikutnya: rentangnya hari **kalender**, bukan 24 jam ke belakang — sama
/// dengan `ReportPeriod.rangeFrom`. Fungsi murni, jadi diuji `test()` biasa
/// (ADR-012).
void main() {
  // Siang hari, supaya salah hitung "24 jam ke belakang" benar-benar terlihat.
  final now = DateTime(2026, 11, 11, 14, 32, 7);

  test('Hari ini mulai tengah malam, bukan 24 jam ke belakang', () {
    final (since, until) = historyRange(HistoryRange.today, now);
    expect(since, DateTime(2026, 11, 11));
    expect(until, DateTime(2026, 11, 12).subtract(const Duration(microseconds: 1)));
  });

  test('Kemarin satu hari kalender penuh, tidak menyentuh hari ini', () {
    final (since, until) = historyRange(HistoryRange.yesterday, now);
    expect(since, DateTime(2026, 11, 10));
    expect(until, DateTime(2026, 11, 11).subtract(const Duration(microseconds: 1)));
    // Transaksi jam 00.00 hari ini harus di luar rentang.
    expect(until.isBefore(DateTime(2026, 11, 11)), isTrue);
  });

  test('7 hari memuat hari ini dan enam hari sebelumnya', () {
    final (since, until) = historyRange(HistoryRange.week, now);
    expect(since, DateTime(2026, 11, 5));
    expect(until, DateTime(2026, 11, 12).subtract(const Duration(microseconds: 1)));
  });

  test('Pilih tanggal memakai tanggalnya, jamnya dibuang', () {
    final (since, until) = historyRange(
      HistoryRange.pickedDate,
      now,
      picked: DateTime(2026, 10, 2, 23, 59),
    );
    expect(since, DateTime(2026, 10, 2));
    expect(until, DateTime(2026, 10, 3).subtract(const Duration(microseconds: 1)));
  });

  test('Pilih tanggal tanpa tanggal jatuh ke hari ini, bukan rentang kosong', () {
    expect(
      historyRange(HistoryRange.pickedDate, now),
      historyRange(HistoryRange.today, now),
    );
  });

  test('semua rentang punya batas atas', () {
    for (final range in HistoryRange.values) {
      final (since, until) = historyRange(range, now, picked: now);
      expect(until.isAfter(since), isTrue, reason: '$range');
    }
  });
}
