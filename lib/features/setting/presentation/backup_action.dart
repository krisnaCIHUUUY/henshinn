import 'package:flutter/material.dart';
import 'package:henshin/features/setting/domain/repositories/backup_repository.dart';
import 'package:henshin/injection_container.dart';

/// Dipakai dari dua tempat (baris Pengaturan dan banner dashboard), jadi
/// dialog tunggu + pesan hasilnya hidup di satu fungsi. Pola yang sama dengan
/// `PinGate.require`: helper statis, bukan bloc baru (ADR-028).
abstract final class BackupAction {
  /// `true` kalau export selesai tanpa error. Pemanggil memakainya untuk
  /// menyegarkan tampilan "backup terakhir".
  static Future<bool> run(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Modal barrier: VACUUM INTO di DB besar makan waktu, dan menekan tombolnya
    // dua kali akan menulis dua file sekaligus. PopScope-nya wajib: tanpa itu
    // tombol back menutup dialog ini, lalu `pop()` di bawah akan menutup
    // halaman di belakangnya.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final result = await sl<BackupRepository>().exportAndShare();

    // Dialog ditutup lewat rootNavigator: barrier ini dipasang di atas
    // navigator mana pun yang sedang aktif.
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    return result.fold(
      (failure) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        return false;
      },
      (_) => true,
    );
  }
}
