# Notice

Pesan sebaris-dua di dalam layar, dengan satu aksi opsional.

| Tone | Kapan | Contoh |
|---|---|---|
| `warning` | Pengingat yang tidak menghalangi | "Backup terakhir 9 hari lalu" + **Backup sekarang** (US-5.3, tampil di Laporan dan Pengaturan bila > 7 hari) |
| `danger` | Sesuatu gagal tapi data aman | "Struk belum tercetak. Transaksi sudah tersimpan." + **Coba lagi** |
| `success` | Hasil yang perlu dikonfirmasi | "Backup tersimpan · 7 Nov, 20.14" |

**Aturan:** judul tebal satu kalimat, penjelasan satu kalimat, maksimal satu aksi bergaris bawah. Notice tidak hilang sendiri; untuk konfirmasi cepat (mis. "Produk disimpan") pakai SnackBar Flutter biasa dengan warna `ink`. Selalu sebut bahwa data aman bila memang aman — itu kekhawatiran utama pemilik.
