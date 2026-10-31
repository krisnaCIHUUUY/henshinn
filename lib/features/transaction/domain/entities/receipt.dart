import 'package:equatable/equatable.dart';

/// Satu baris item di struk. Angkanya diambil dari snapshot `transaction_items`
/// (bukan dari produk saat ini), supaya cetak ulang struk lama tetap sama
/// walau harga produk sudah berubah (PRD §2.6).
class ReceiptLine extends Equatable {
  const ReceiptLine({
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  final String name;
  final int qty;
  final int unitPrice;

  int get subtotal => unitPrice * qty;

  @override
  List<Object?> get props => [name, qty, unitPrice];
}

/// Satu model untuk tiga keluaran: preview layar, PDF, dan nanti byte ESC/POS
/// (PRD §2.8). Tidak ada satu pun keluaran yang menghitung ulang angkanya
/// sendiri — semuanya membaca model ini lewat `ReceiptFormatter`.
class Receipt extends Equatable {
  const Receipt({
    required this.transactionId,
    required this.dateTime,
    required this.lines,
    required this.total,
    required this.paymentAmount,
    this.storeName = '',
    this.storeAddress = '',
    this.footerMessage = '',
    this.isVoided = false,
    this.voidReason,
    this.isReprint = false,
  });

  final int transactionId;
  final DateTime dateTime;
  final List<ReceiptLine> lines;
  final int total;
  final int paymentAmount;

  final String storeName;
  final String storeAddress;
  final String footerMessage;

  /// Struk transaksi yang sudah di-void harus terlihat jelas statusnya supaya
  /// tidak dipakai sebagai bukti pembayaran yang sah.
  final bool isVoided;
  final String? voidReason;

  /// Ditandai di struk supaya salinan tidak tertukar dengan yang asli (US-3.4).
  final bool isReprint;

  int get change => paymentAmount - total;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.qty);

  Receipt copyWith({bool? isReprint}) => Receipt(
    transactionId: transactionId,
    dateTime: dateTime,
    lines: lines,
    total: total,
    paymentAmount: paymentAmount,
    storeName: storeName,
    storeAddress: storeAddress,
    footerMessage: footerMessage,
    isVoided: isVoided,
    voidReason: voidReason,
    isReprint: isReprint ?? this.isReprint,
  );

  @override
  List<Object?> get props => [
    transactionId,
    dateTime,
    lines,
    total,
    paymentAmount,
    storeName,
    storeAddress,
    footerMessage,
    isVoided,
    voidReason,
    isReprint,
  ];
}
