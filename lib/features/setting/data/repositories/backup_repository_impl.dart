import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/repositories/backup_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hasil share sheet, disuntikkan supaya `exportAndShare` bisa diuji tanpa UI.
typedef ShareBackup = Future<ShareResultStatus> Function(File file);

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(
    this._db,
    this._settingsDao, {
    Future<Directory> Function()? outputDirectory,
    ShareBackup? share,
    DateTime Function()? now,
  })  : _outputDirectory = outputDirectory ?? getTemporaryDirectory,
        _share = share ?? _shareWithSystem,
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SettingsDao _settingsDao;

  /// Cache aplikasi, bukan folder publik: sejak Android 11 menulis ke
  /// penyimpanan bersama butuh SAF/MediaStore. File di sini hanya titipan
  /// sampai user memilih tujuan di share sheet, dan boleh dibuang OS kapan pun.
  final Future<Directory> Function() _outputDirectory;
  final ShareBackup _share;
  final DateTime Function() _now;

  /// `.sqlite` tidak punya mime type terdaftar di Android, jadi tanpa ini
  /// sebagian target share (Drive, WhatsApp) menolak atau menyembunyikan file.
  static Future<ShareResultStatus> _shareWithSystem(File file) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        text: 'Backup Henshin ${p.basename(file.path)}',
      ),
    );
    return result.status;
  }

  /// Dipisah dari [exportAndShare] supaya isinya bisa diverifikasi tanpa share
  /// sheet: file hasilnya harus benar-benar database yang bisa dibuka.
  Future<File> exportToFile() async {
    final dir = await _outputDirectory();
    final file = File(p.join(dir.path, _fileName(_now())));
    await _db.exportInto(file);
    return file;
  }

  /// Nama berisi tanggal + jam supaya dua backup di hari yang sama tidak saling
  /// menimpa di folder tujuan user.
  static String _fileName(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'henshin-backup-${at.year}-${two(at.month)}-${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}.sqlite';
  }

  @override
  Future<Either<Failure, void>> exportAndShare() async {
    try {
      final file = await exportToFile();
      final status = await _share(file);

      // `dismissed` = user menutup share sheet tanpa memilih tujuan, jadi tidak
      // ada backup yang benar-benar tersimpan di luar cache. Di Android status
      // sering `unavailable` (tidak bisa dibedakan) — itu tetap dihitung
      // berhasil, karena menolaknya berarti pengingat 7 hari tidak pernah
      // berhenti muncul di semua HP Android.
      if (status == ShareResultStatus.dismissed) return const Right(null);

      await _settingsDao.updateSettings(
        SettingsCompanion(lastBackupAt: Value(_now())),
      );
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('[backup] gagal export: $e');
      debugPrint('$stackTrace');
      return Left(StorageFailure('Gagal membuat backup: $e'));
    }
  }
}
