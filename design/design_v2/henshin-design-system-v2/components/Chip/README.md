# Chip

Pilihan tunggal untuk mempersempit daftar: kategori produk atau preset rentang tanggal laporan.

- **Filter kategori (F2, Kasir):** chip pertama selalu **Semua** (Filter Semua di glosarium, bukan sebuah kategori), lalu kategori urut abjad. Bergeser horizontal kalau tidak muat.
- **Rentang laporan (F4):** **Hari ini · 7 hari · 30 hari · Pilih tanggal**. Tiga preset ini juga garis potong PRD 3.2 kalau pilih tanggal bebas belum sempat dibuat.

**State:** tidak aktif (`surface` + batas `line-strong`), aktif (`primary-soft` + batas dan teks `primary`). Selalu tepat satu yang aktif.

**Aturan:** bentuk pil (`radius-full`) hanya untuk chip, supaya tidak tertukar dengan tombol. Tinggi visual 40px, area sentuh 48px. Jangan pakai chip untuk aksi.
