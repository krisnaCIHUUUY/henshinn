# Kategori baru dibuat dari form produk, tab kosong disembunyikan

Status: ready-for-agent
Type: task

Hasil sesi `/grill-with-docs` 2026-11-02. Pemilik repo minta dikerjakan nanti —
jangan mulai tanpa diminta ulang.

## Masalah

Tab kategori di daftar produk hanya pernah berisi "Semua" dan "Umum", dan
**tidak ada apa pun di aplikasi yang bisa membuat kategori**.
`CategoryDao.addCategory` / `updateCategory` / `deleteCategory` ada tapi tidak
dipanggil dari mana pun (dicek di `lib/` dan `test/`, 2026-11-02). `'Umum'`
lahir dari seed langkah 2 semata-mata supaya FK `products.categoryId` tidak
orphan. PRD §F2 menyebut kategori sebagai **kolom produk**, bukan entitas yang
dikelola, jadi ini lubang di rencana, bukan bug.

## Keputusan pemilik (lima, sudah final)

1. **Kategori = alat cari cepat** di daftar produk. Bukan data laporan, tidak
   muncul di struk. Karena itu tidak ada aturan "kategori tidak boleh dihapus
   karena laporan lama memakainya".
2. **Dibuat dari form produk**, bukan layar sendiri: dropdown kategori dapat
   opsi "+ Kategori baru", nama diketik di situ, kategori dibuat saat produk
   disimpan.
3. **Tidak ada hapus dan ganti nama.** Gantinya: tab hanya tampil untuk
   kategori yang punya produk, jadi salah ketik sembuh sendiri begitu
   produknya dipindah. Barisnya tetap di DB.
4. **Nama dicari tanpa peka huruf besar/kecil** sebelum insert. "minuman" saat
   "Minuman" sudah ada → masuk ke kategori lama, tanpa pesan error.
5. **Tanpa unique index di DB** — jaminan di kode saja. Satu HP satu pemakai,
   dan bump `schemaVersion` sekarang akan menambah variabel ke uji restore
   langkah 14.

## Yang perlu dikerjakan

1. `ProductRepositoryImpl`: jalur "cari-atau-buat" kategori berdasarkan nama,
   perbandingan tanpa peka huruf. Ini satu-satunya pemakai pertama
   `CategoryDao.addCategory`.
2. `product_form_screen.dart` (~baris 178, 347): opsi "+ Kategori baru" di
   dropdown + field nama yang muncul saat opsi itu dipilih. Validator
   `'Pilih kategori'` yang ada sekarang tetap berlaku.
3. `product_list_screen.dart:251`: tab difilter ke kategori yang punya produk.
   Produknya sudah ada di state yang sama, jadi ini filter satu baris.
4. `CategoryDao.updateCategory` dan `deleteCategory` tetap tidak akan terpakai
   setelah ini — hapus keduanya, jangan tinggalkan sebagai kode mati.
5. Tes: cari-atau-buat (nama baru, nama persis sama, nama beda huruf besar
   kecil), dan tab kategori kosong tidak ikut terbangun.
6. ADR-038 di `docs/keputusan-arsitektur.md` (**bukan** `docs/adr/`): kenapa
   tidak ada hapus, kenapa tab kosong disembunyikan, kenapa tanpa unique index.
   Lolos ketiga syarat ADR: sulit dibalik, mengejutkan tanpa konteks, hasil
   pertukaran nyata.

## Satu pertanyaan terbuka

`watchAllProducts` belum dicek apakah menyertakan produk `isActive = false`.
Kalau ya, kategori yang isinya hanya produk non-aktif tetap memunculkan tabnya.
Rekomendasi: hitung hanya produk aktif, karena kategori gunanya alat cari dan
produk non-aktif tidak dicari kasir. Putuskan saat implementasi, tidak perlu
tanya pemilik.

## Efek samping yang harus dipahami

Tab "Umum" akan **hilang sendiri** begitu semua produk punya kategori nyata.
Itu benar secara desain, tapi akan terasa seperti kerusakan kalau tidak
diharapkan — sebut ini di ringkasan saat mengerjakannya.

Istilahnya sudah dikunci di `CONTEXT.md`: **Kategori**, **Filter Semua** (tab
pertama, bukan kategori, tidak punya baris DB), dan **Umum**.
