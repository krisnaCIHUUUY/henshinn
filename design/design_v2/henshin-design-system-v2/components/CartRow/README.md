# CartRow

Satu baris keranjang di Kasir: nama, harga satuan × qty, subtotal, dan stepper − qty +.

- **Stepper:** tombol 40×40 dengan area sentuh 48. Saat qty 1, tombol "−" berubah menjadi ikon hapus berwarna `danger` (US-1.3: koreksi tanpa membatalkan transaksi). Tap angka qty membuka keyboard angka untuk qty besar.
- **Baru ditambahkan:** latar `primary-soft` selama ±600ms, lalu kembali `surface`. Kalau produk yang sama di-scan lagi, qty baris itu yang naik — bukan baris baru.
- **Stok tidak cukup:** tombol "+" disabled dan teks bawah menjadi "Stok tinggal 2" dengan warna `warning`.

**Isi:** nama (`body`), "Rp 18.000 × 2" (`label`, `ink-muted`), subtotal (`body-strong`, angka tabular, rata kanan). Urutan baris = urutan ditambahkan, terbaru di atas.
