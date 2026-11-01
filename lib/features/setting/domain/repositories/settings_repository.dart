import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';

abstract class SettingsRepository {
  Stream<StoreInfo> watchStoreInfo();

  Future<Either<Failure, StoreInfo>> getStoreInfo();

  /// Hanya field yang diisi yang diubah.
  Future<Either<Failure, void>> updateStoreInfo({
    String? name,
    String? address,
    String? receiptMessage,
  });
}
