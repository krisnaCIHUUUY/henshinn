# Field

Satu input dengan label di atas; tiga jenis: teks, uang, dan pencarian dengan tombol scan.

| Jenis | Kapan | Catatan |
|---|---|---|
| `text` | Nama produk, barcode, alasan void, info toko | Keyboard teks. |
| `money` | Harga jual, harga modal, uang diterima, jumlah restok | Prefix "Rp" `ink-muted`, keyboard angka, format titik ribuan saat mengetik, simpan lewat `parseRupiah`. |
| `search` | Cari produk di Kasir dan Produk | Ikon cari di kiri, tombol scan `primary` 48×48 di kanan (F1, FR-05). Hasil muncul sambil mengetik. |

**State:** default (batas `line-strong` 1px), fokus (`primary` 2px), error (`danger` 2px + pesan di bawah dengan teks `danger`), disabled (`surface-muted`, tanpa batas).

**Aturan:**
- Label selalu terlihat di atas, bukan hanya placeholder — kasir perlu tahu field mana yang sedang diisi.
- Pesan error menyebut cara memperbaiki: "Harga jual harus lebih dari harga modal", bukan "Input tidak valid".
- Field harga dan modal di form produk membuka PinPad saat produk sudah ada (ubah harga butuh PIN, PRD 1.6).
- Uang diterima di kasir punya tombol cepat di bawahnya: "Uang pas", "Rp 50.000", "Rp 100.000".
