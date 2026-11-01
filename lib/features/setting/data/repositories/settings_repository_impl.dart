import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/settings_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:henshin/features/setting/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDao _settingsDao;

  SettingsRepositoryImpl(this._settingsDao);

  static StoreInfo _toEntity(Setting row) => StoreInfo(
    name: row.storeName,
    address: row.storeAddress,
    receiptMessage: row.receiptMessage,
    lastBackupAt: row.lastBackupAt,
  );

  @override
  Stream<StoreInfo> watchStoreInfo() =>
      _settingsDao.watchSettings().map(_toEntity);

  @override
  Future<Either<Failure, StoreInfo>> getStoreInfo() async {
    try {
      return Right(_toEntity(await _settingsDao.getSettings()));
    } catch (e) {
      return Left(DatabaseFailure('Gagal membaca info toko: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStoreInfo({
    String? name,
    String? address,
    String? receiptMessage,
  }) async {
    try {
      final changed = await _settingsDao.updateSettings(
        SettingsCompanion(
          storeName: name == null ? const Value.absent() : Value(name.trim()),
          storeAddress: address == null
              ? const Value.absent()
              : Value(address.trim()),
          receiptMessage: receiptMessage == null
              ? const Value.absent()
              : Value(receiptMessage.trim()),
        ),
      );
      if (!changed) {
        return const Left(NotFoundFailure('Baris settings tidak ditemukan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyimpan info toko: $e'));
    }
  }
}
