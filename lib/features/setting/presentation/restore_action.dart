import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/features/setting/domain/repositories/backup_repository.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/injection_container.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Memulihkan data dari file backup (langkah 14 / PRD §1.6).
///
/// Urutannya disengaja: PIN dulu, lalu pilih file, lalu validasi, dan
/// konfirmasi terakhir — supaya pemilik tidak pernah diminta menyetujui
/// penimpaan data sebelum kita tahu file-nya benar-benar bisa dipulihkan.
/// Pola helper statisnya sama dengan `BackupAction` dan `PinGate` (ADR-028).
abstract final class RestoreAction {
  static Future<void> run(BuildContext context) async {
    if (!await PinGate.require(
      context,
      reason: 'Diperlukan untuk memulihkan data',
    )) {
      return;
    }
    if (!context.mounted) return;

    // FileType.any tanpa allowedExtensions: filter ekstensi di Android
    // dikerjakan file explorer bawaan HP dan sering diabaikan, jadi kita
    // memvalidasi sendiri di `BackupRepository.validate` (dan memang harus).
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Pilih file backup Henshin',
      type: FileType.any,
    );
    if (picked == null || !context.mounted) return;

    if (!await _confirm(context, picked.name)) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    _showBlockingProgress(context);

    final Either<Failure, void> result;
    File? staged;
    try {
      staged = await _stageInCache(picked);
      result = await sl<BackupRepository>().restoreFrom(staged);
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membaca file backup: $e')),
      );
      return;
    } finally {
      // Salinan kerja, bukan data pemilik: file aslinya tetap di tempatnya.
      if (staged != null && staged.existsSync()) staged.deleteSync();
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        if (context.mounted) _showMustRestart(context);
      },
    );
  }

  /// Picker bisa mengembalikan file dari Drive atau penyedia lain yang tidak
  /// punya jalur di disk (`path` null). sqlite3 butuh jalur nyata, jadi
  /// isinya selalu disalin dulu — satu jalur kode untuk semua sumber.
  static Future<File> _stageInCache(PlatformFile picked) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'henshin-restore-kandidat.sqlite'));
    final sink = file.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
    } finally {
      await sink.close();
    }
    return file;
  }

  static Future<bool> _confirm(BuildContext context, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Timpa semua data sekarang?'),
        content: Text(
          'Semua produk, transaksi, dan stok di HP ini akan diganti dengan isi '
          '"$fileName". Data yang sekarang tidak bisa dikembalikan kecuali '
          'kamu punya backup-nya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColor.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Timpa data'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static void _showBlockingProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Koneksi database sudah ditutup dan setiap DAO di get_it memegang
  /// pegangan mati, jadi tidak ada layar yang boleh dibuka lagi. Dialog ini
  /// tidak bisa ditutup selain lewat tombolnya (ADR-039).
  ///
  /// `exit(0)`, **bukan** `SystemNavigator.pop()`: yang terakhir hanya menutup
  /// Activity dan membiarkan prosesnya hidup, jadi saat aplikasi dibuka lagi
  /// `main()` tidak jalan ulang, `initDependencies()` tidak jalan ulang, dan
  /// get_it masih memegang koneksi yang sudah ditutup di atas — layarnya putih
  /// kosong. Ditemukan saat verifikasi manual langkah 14.
  static void _showMustRestart(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Data sudah dipulihkan'),
          content: const Text(
            'Henshin perlu ditutup dan dibuka lagi supaya data yang baru '
            'terpakai.',
          ),
          actions: [
            TextButton(
              onPressed: () => exit(0),
              child: const Text('Tutup aplikasi'),
            ),
          ],
        ),
      ),
    );
  }
}
