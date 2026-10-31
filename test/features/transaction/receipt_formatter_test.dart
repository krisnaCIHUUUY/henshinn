import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:henshin/features/transaction/domain/receipt_formatter.dart';

void main() {
  const formatter = ReceiptFormatter();

  Receipt receipt({
    List<ReceiptLine> lines = const [
      ReceiptLine(name: 'Kopi', qty: 2, unitPrice: 25000),
    ],
    int total = 50000,
    int paymentAmount = 100000,
    String storeName = '',
    String storeAddress = '',
    String footerMessage = '',
    bool isVoided = false,
    String? voidReason,
    bool isReprint = false,
  }) => Receipt(
    transactionId: 7,
    dateTime: DateTime(2026, 10, 31, 14, 5),
    lines: lines,
    total: total,
    paymentAmount: paymentAmount,
    storeName: storeName,
    storeAddress: storeAddress,
    footerMessage: footerMessage,
    isVoided: isVoided,
    voidReason: voidReason,
    isReprint: isReprint,
  );

  test('tidak ada baris yang melebihi lebar kertas 58mm', () {
    final lines = formatter.format(
      receipt(
        storeName: 'Toko Henshin Serba Ada Cabang Utama Jalan Panjang',
        storeAddress: 'Jl. Raya Bandung Nomor 123 RT 04 RW 08 Kecamatan X',
        footerMessage: 'Terima kasih sudah berbelanja, sampai jumpa lagi ya',
        lines: const [
          ReceiptLine(
            name: 'Kopi Susu Gula Aren Ukuran Besar Extra Shot',
            qty: 3,
            unitPrice: 28000,
          ),
          ReceiptLine(name: 'Teh', qty: 1, unitPrice: 8000),
        ],
        total: 92000,
      ),
    );

    for (final line in lines) {
      expect(
        line.length,
        lessThanOrEqualTo(ReceiptFormatter.defaultWidth),
        reason: 'baris melebihi 32 karakter: "$line"',
      );
    }
  });

  test('kata yang lebih panjang dari kertas tetap dipecah, tidak hilang', () {
    final lines = formatter.format(
      receipt(
        lines: [
          // 'Z' dipakai karena tidak muncul di label struk mana pun
          // (TOTAL, Bayar, Kembali, Waktu), jadi hitungannya murni.
          ReceiptLine(name: 'Z' * 70, qty: 1, unitPrice: 1000),
        ],
        total: 1000,
      ),
    );

    // seluruh 70 huruf harus tetap muncul, terpecah di beberapa baris
    final joined = lines.join();
    expect(joined.split('').where((c) => c == 'Z').length, 70);
  });

  test('angka rata kanan dan tidak pernah terpotong', () {
    final lines = formatter.format(
      receipt(total: 1234567, paymentAmount: 2000000),
    );

    final totalLine = lines.firstWhere((l) => l.startsWith('TOTAL'));
    expect(totalLine.length, ReceiptFormatter.defaultWidth);
    expect(totalLine.trimRight(), endsWith('1.234.567'));

    final changeLine = lines.firstWhere((l) => l.startsWith('Kembali'));
    expect(changeLine.trimRight(), endsWith('765.433'));
  });

  test('label panjang dipotong, nilainya tetap utuh', () {
    const narrow = ReceiptFormatter(width: 14);
    final lines = narrow.format(receipt(total: 1234567));

    final totalLine = lines.firstWhere((l) => l.contains('1.234.567'));
    expect(totalLine.length, lessThanOrEqualTo(14));
    expect(totalLine, contains('1.234.567'));
  });

  test('header dilewati kalau info toko belum diisi', () {
    final lines = formatter.format(receipt());

    expect(lines.first, startsWith('No   : #7'));
    expect(lines.any((l) => l.contains('Henshin')), isFalse);
  });

  test('nama dan alamat toko muncul di atas, rata tengah', () {
    final lines = formatter.format(
      receipt(storeName: 'Toko Henshin', storeAddress: 'Jl. Merdeka 1'),
    );

    expect(lines.first.trim(), 'Toko Henshin');
    expect(lines[1].trim(), 'Jl. Merdeka 1');
    // rata tengah: ada spasi di depan
    expect(lines.first.startsWith(' '), isTrue);
  });

  test('isi struk: nomor, waktu, item, total, bayar, kembali', () {
    final text = formatter.formatAsText(receipt());

    expect(text, contains('#7'));
    expect(text, contains('31/10/2026 14:05'));
    expect(text, contains('Kopi'));
    expect(text, contains('2 x 25.000'));
    expect(text, contains('50.000'));
    expect(text, contains('TOTAL (2 item)'));
    expect(text, contains('Kembali'));
  });

  test('struk void ditandai jelas beserta alasannya', () {
    final text = formatter.formatAsText(
      receipt(isVoided: true, voidReason: 'Salah input harga'),
    );

    expect(text, contains('*** VOID ***'));
    expect(text, contains('Transaksi dibatalkan.'));
    expect(text, contains('Alasan: Salah input harga'));
  });

  test('cetak ulang ditandai supaya tidak tertukar dengan struk asli', () {
    final text = formatter.formatAsText(receipt(isReprint: true));
    expect(text, contains('-- CETAK ULANG --'));

    // struk asli tidak membawa tanda itu
    expect(formatter.formatAsText(receipt()), isNot(contains('CETAK ULANG')));
  });

  test('uang kurang menghasilkan kembalian negatif, bukan dibulatkan', () {
    final r = receipt(total: 50000, paymentAmount: 20000);
    expect(r.change, -30000);
    expect(formatter.formatAsText(r), contains('-30.000'));
  });
}
