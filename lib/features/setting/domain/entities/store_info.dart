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

  /// Ambang pengingat backup (langkah 13). Dihitung per hari kalender, bukan
  /// per 168 jam: backup jam 23:00 lalu dibuka jam 01:00 tujuh hari kemudian
  /// tetap terhitung 7 hari, sama seperti pengelompokan hari di laporan
  /// (ADR-032).
  static const backupStaleAfterDays = 7;

  /// Jumlah hari kalender sejak backup terakhir; null kalau belum pernah.
  int? daysSinceBackup(DateTime now) {
    final last = lastBackupAt;
    if (last == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final then = DateTime(last.year, last.month, last.day);
    return today.difference(then).inDays;
  }

  /// Belum pernah backup juga dianggap basi — itu justru kondisi paling
  /// berbahaya, bukan kondisi netral.
  bool backupIsStale(DateTime now) {
    final days = daysSinceBackup(now);
    return days == null || days > backupStaleAfterDays;
  }

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
