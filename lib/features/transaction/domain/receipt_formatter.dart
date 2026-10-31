import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/transaction/domain/entities/receipt.dart';
import 'package:intl/intl.dart';

/// Mengubah [Receipt] jadi baris-baris teks selebar kertas 58mm.
///
/// Ini satu-satunya tempat tata letak struk ditentukan. Preview layar, PDF,
/// dan nanti byte ESC/POS semuanya memakai keluaran yang sama, jadi tidak ada
/// risiko struk di layar berbeda dengan yang tercetak (PRD §2.8).
class ReceiptFormatter {
  const ReceiptFormatter({this.width = defaultWidth});

  /// 58mm ≈ 32 karakter pada font 12x24 (PRD §2.8).
  static const int defaultWidth = 32;

  final int width;

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<String> format(Receipt receipt) => [
    ..._header(receipt),
    ..._items(receipt),
    _divider(),
    ..._totals(receipt),
    ..._footer(receipt),
  ];

  /// Teks siap kirim/ditempel, satu string dengan newline.
  String formatAsText(Receipt receipt) => format(receipt).join('\n');

  // ===== bagian struk =====

  List<String> _header(Receipt receipt) => [
    if (receipt.storeName.isNotEmpty) ..._centerWrapped(receipt.storeName),
    if (receipt.storeAddress.isNotEmpty)
      ..._centerWrapped(receipt.storeAddress),
    if (receipt.storeName.isNotEmpty || receipt.storeAddress.isNotEmpty) '',
    if (receipt.isVoided) ...[..._centerWrapped('*** VOID ***'), ''],
    if (receipt.isReprint) ...[..._centerWrapped('-- CETAK ULANG --'), ''],
    'No   : #${receipt.transactionId}',
    'Waktu: ${_dateFormat.format(receipt.dateTime)}',
    _divider(),
  ];

  /// Nama item di baris sendiri supaya nama panjang tidak memotong angka;
  /// baris kedua berisi "qty x harga" di kiri dan subtotal rata kanan.
  List<String> _items(Receipt receipt) => [
    for (final line in receipt.lines) ...[
      ..._wrap(line.name),
      _row(
        '  ${line.qty} x ${_plain(line.unitPrice)}',
        _plain(line.subtotal),
      ),
    ],
  ];

  List<String> _totals(Receipt receipt) => [
    _row('TOTAL (${receipt.itemCount} item)', _plain(receipt.total)),
    _row('Bayar', _plain(receipt.paymentAmount)),
    _row('Kembali', _plain(receipt.change)),
  ];

  List<String> _footer(Receipt receipt) => [
    if (receipt.isVoided) ...[
      '',
      _divider(),
      ..._wrap('Transaksi dibatalkan.'),
      if ((receipt.voidReason ?? '').isNotEmpty)
        ..._wrap('Alasan: ${receipt.voidReason}'),
    ],
    if (receipt.footerMessage.isNotEmpty) ...[
      '',
      ..._centerWrapped(receipt.footerMessage),
    ],
  ];

  // ===== utilitas tata letak =====

  String _divider() => '-' * width;

  /// Rupiah tanpa prefix "Rp " supaya kolom angka tetap sempit di 32 karakter.
  String _plain(int amount) =>
      formatRupiah(amount).replaceFirst('Rp ', '').trim();

  /// Label di kiri, nilai rata kanan. Kalau tidak cukup, nilai menang dan
  /// label dipotong — angka tidak boleh pernah terpotong di struk.
  String _row(String label, String value) {
    final space = width - value.length;
    if (space <= 1) return value.padLeft(width);

    final trimmedLabel = label.length > space - 1
        ? label.substring(0, space - 1)
        : label;
    return trimmedLabel.padRight(space) + value;
  }

  List<String> _centerWrapped(String text) =>
      _wrap(text).map((line) => _center(line)).toList();

  String _center(String text) {
    if (text.length >= width) return text;
    final left = (width - text.length) ~/ 2;
    return ' ' * left + text;
  }

  /// Memotong per kata; kata yang lebih panjang dari lebar kertas dipecah
  /// paksa supaya tidak ada baris yang hilang.
  List<String> _wrap(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.length <= width) return [trimmed];

    final lines = <String>[];
    var current = '';

    for (final word in trimmed.split(RegExp(r'\s+'))) {
      var remaining = word;
      while (remaining.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        lines.add(remaining.substring(0, width));
        remaining = remaining.substring(width);
      }

      if (current.isEmpty) {
        current = remaining;
      } else if (current.length + 1 + remaining.length <= width) {
        current = '$current $remaining';
      } else {
        lines.add(current);
        current = remaining;
      }
    }

    if (current.isNotEmpty) lines.add(current);
    return lines;
  }
}
