# Receipt

Preview struk 58mm (32 karakter per baris) dari model `Receipt` yang sama dengan byte ESC/POS dan PDF (PRD 2.8).

**Isi, dari atas:** nama toko (tengah, tebal), alamat, garis `-`, nomor & waktu, item ("nama" lalu "qty x harga ... subtotal"), garis, TOTAL, Tunai, Kembali, garis, pesan struk dari Pengaturan. Transaksi void yang dicetak ulang diberi baris `*** VOID ***` di atas dan bawah.

**Aksi di layar preview:** **Cetak** (`primary`) bila printer terhubung, **Share PDF** (`secondary`) selalu ada — ini juga jalur cadangan selama printer belum tiba (PRD 3.2).

**Aturan:** gaya `receipt` (Roboto Mono 13px) hanya di sini. Angka rata kanan, tanpa "Rp" di baris item agar muat 32 karakter; "Rp" hanya di TOTAL.
