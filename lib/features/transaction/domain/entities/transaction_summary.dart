import 'package:equatable/equatable.dart';

/// Satu baris di list riwayat. Hanya yang terlihat di list — detailnya dibaca
/// ulang sebagai `Receipt` saat barisnya dibuka, jadi tidak ada angka struk
/// yang digandakan di dua tempat.
class TransactionSummary extends Equatable {
  const TransactionSummary({
    required this.id,
    required this.dateTime,
    required this.total,
    required this.itemCount,
    required this.isVoided,
  });

  final int id;
  final DateTime dateTime;
  final int total;
  final int itemCount;
  final bool isVoided;

  @override
  List<Object?> get props => [id, dateTime, total, itemCount, isVoided];
}
