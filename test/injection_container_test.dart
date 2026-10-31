import 'dart:io';

import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/database/app_database.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_bloc.dart';
import 'package:henshin/injection_container.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'features/setting/fake_secure_storage.dart';

/// path_provider butuh platform channel; dipalsukan ke folder temp supaya
/// grafik DI bisa di-resolve sepenuhnya tanpa device.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getTemporaryPath() async => dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;

  @override
  Future<String?> getApplicationCachePath() async => dir;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('henshin_di_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    FlutterSecureStoragePlatform.instance = FakeSecureStorage();
    initDependencies();
  });

  tearDown(() async {
    await sl.reset();
    tempDir.deleteSync(recursive: true);
  });

  // Regresi: pernah lolos `flutter analyze` tapi meledak di runtime dengan
  // NoSuchMethodError karena jumlah argumen konstruktor repository berubah
  // tanpa registrasi DI-nya ikut diubah.
  test('semua dependency yang dipakai app bisa di-resolve', () {
    expect(sl<AppDatabase>(), isNotNull);
    expect(sl<ProductRepository>(), isNotNull);
    expect(sl<ProductBloc>(), isNotNull);
    expect(sl<PinRepository>(), isNotNull);
    expect(sl<PinBloc>(), isNotNull);
  });

  test('database yang di-wire benar-benar bisa dibuka dan di-query', () async {
    final db = sl<AppDatabase>();

    // Membuka file sungguhan di folder temp, menjalankan migrasi + seed.
    final categories = await db.select(db.categories).get();
    expect(categories.map((c) => c.name), [kDefaultCategoryName]);
    expect(db.schemaVersion, 3);

    // Repository di atas DB yang sama ikut terbaca.
    expect(await sl<ProductRepository>().watchAllProducts().first, isEmpty);

    await db.close();
  });
}
