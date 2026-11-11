import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/transaction/presentation/screens/payment_screen.dart';

/// Tombol cepat di layar bayar. Fungsi murni, jadi diuji `test()` biasa —
/// bukan lewat widget (ADR-012).
void main() {
  test('tombol pertama selalu uang pas, sebesar total', () {
    expect(quickCashOptions(23500).first, 23500);
  });

  test('hanya pecahan yang lebih besar dari total yang ditawarkan', () {
    expect(quickCashOptions(23500), [23500, 25000, 50000, 100000]);
    expect(quickCashOptions(60000), [60000, 100000]);
  });

  test('pecahan yang sama dengan total tidak diduakalikan', () {
    expect(quickCashOptions(50000), [50000, 100000]);
  });

  test('total di atas 100.000 hanya menyisakan uang pas', () {
    expect(quickCashOptions(230000), [230000]);
  });
}
