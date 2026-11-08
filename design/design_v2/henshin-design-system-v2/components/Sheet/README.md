# Sheet

Bottom sheet untuk satu tugas pendek tanpa meninggalkan layar: pembayaran, restok, alasan void, PIN, pilih printer.

**Bentuk:** `surface`, sudut atas `radius-lg`, `shadow-sheet`, handle di atas, judul `heading`, isi, lalu baris aksi di bawah (secondary kiri, primary/danger kanan). Padding `space-4`.

**Isi yang sudah ditentukan:**
| Sheet | Isi | Aksi |
|---|---|---|
| Pembayaran (F1) | Total, field Uang diterima, tombol cepat, kembalian | Selesai |
| Restok (F2) | Nama produk, stok sekarang, field Jumlah tambah | Simpan restok |
| Void (F3) | Ringkasan transaksi, pilihan alasan (Salah input · Pembeli batal · Lainnya + field). Tap Void → isi Sheet berganti PinPad; PIN benar langsung mem-void. | Void transaksi (`danger`) |
| Restore (F5) | Nama file + tanggal backup, peringatan "Data di HP ini akan diganti", → PinPad | Timpa data (`danger`) |

**Aturan:** satu Sheet, satu tugas. Tidak bertumpuk — PinPad menggantikan isi Sheet, bukan Sheet kedua. Tap di luar atau geser ke bawah = batal, kecuali saat menyimpan.
