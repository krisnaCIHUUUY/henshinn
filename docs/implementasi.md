# Rencana Implementasi Henshin POS

Rencana langkah demi langkah berdasarkan `docs/henshin_prd.md` dan arsitektur `AGENTS.md`.
Belum ada kode sampai tiap langkah disetujui.

**Asumsi awal (kondisi repo saat ini):**
- Tabel Drift v1 + DAO sudah ada (`lib/core/database/app_database.dart`), `ProductBloc` sudah ada.
- `injection_container.dart` masih kosong.
- Lib printer/backup/PIN (`esc_pos_bluetooth`/printer plugin, `pdf`, `share_plus`, `file_picker`, `flutter_secure_storage`, `crypto`, `fl_chart`) belum ada di `pubspec.yaml`.

---

## Fondasi (dependency untuk semua fitur)

### 1. Kunci DI + wiring database
Pasang `AppDatabase` singleton + DAO + repository impl + usecase di `injection_container.dart`, expose via `RepositoryProvider/BlocProvider` di `main.dart`.
- **Tes terpisah:** `flutter analyze` + app boot tanpa error provider-missing.
- **Ukuran:** kecil.

### 2. Migrasi DB + seed kategori awal
Isi `onUpgrade` skeleton yang teruji + seed 1 kategori default agar FK `categoryId` tidak orphan. Tambah kolom yang kurang dari PRD §2.6: `products.costPrice`, `products.lowStockThreshold`, `products.isActive`, tabel `settings`.
- **Tes terpisah:** install fresh + upgrade dari v1 ke v2 dengan data dummy, tidak corrupt.
- **Ukuran:** kecil.

### 3. Settings + PIN (hash, bukan plaintext)
Tambah `flutter_secure_storage` + `crypto`; layar buat/verifikasi PIN; gate untuk void, restore, ubah harga/modal, lihat laba (PRD §1.6 asumsi PIN).
- **Tes terpisah:** buat PIN → tutup app → verifikasi benar/salah; cek PIN tidak ada di DB.
- **Ukuran:** sedang.
- **⚠ RISIKO SEDANG** — scope PIN masih asumsi PRD, belum konfirmasi pemilik; keputusan ini mengunci UX void/restore.

---

## F2 — Produk & Stok (fondasi fitur; F1/F3/F4 tergantung padanya)

### 4. CRUD produk + validasi harga/stok
Form produk (nama, barcode nullable unik, kategori, jual, modal, stok awal, threshold, aktif). Uang `int` rupiah.
- **Tes terpisah:** tambah/ubah/hapus produk → list reaktif via `watch*` ter-update.
- **Ukuran:** kecil-sedang.

### 5. Restok + `stock_movements` ledger + peringatan stok menipis
Setiap perubahan stok (jual/restok/void/koreksi) tulis 1 baris `stock_movements`; query low-stock (`stock <= threshold`).
- **Tes terpisah:** unit test repository: restok +50 → stok + ledger cocok; list low-stock benar.
- **Ukuran:** kecil.

---

## F1 — Kasir & Struk (tergantung Langkah 4–5)

### 6. Keranjang in-memory + bayar + kembalian + simpan atomik
Cart (tambah/ubah qty/hapus), total+kembalian otomatis, simpan `transactions` + `transaction_items` (snapshot `priceAtSale`) + decrement stok dalam 1 transaksi Drift.
- **Tes terpisah:** buat transaksi 3 item → total/kembalian benar, stok turun, reload app data tetap ada.
- **Ukuran:** sedang.
- **⚠ RISIKO TINGGI** — keatoman transaksi-stok adalah "tidak boleh dipotong" (PRD §3.2); bug di sini merusak akurasi stok (metrik ≤5%).

### 7. Scan barcode kamera
Tambah permission kamera + `mobile_scanner` di layar kasir; barcode tidak dikenal → fallback cari manual/tambah cepat.
- **Tes terpisah:** scan di device fisik → produk masuk keranjang ≤2 detik.
- **Ukuran:** kecil.
- **⚠ RISIKO SEDANG** — wajib device fisik, emulator tidak cukup (PRD §1.6); UX fallback belum jelas.

### 8. Model `Receipt` tunggal + preview layar + PDF/share fallback
Satu model dipakai untuk preview, PDF, dan nanti ESC/POS byte. Lebar 58mm (~32 char/baris).
- **Tes terpisah:** transaksi dummy → preview tampil + PDF ter-share via WhatsApp/Drive.
- **Ukuran:** sedang.

### 9. Cetak ESC/POS Bluetooth thermal
`PrinterService` interface + impl plugin; handle izin Bluetooth Android 12+, pairing, retry; transaksi tetap tersimpan walau cetak gagal (US-1.4).
- **Tes terpisah:** 50x cetak, target ≥95% sukses first-try (metrik PRD).
- **Ukuran:** sedang.
- **⚠ RISIKO TINGGI** — alasan: (a) printer fisik belum ada, (b) plugin belum ada di `pubspec` dan status maintenance belum dicek, (c) perilaku Bluetooth tiap merk 58mm beda. Fallback Langkah 8 wajib jadi duluan.

---

## F3 — Riwayat, Void, PIN (tergantung Langkah 6)

### 10. Riwayat + detail + cetak ulang
List + filter status/tanggal, detail item + snapshot harga, tombol cetak ulang (pakai model `Receipt` Langkah 8).
- **Tes terpisah:** 20 transaksi dummy → list + detail + reprint benar.
- **Ukuran:** kecil.

### 11. Void ber-PIN + alasan + stok kembali otomatis
Void = update `status='voided'` + `voidReason` (soft-delete), kembalikan stok + tulis ledger, wajib PIN + alasan tidak kosong.
- **Tes terpisah:** void → status berubah, stok kembali, laporan tidak hitung yang void.
- **Ukuran:** kecil.
- **⚠ RISIKO SEDANG** — aturan audit pemilik; salah implementasi (hard-delete) melanggar PRD.

---

## F4 — Dashboard & Laporan (tergantung Langkah 6 + 11)

### 12. Dashboard hari ini + laporan preset + produk terlaris
Omzet, laba kotor (jual−modal dari snapshot), jumlah transaksi; preset Hari ini/7 hari/30 hari saja (garis potong PRD §3.2, tanpa rentang bebas dulu); top-seller via agregat Drift.
- **Tes terpisah:** seed data 30 hari → angka dashboard = hitung manual; void excluded.
- **Ukuran:** sedang.

---

## F5 — Backup & Restore (wajib MVP, tidak boleh dipotong)

### 13. Export (`VACUUM INTO`) + share + pengingat 7 hari
Snapshot konsisten → share sheet (Drive/WA); simpan `lastBackupAt` di settings; banner pengingat jika >7 hari.
- **Tes terpisah:** export → file `.db` valid dibuka di SQLite viewer.
- **Ukuran:** kecil-sedang.
- **⚠ RISIKO TINGGI** — alasan: satu-satunya safety net data (PRD §1.6); approach `VACUUM INTO` + izin storage Android sensitif versi OS; tanpa uji restore, backup = ilusi aman.

### 14. Import + validasi + PIN gate + safety copy
File picker → validasi header SQLite + tabel wajib + versi skema → salinan pengaman sebelum timpa → restore wajib PIN → PIN baru di HP baru (PIN tidak ikut di-backup, PRD §2.7).
- **Tes terpisah:** backup → hapus data → restore → data identik 100% (metrik PRD).
- **Ukuran:** sedang.
- **⚠ RISIKO TINGGI** — alasan sama dengan Langkah 13 + risiko timpa data aktif jika validasi longgar.

---

## Hardening (terakhir)

### 15. Mode pesawat end-to-end + pilot checklist
Uji F1→F5 offline penuh, ukur median transaksi 3 item ≤30 dtk, crash-free ≥99%, siapkan skenario UAT + baseline 10 transaksi manual (PRD §1.5).
- **Tes terpisah:** checklist lolos/tidak per alur.
- **Ukuran:** besar tapi non-koding dominan.

---

## Urutan dependency

```
1 → 2 → 3 → 4 → 5 → 6 → (7, 8 paralel) → 9 → 10 → 11 → 12 → 13 → 14 → 15
```

Fondasi (1–3) → F2 (4–5) → F1 (6–9) → F3 (10–11) → F4 (12) → F5 (13–14) → Hardening (15).

**Logika urutan:** fondasi menutup semua fitur; F2 dulu karena F1 (transaksi) menulis stok dan F4 (laporan) membaca harga/modal; F5 terakhir karena butuh data produksi untuk uji restore end-to-end yang kredibel.
