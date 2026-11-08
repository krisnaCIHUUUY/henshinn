# StatTile

Satu angka ringkasan di layar Laporan dengan labelnya.

**Isi layar Laporan (F4), dari atas:**
1. Chip rentang: Hari ini · 7 hari · 30 hari · Pilih tanggal.
2. StatTile **hero** lebar penuh: Omzet (`amount`).
3. Dua StatTile: **Laba kotor** dan **Transaksi** (`stat`). Laba = Σ (harga jual − harga modal) dari snapshot di transaction_items, transaksi void tidak dihitung.
4. Daftar **Terlaris** (5 teratas, ProductRow dengan jumlah terjual di kanan).
5. Daftar **Perlu restok** (badge `warning`).

Target metrik PRD: laba dan terlaris hari ini terlihat dalam ≤ 2 tap — buka tab Laporan, sudah tampil.

**Terkunci:** angka laba di balik PIN (PRD 1.6). Tile menampilkan "Tap untuk lihat" dengan ikon gembok; setelah PIN benar, terbuka sampai aplikasi ditutup.

**Tidak ada:** grafik 7 hari, perbandingan "vs kemarin", rata-rata per transaksi. Bisa ditambah setelah MVP.
