# Button

Tombol untuk satu aksi; hanya satu `primary` yang terlihat di tiap layar.

| Varian | Kapan | Contoh |
|---|---|---|
| `primary` | Aksi yang menjadi tujuan layar. Tinggi `tap-primary` (56px), biasanya lebar penuh di bawah. | Bayar, Simpan produk, Buat backup |
| `secondary` | Aksi pendamping di samping primary. `surface-muted` + `ink`. | Batal, Cetak ulang, Share PDF |
| `ghost` | Aksi ringan di dalam daftar atau app bar. Teks `primary`. | Lihat semua, Ubah |
| `danger` | Hanya tombol konfirmasi terakhir yang merusak data, di dalam Sheet setelah PIN. | Void transaksi, Hapus produk, Timpa data |

**State:** default, ditekan (`primary-pressed`), disabled (`surface-muted` + `ink-muted`, mis. Bayar saat uang diterima kurang dari total), loading (spinner menggantikan ikon, label tetap, tombol tidak bisa ditekan lagi — mencegah transaksi tersimpan dua kali).

**Aturan:**
- Label diawali kata kerja, maksimal 3 kata. "Bayar Rp 54.000" boleh di PayBar.
- Jangan pakai `danger` untuk tombol yang membuka konfirmasi; tombol pembuka void di detail transaksi adalah `secondary` dengan teks `danger`.
- Ukuran minimum `tap-min` (48px) untuk semua varian.

**Flutter:** `FilledButton` (primary/danger), `FilledButton.tonal` (secondary), `TextButton` (ghost), tema dari `AppTheme`.
