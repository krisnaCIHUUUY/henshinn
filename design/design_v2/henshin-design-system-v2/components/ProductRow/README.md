# ProductRow

Satu produk dalam daftar: inisial, nama, kategori/stok, dan harga jual rata kanan.

Dipakai di dua tempat dengan satu bentuk:
- **Produk (F2):** tap membuka form produk. Info bawah: "Kategori · Stok 14", atau badge `Sisa 3` / `Habis`.
- **Hasil cari di Kasir (F1):** tap langsung menambah 1 ke keranjang dan memberi umpan balik singkat (getar + baris CartRow berwarna `primary-soft` sesaat). Tidak ada tombol "+" kecil terpisah — seluruh baris adalah tombol (v1 punya tombol + 28px yang terlalu kecil).

**State:** normal, stok menipis (badge `warning`), habis (badge `danger`, nama dan harga `ink-muted`, di kasir tidak bisa ditambahkan), nonaktif (hanya di Produk).

**Ukuran:** tinggi minimum `row-min` (64px), padding `space-3` × `space-4`, pemisah `line`. Nama satu baris, terpotong dengan elipsis.

**Tidak ada:** gambar produk, harga modal (harga modal hanya di form, di balik PIN), tombol edit/hapus di baris.
