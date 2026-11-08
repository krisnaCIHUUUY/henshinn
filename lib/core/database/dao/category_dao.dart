import 'package:drift/drift.dart';

import 'package:henshin/core/database/app_database.dart';
part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  /// Pencocokan tanpa peka huruf besar/kecil supaya "minuman" tidak membuat
  /// kategori kedua di samping "Minuman" (ADR-038). `limit(1)`, bukan
  /// `getSingleOrNull` tanpa batas: tidak ada unique index di kolom ini, jadi
  /// baris kembar mungkin ada dan tidak boleh melempar.
  ///
  /// shortcut: `lower()` SQLite hanya melipat ASCII, jadi "Café" dan "café"
  /// tetap dianggap beda; naikkan kalau nama kategori non-ASCII jadi nyata.
  Future<Category?> findCategoryByName(String name) {
    final needle = name.toLowerCase();
    return (select(categories)
          ..where((c) => c.name.lower().equals(needle))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> addCategory(CategoriesCompanion category) =>
      into(categories).insert(category);
}
