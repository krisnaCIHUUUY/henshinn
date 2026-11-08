# PinPad

Keypad angka untuk memasukkan PIN pemilik, tampil di dalam Sheet.

**Dipakai untuk (PRD 1.6):** void transaksi, restore backup, ubah harga jual/modal produk yang sudah ada, membuka angka laba. Pembuatan PIN pertama memakai PinPad yang sama dua kali ("Buat PIN" lalu "Ulangi PIN").

**Bentuk:** judul aksi di atas ("Masukkan PIN untuk void"), 6 titik, grid 3×4 tombol 56px dengan gap `space-2`: 1–9, kosong, 0, hapus. Tidak ada tombol OK — PIN langsung dicek saat digit terakhir diisi.

**State:** kosong, terisi sebagian (titik `ink`), salah (titik `danger`, teks "PIN salah. Coba lagi." di bawah, getar, titik dikosongkan), terkunci sementara setelah 5 kali salah ("Coba lagi dalam 30 detik").

**Aturan:** angka tidak pernah ditampilkan. Tombol 56px karena dipakai dengan jempol di HP yang dipegang satu tangan.
