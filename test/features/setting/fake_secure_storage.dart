import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Secure storage palsu berbasis Map. Memakai seam resmi plugin
/// (`FlutterSecureStoragePlatform.instance`) supaya kode produksi tidak perlu
/// wrapper tambahan hanya demi tes.
///
/// `store` sengaja dibiarkan publik: memakai Map yang sama untuk dua instance
/// `FlutterSecureStorage` mensimulasikan app ditutup lalu dibuka lagi.
class FakeSecureStorage extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  FakeSecureStorage([Map<String, String>? initial])
    : store = initial ?? <String, String>{};

  final Map<String, String> store;

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async => store[key] = value;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => store[key];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => store.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async => store.remove(key);

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map.of(store);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      store.clear();
}
