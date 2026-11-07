# BottomNav

Empat tab utama: Kasir · Produk · Riwayat · Laporan.

**Perubahan dari v1:** v1 punya Dasbor · Produk · Riwayat · Pengaturan, dan Kasir dibuka dari tombol "Mulai transaksi baru" di Dasbor. v2 menjadikan **Kasir** tab pertama dan layar pembuka (satu tap lebih sedikit untuk setiap transaksi), menggabungkan Dasbor + Laporan menjadi **Laporan** (F4), dan memindahkan **Pengaturan** ke ikon gear di app bar Laporan (pemilik, bukan kasir).

**Bentuk:** `surface`, garis atas `line`, ikon outlined 24px + label `caption`. Tab aktif: ikon dan label `primary`, pil `primary-soft` di belakang ikon. Badge titik `warning` di tab Laporan bila backup > 7 hari atau ada produk perlu restok.

**Flutter:** `NavigationBar` Material 3 dengan `indicatorColor: AppColor.primarySoft`, tetap di `StatefulShellRoute`. Kasir pindah dari GoRoute top-level ke branch pertama.
