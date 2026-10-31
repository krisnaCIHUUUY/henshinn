# AGENTS.md — Henshin POS

> Details: `docs/henshin_prd.md` (scope + business rules), `README.md` (quick start).
> Plan + status: `docs/implementasi.md` (step plan), `docs/progress.md` (what is done).
> **`docs/keputusan-arsitektur.md` — read before changing DB, PIN, or stock code.**
> It records decisions you cannot infer from the code and must not undo by accident.

## 1. Tech stack

Flutter (Android, offline-only) + flutter_bloc (Bloc + Freezed) + Drift (SQLite) + go_router (`StatefulShellRoute`), Clean Architecture per feature (`presentation → domain ← data`). No backend, no cloud — all data lives on one device.

## 2. Folder structure (actual)

```
lib/
  main.dart                    # initDependencies() then MaterialApp.router + BlocProvider
  app.dart                     # AppScreen + bottom nav (Dashboard/Produk/Riwayat/Pengaturan)
  injection_container.dart     # get_it wiring; `sl` + initDependencies(). Opens the DB.
  core/
    database/                  # app_database.dart (tables), dao/, app_database.steps.dart, *.g.dart
    errors/failures.dart
    router/app_router.dart
    theme/                     # app_color, app_spacing, app_radius, app_text_style
    utils/                     # page_routes.dart, currency_formatter.dart (no date formatter yet)
  features/
    product/                   # data/model+repositories, domain/entities+repositories+usecases, presentation/bloc+screens+widgets
    setting/                   # PIN: repository + usecases + bloc + screens + pin_gate.dart
    transaction/  dashboard/  report/
build.yaml                     # drift_dev config for make-migrations — required
drift_schemas/                 # schema snapshot per version — COMMIT THESE, they are migration history
test/drift/                    # generated migration tests + seed tests
test/features/                 # repository / bloc / widget tests
test/injection_container_test.dart  # resolves the whole DI graph — catches runtime-only wiring breaks
test/widget_test.dart          # STALE counter template — broken, ignore it (makes bare `flutter test` fail)
docs/struktur_folder.md        # ASPIRATIONAL — differs from code, do not follow blindly
```

## 3. Code conventions (required)

- Layering: `presentation → domain ← data`. Never touch Drift/DAO from widgets or blocs; go through `domain/repositories` (interface) + usecases.
- State: Bloc + Freezed (`*_event.dart`, `*_state.dart`, `*.freezed.dart`). Reactive lists use `watch*` streams + `emit.forEach` (see `product_bloc.dart`).
- Errors: repositories return `Either<Failure, T>` (dartz); `Failure` subclasses live in `core/errors/failures.dart`. Entities/models extend `Equatable`.
- Money: always `int` rupiah, never `double`. Snapshot price in `priceAtSale` per transaction item — history must not change when product price changes.
- Drift: tables in `app_database.dart`, queries in `dao/`. After any table/DAO/Freezed edit → run codegen. Schema change → add migration in `AppDatabase.migration.onUpgrade`; never bump `schemaVersion` without a migration.
- Sale + stock decrement must be atomic (one DB transaction). Void = set `status='voided'` + `voidReason` (soft delete, never delete rows) and record a `stock_movements` entry.
- `PRAGMA foreign_keys = ON` lives in `AppDatabase.beforeOpen`, outside `transaction()` and after `onUpgrade`. Without it SQLite ignores every `references` and sold products can be hard-deleted. Never remove it (ADR-008).
- Every stock change writes exactly one `stock_movements` row in the same transaction. Only `ProductDao.restock` / `adjustStock` / `addProduct` (initial stock) and `TransactionDao` may change stock; `updateProduct` deliberately ignores the `stock` column. `decrementStock`/`incrementStock` write NO ledger row — do not use them for sales (ADR-011).
- Schema change → snapshot the OLD version with `dart run drift_dev make-migrations` BEFORE editing tables, then bump `schemaVersion`, re-run it, and fill `stepByStep`. Commit `drift_schemas/` and `app_database.steps.dart` (ADR-004).
- Money input: parse with `parseRupiah`, display with `formatRupiah` (`core/utils/currency_formatter.dart`).
- Navigation: add routes via `PageRoutes` constants + `app_router.dart`. Bottom tabs = `StatefulShellBranch`; full-screen routes (cashier) = top-level `GoRoute`.
- UI: use `AppColor/AppSpacing/AppRadius/AppTextStyle` tokens; format via `currency_formatter`.
- Tests: flows that hit the DB go in repository/bloc tests (plain `test()`, real async). `testWidgets` runs in fake-async, so Drift streams stall and `pumpAndSettle` times out — keep widget tests to pure-UI assertions. Fake plugins via their platform interface (`FlutterSecureStoragePlatform.instance`, `PathProviderPlatform.instance`), never via a wrapper in production code (ADR-012).

## 4. Run / test / build

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after Drift/Freezed edits
flutter run          # barcode/Bluetooth features need a physical Android device
flutter analyze
flutter test test/drift test/features test/injection_container_test.dart   # the real suite
flutter test test/some_file_test.dart   # single file; bare `flutter test` fails on widget_test.dart
dart run drift_dev make-migrations      # schema snapshot + migration steps + test template
flutter build apk --release
```

## 5. Do not (PRD §1.4 out-of-scope + production rules)

- No new features for: cloud sync / multi-device / multi-outlet / auto cloud backup, QRIS/transfer/card payment, multi-user login (one PIN only), loyalty/customer data, marketplace/accounting/WhatsApp integrations, Excel export, supplier/PO, discounts/promos/tax/partial returns, product variants/modifiers/table management, customer debt, cashier shift/cash close, iOS/web targets, in-app CSV import, cash drawer.
- Never store money as `double`. Never hard-delete transactions.
- Never store the PIN raw in the DB (hash in secure storage); PIN gates void, restore, and price/cost edits.
- Never commit `*.g.dart`/`*.freezed.dart` regenerated by hand — rerun build_runner instead.

