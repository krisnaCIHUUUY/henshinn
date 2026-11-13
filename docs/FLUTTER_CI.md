# Build Henshin APK lewat GitHub Actions

## Context
Henshin belum punya CI (`.github/` tidak ada). User mau APK dibangun otomatis di
GitHub Actions dan dipublikasikan sebagai **GitHub Release**. Keputusan user:
- Signing: **debug key dulu** (tanpa secrets; `android/app/build.gradle.kts:36` sudah begitu).
- Trigger: **push / PR ke `main` dan `develop`**.
- Output: **GitHub Release**.

Sumber (context7): `/subosito/flutter-action` (setup Flutter + cache, contoh `flutter build apk`)
dan `/flutter/website` deployment/android (signing — ditunda).

Temuan yang membentuk rencana:
- `*.g.dart` / `*.freezed.dart` sudah di-commit (12 file) → CI **tidak perlu** `build_runner`.
- Flutter lokal 3.47.1 (Dart 3.13.1); pubspec tidak menyimpan versi Flutter exact → pin
  `flutter-version: 3.47.1` di workflow.
- Java 17 (`build.gradle.kts:13-14,43`) → `actions/setup-java` temurin 17 + cache gradle.
- **Blocker:** `flutter analyze` gagal (exit 1) karena `pubspec.yaml:96-97` mendaftarkan
  `assets/` yang tidak ada di repo mana pun dan tidak dipakai `lib/`.
- `dart format --set-exit-if-changed` akan gagal di 49 file → gate format **tidak** dipasang sekarang.

## Perubahan

### 1. `pubspec.yaml` — hapus baris 96-97
```yaml
  assets:
    - assets/
```
(baris komentar di sekitarnya dibiarkan). Ini membuat `flutter analyze` bersih.

### 2. Baru: `.github/workflows/build.yml`
```yaml
name: Build APK

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

permissions:
  contents: write   # gh release create

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 17
          cache: gradle
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.47.1
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
      - name: Publish GitHub Release
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk henshin-${{ github.run_number }}.apk
          gh release create "build-${{ github.run_number }}" henshin-${{ github.run_number }}.apk \
            --target "$GITHUB_SHA" --title "Henshin build #${{ github.run_number }}" \
            --prerelease --generate-notes
```
Perilaku:
- PR & push ke `develop` → analyze + test + build APK (validasi saja, tanpa release).
- Push ke `main` (termasuk merge PR) → sama + Release `build-N` berisi APK.
- `--prerelease` karena APK ditandatangani debug key — tidak bisa ke Play Store dan
  tidak bisa di-upgrade oleh build yang nanti ditandatangani keystore asli.
- `gh` CLI sudah ada di runner → tanpa action pihak ketiga untuk release.

## Sengaja dilewati
- Gate `dart format` (49 file belum terformat) — perlu satu commit `dart format .` dulu.
- Signing keystore via Secrets, `.aab`, iOS, cache key custom, coverage upload.
- Update `docs/progress.md` / ADR — ini bukan langkah `implementasi.md`; commit message
  diserahkan setelah owner verifikasi (AGENTS.md §5).

## Verifikasi
1. Lokal: `flutter analyze` (harus 0 issue), `flutter test`, `flutter build apk --release`.
2. Push branch ini + buka PR ke `develop` → cek run "Build APK" hijau di tab Actions
   (analyze/test/build jalan, step Release ter-*skip*).
3. Setelah merge ke `main` → cek ada Release `build-N` (prerelease) dengan `henshin-N.apk`;
   unduh dan install di HP Android.
