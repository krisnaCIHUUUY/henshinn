import 'package:equatable/equatable.dart';

/// Info toko yang dicetak di struk. Berasal dari tabel `settings`.
class StoreInfo extends Equatable {
  const StoreInfo({
    this.name = '',
    this.address = '',
    this.receiptMessage = '',
    this.lastBackupAt,
  });

  final String name;
  final String address;

  /// Catatan penutup struk, mis. "Terima kasih".
  final String receiptMessage;
  final DateTime? lastBackupAt;

  /// Header struk dilewati kalau pemilik belum mengisi apa pun.
  bool get hasHeader => name.isNotEmpty || address.isNotEmpty;

  StoreInfo copyWith({
    String? name,
    String? address,
    String? receiptMessage,
    DateTime? lastBackupAt,
  }) => StoreInfo(
    name: name ?? this.name,
    address: address ?? this.address,
    receiptMessage: receiptMessage ?? this.receiptMessage,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
  );

  @override
  List<Object?> get props => [name, address, receiptMessage, lastBackupAt];
}
