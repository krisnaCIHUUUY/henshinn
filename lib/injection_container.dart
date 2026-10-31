import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/core/database/dao/category_dao.dart';
import 'package:henshin/core/database/dao/product_dao.dart';
import 'package:henshin/features/product/data/repositories/product_repository_impl.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/setting/data/repositories/pin_repository_impl.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/domain/usecases/has_pin.dart';
import 'package:henshin/features/setting/domain/usecases/set_pin.dart';
import 'package:henshin/features/setting/domain/usecases/verify_pin.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_bloc.dart';

final sl = GetIt.instance;

/// Dipanggil sekali di `main()` sebelum `runApp`.
/// DAO/repository/usecase lain didaftarkan saat fiturnya digarap, bukan di sini.
void initDependencies() {
  // ===== core =====
  sl.registerLazySingleton<AppDatabase>(
    () => AppDatabase(
      driftDatabase(
        name: 'henshin',
        native: const DriftNativeOptions(
          // support dir, bukan documents dir: tidak terekspos ke file manager user
          databaseDirectory: getApplicationSupportDirectory,
        ),
      ),
    ),
  );
  sl.registerLazySingleton<ProductDao>(() => ProductDao(sl()));
  sl.registerLazySingleton<CategoryDao>(() => CategoryDao(sl()));

  // ===== product =====
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AddProduct>(() => AddProduct(sl()));
  sl.registerLazySingleton<UpdateProduct>(() => UpdateProduct(sl()));
  sl.registerLazySingleton<DeleteProduct>(() => DeleteProduct(sl()));
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(
      repository: sl(),
      addProduct: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
    ),
  );

  // ===== setting / PIN =====
  // Opsi Android default v10: RSA OAEP + AES-GCM lewat keystore.
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<PinRepository>(() => PinRepositoryImpl(sl()));
  sl.registerLazySingleton<HasPin>(() => HasPin(sl()));
  sl.registerLazySingleton<SetPin>(() => SetPin(sl()));
  sl.registerLazySingleton<VerifyPin>(() => VerifyPin(sl()));
  sl.registerFactory<PinBloc>(
    () =>
        PinBloc(repository: sl(), hasPin: sl(), setPin: sl(), verifyPin: sl()),
  );
}
