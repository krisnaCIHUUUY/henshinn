import 'package:drift/drift.dart';
import 'package:henshin/core/database/app_database.dart';

part 'settings_dao.g.dart';

/// Tabel `settings` selalu tepat satu baris (id = 1), di-seed di
/// `AppDatabase.beforeOpen`. DAO ini tidak pernah membuat baris baru.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<Setting> watchSettings() =>
      (select(settings)..limit(1)).watchSingle();

  Future<Setting> getSettings() => (select(settings)..limit(1)).getSingle();

  /// Hanya kolom yang diisi yang tertimpa — kolom lain dibiarkan.
  Future<bool> updateSettings(SettingsCompanion changes) async {
    final rows = await update(settings).write(changes);
    return rows > 0;
  }
}
