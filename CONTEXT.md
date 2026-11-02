# Henshin POS

Kasir offline untuk satu warung, satu HP, satu pemegang. Glosarium ini mengikat
istilah yang dipakai di kode, tes, dan dokumen — kalau sebuah istilah ada di
sini, jangan pakai sinonimnya.

## Language

**Kategori**:
Label pengelompokan produk yang hanya dipakai untuk mempersempit daftar produk
saat mencari. Bukan data pelaporan dan tidak pernah muncul di struk.
_Hindari_: grup, jenis, tipe produk

**Filter Semua**:
Keadaan daftar produk ketika tidak ada kategori yang dipilih. Bukan sebuah
kategori dan tidak punya baris di database.
_Hindari_: kategori "Semua", kategori default

**Umum**:
Kategori bawaan yang lahir bersama database supaya setiap produk selalu punya
kategori. Tidak istimewa selain itu.
_Hindari_: kategori kosong, tanpa kategori

**Produk**:
Barang yang dijual, dengan harga jual dan harga modal sendiri. Selalu tepat
satu kategori.
_Hindari_: item, barang, SKU

**Void**:
Pembatalan transaksi yang sudah tersimpan. Transaksinya tetap ada dan tetap
terlihat di riwayat, hanya ditandai batal.
_Hindari_: hapus transaksi, refund, retur

**Backup**:
Salinan utuh database pada satu titik waktu, dibuat pemilik lewat share sheet.
_Hindari_: export, sinkronisasi, snapshot otomatis
