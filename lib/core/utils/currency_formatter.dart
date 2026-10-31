import 'package:intl/intl.dart';

/// Rupiah selalu `int` (PRD §2.6), jadi tidak ada desimal di mana pun.
final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRupiah(int amount) => _rupiah.format(amount);

/// Membaca input user yang mungkin berisi titik/spasi ("25.000") jadi int.
/// Mengembalikan null kalau tidak ada angka yang bisa dibaca.
int? parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}
