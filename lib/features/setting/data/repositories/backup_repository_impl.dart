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
import 'package:sqlite3/sqlite3.dart';

/// Hasil share sheet, disuntikkan supaya `exportAndShare` bisa diuji tanpa UI.
typedef ShareBackup = Future<ShareResultStatus> Function(File file);

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(
    this._db,
    this._settingsDao, {
    Future<Directory> Function()? outputDirectory,
    Future<Directory> Function()? databaseDirectory,
    ShareBackup? share,
    DateTime Function()? now,
  })  : _outputDirectory = outputDirectory ?? getTemporaryDirectory,
        _databaseDirectory = databaseDirectory ?? getApplicationSupportDirectory,
        _share = share ?? _shareWithSystem,
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SettingsDao _settingsDao;

  /// Cache aplikasi, bukan folder publik: sejak Android 11 menulis ke
  /// penyimpanan bersama butuh SAF/MediaStore. File di sini hanya titipan
  /// sampai user memilih tujuan di share sheet, dan boleh dibuang OS kapan pun.
  final Future<Directory> Function() _outputDirectory;

  /// Folder tempat `driftDatabase(name: 'henshin')` menaruh file aktifnya.
  /// Sama dengan yang dipasang di `injection_container.dart`.
  final Future<Directory> Function() _databaseDirectory;
  final ShareBackup _share;
  final DateTime Function() _now;

  /// `driftDatabase(name: 'henshin')` menulis ke `<dir>/henshin.sqlite`.
  static const liveDatabaseFileName = 'henshin.sqlite';

  /// Satu file, selalu ditimpa: cukup untuk membatalkan satu restore yang
  /// salah. Bukan backup — ia tinggal di cache yang boleh dibuang Android
  /// kapan pun (ADR-040).
  static const safetyCopyFileName = 'henshin-sebelum-restore.sqlite';

  /// 16 byte pertama setiap file database SQLite, termasuk NUL penutupnya.
  static const _sqliteHeader = 'SQLite format 3\x00';

  /// Nama tabel di `@DriftDatabase`. Dicek manual, bukan lewat Drift, supaya
  /// file kandidat tidak pernah dibuka sebagai `AppDatabase` — membukanya
  /// berarti menjalankan migrasi dan mengubah backup milik pemilik.
  static const _requiredTables = {
    'categories',
    'products',
    'transactions',
    'transaction_items',
    'stock_movements',
    'settings',
  };

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

  /// `null` kalau [file] layak dipulihkan, kalau tidak Failure dengan pesan
  /// yang bisa langsung ditampilkan ke pemilik.
  ///
  /// Dipisah dan publik supaya setiap aturannya bisa diuji tanpa menyentuh
  /// database aktif. Urutannya dari yang paling murah: ada, cukup besar,
  /// header benar, baru dibuka.
  static Failure? validate(File file, {int currentSchemaVersion = 4}) {
    if (!file.existsSync()) {
      return const StorageFailure('File backup tidak ditemukan');
    }

    // Lebih pendek dari header saja sudah pasti bukan database, dan membaca
    // 16 byte dari file 3 byte akan error, bukan mengembalikan pendek.
    if (file.lengthSync() < _sqliteHeader.length) {
      return const ValidationFailure('File ini bukan backup Henshin');
    }

    final raf = file.openSync();
    final List<int> head;
    try {
      head = raf.readSync(_sqliteHeader.length);
    } finally {
      raf.closeSync();
    }
    if (String.fromCharCodes(head) != _sqliteHeader) {
      return const ValidationFailure('File ini bukan backup Henshin');
    }

    // readOnly: kalau file-nya ternyata rusak, jangan sampai sqlite
    // "memperbaikinya" dengan menulis ke backup milik pemilik.
    final Database candidate;
    try {
      candidate = sqlite3.open(file.path, mode: OpenMode.readOnly);
    } catch (e) {
      return ValidationFailure('File backup rusak dan tidak bisa dibuka: $e');
    }

    try {
      final tables = candidate
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row['name'] as String)
          .toSet();
      final missing = _requiredTables.difference(tables);
      if (missing.isNotEmpty) {
        return ValidationFailure(
          'Backup ini tidak lengkap, tabel ${missing.join(", ")} tidak ada',
        );
      }

      // `PRAGMA user_version`, bukan kolom `settings.schemaVersion`: yang
      // terakhir hanya diisi saat seed dan jadi basi setelah migrasi, sedangkan
      // user_version selalu dinaikkan Drift sendiri.
      final version = candidate.select('PRAGMA user_version').first.values.first;
      if (version is! int || version < 1) {
        return const ValidationFailure('File ini bukan backup Henshin');
      }
      if (version > currentSchemaVersion) {
        return ValidationFailure(
          'Backup ini dari versi aplikasi yang lebih baru (skema $version). '
          'Update Henshin dulu, baru pulihkan.',
        );
      }
    } catch (e) {
      return ValidationFailure('File backup rusak: $e');
    } finally {
      candidate.close();
    }

    return null;
  }

  @override
  Future<Either<Failure, void>> restoreFrom(File backup) async {
    final invalid = validate(backup);
    if (invalid != null) return Left(invalid);

    try {
      final live = File(
        p.join((await _databaseDirectory()).path, liveDatabaseFileName),
      );
      final safety = File(
        p.join((await _outputDirectory()).path, safetyCopyFileName),
      );

      // Salinan pengaman dulu, selagi koneksi masih hidup: VACUUM INTO butuh
      // database yang terbuka, dan kalau langkah ini gagal tidak ada apa pun
      // yang sudah ditimpa.
      await _db.exportInto(safety);

      // Disalin ke sebelah file aktif lebih dulu, lalu di-rename. Rename di
      // filesystem yang sama bersifat atomik, jadi tidak ada momen di mana
      // `henshin.sqlite` berisi setengah backup — itu yang terjadi kalau kita
      // menyalin langsung ke atasnya dan prosesnya mati di tengah.
      final staged = File('${live.path}.restore');
      await backup.copy(staged.path);

      await _db.close();
      try {
        await staged.rename(live.path);
      } catch (e) {
        // Koneksi sudah mati tapi file aktif belum tersentuh: datanya utuh,
        // hanya aplikasinya yang tidak bisa dipakai sampai dibuka ulang.
        // Pesannya harus mengatakan itu, bukan sekadar "gagal".
        return Left(StorageFailure(
          'Gagal menukar file database: $e. Data lama masih utuh — tutup dan '
          'buka lagi Henshin.',
        ));
      }

      // WAL dan shm milik database lama. Kalau ditinggal, sqlite bisa memutar
      // ulang transaksi lama di atas file yang baru dipulihkan.
      for (final suffix in const ['-wal', '-shm']) {
        final sidecar = File('${live.path}$suffix');
        if (sidecar.existsSync()) sidecar.deleteSync();
      }

      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('[backup] gagal restore: $e');
      debugPrint('$stackTrace');
      return Left(StorageFailure('Gagal memulihkan data: $e'));
    }
  }
}
