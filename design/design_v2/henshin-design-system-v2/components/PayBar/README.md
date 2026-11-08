# PayBar

Bilah bawah layar Kasir yang selalu terlihat: jumlah item, total, dan tombol Bayar.

**Alur (F1, target ≤ 30 detik untuk 3 item):**
1. Keranjang kosong → PayBar tersembunyi; layar menampilkan field cari + scan.
2. Ada item → PayBar muncul: "3 produk" (`label`), total (`amount`), tombol **Bayar** (`primary`, 56px).
3. Tap Bayar → Sheet pembayaran: field Uang diterima + tombol cepat (Uang pas, 50.000, 100.000), kembalian dihitung langsung dengan warna `success`, tombol **Selesai**.
4. Selesai → transaksi tersimpan dulu, baru struk dicetak. Kalau printer gagal, muncul Notice "Struk belum tercetak" dengan aksi **Coba lagi** / **Share PDF** — transaksi tetap aman (US-1.4).

**Aturan:** total memakai angka tabular supaya tidak "melompat" saat berubah. PayBar memakai `shadow-sheet` karena melayang di atas daftar. Tidak ada tombol Diskon atau Pajak (di luar scope).
