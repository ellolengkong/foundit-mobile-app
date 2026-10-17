# FoundIt — UI/UX Design Specification

**Product:** FoundIt — Lost & Found UNSRAT  
**Tagline:** *Lost Today, Found Tomorrow.*  
**Dokumen:** Rancangan UI/UX MVP v1.1 — Modern & Friendly  
**Platform:** Android (Flutter)

## 1. Arah Visual dan Prinsip Desain

FoundIt ditujukan kepada mahasiswa. Visualnya harus terasa **modern, ringan, ramah, dan dapat dipercaya**—bukan seperti dashboard administrasi kampus, tetapi juga tidak terlalu ramai seperti aplikasi hiburan.

**Arah visual:** *soft modern utility*. Gunakan warna indigo sebagai identitas, latar sedikit keabu-abuan, tipografi yang hangat, komponen membulat, dan ruang kosong yang cukup. Hindari gradien mencolok, banyak warna aksen sekaligus, bayangan tebal, serta animasi dekoratif yang tidak membantu tugas pengguna.

1. **Search-first:** kolom pencarian mudah ditemukan di bagian atas Beranda.
2. **Navigasi sederhana:** hanya tiga item navigasi utama: Beranda, tombol Lapor (+), dan Profil.
3. **Akses tamu:** pengguna boleh melihat, mencari, memfilter, dan membuka detail laporan tanpa login.
4. **Formulir singkat:** hanya meminta informasi yang dibutuhkan untuk membantu menemukan barang.
5. **Status jelas:** bedakan laporan hilang dan ditemukan dengan teks serta warna, bukan warna saja.
6. **Privasi sejak awal:** jangan tampilkan nomor kontak, nomor identitas, atau ciri khusus barang secara terbuka.
7. **Konsisten:** tombol, jarak, ukuran teks, dan pola interaksi harus sama di semua layar.
8. **Ramah, bukan kekanak-kanakan:** gunakan sudut lembut dan ilustrasi kosong sederhana bila diperlukan, tetapi hindari stiker, emoji berlebihan, dan warna neon.

## 2. Color Palette

Gunakan palet **Indigo + Soft Neutral**. Indigo memberi karakter produk digital modern, sedangkan latar yang lembut dan permukaan putih menjaga layar tetap tenang. Warna status hanya dipakai untuk menyampaikan makna.

| Token | Hex | Pemakaian |
|---|---|---|
| `primary` | `#5B5BD6` | Tombol utama, tautan penting, tab aktif, dan tombol + |
| `primaryPressed` | `#4545B8` | Kondisi ditekan dan variasi primer yang lebih gelap |
| `primarySoft` | `#EEEEFF` | Latar chip terpilih, ikon kecil, dan highlight ringan |
| `background` | `#F7F7FB` | Latar halaman utama yang lembut |
| `surface` | `#FFFFFF` | Formulir, kartu, dialog, dan bottom sheet |
| `textPrimary` | `#202033` | Judul dan teks utama |
| `textSecondary` | `#717187` | Metadata, tanggal, keterangan, dan teks sekunder |
| `border` | `#E7E7F0` | Batas input, pemisah, dan outline kartu |
| `found` | `#167D72` | Status “Ditemukan” dengan teks yang sesuai |
| `foundSoft` | `#E5F5F1` | Latar lembut status “Ditemukan” |
| `lost` | `#B95D32` | Status “Hilang” dengan teks yang sesuai |
| `lostSoft` | `#FFF0E8` | Latar lembut status “Hilang” |
| `error` | `#C43D4B` | Validasi gagal dan pesan kesalahan |
| `success` | `#18794E` | Konfirmasi aksi berhasil |

### Aturan penggunaan warna

- Gunakan `background` untuk latar halaman dan `surface` untuk kartu atau formulir. Tidak perlu membingkai setiap bagian dengan kartu terpisah.
- Gunakan `primary` secara selektif: satu aksi utama yang paling penting dalam satu layar. Tombol sekunder memakai gaya outline atau teks.
- `primarySoft` boleh menjadi latar chip terpilih, tetapi jangan mewarnai seluruh layar dengan indigo.
- Status “Hilang” memakai `lostSoft` dan teks `lost`; status “Ditemukan” memakai `foundSoft` dan teks `found`. Jangan menggunakan aksen merah/hijau terang secara berlebihan.
- Selalu sertakan label status seperti “Hilang”, “Ditemukan”, “Aktif”, atau “Selesai”; jangan menyampaikan status hanya dengan warna.
- Pastikan kontras teks tetap terbaca, terutama untuk tombol, label, serta teks kecil. Jangan gunakan `textSecondary` untuk informasi yang kritis.
- Hindari gradien neon, warna pelangi, dan bayangan berat. Jika butuh elevasi, gunakan bayangan yang sangat tipis hanya pada tombol + atau bottom sheet.

## 3. Tipografi, Spasi, dan Komponen

- **Font utama:** Plus Jakarta Sans. Karakternya kontemporer dan ramah, tetapi tetap profesional untuk aplikasi mahasiswa. Gunakan satu keluarga font secara konsisten agar tampilan tidak terasa ramai.
- **Fallback:** sans-serif bawaan sistem. Jika font dikemas di aplikasi, pastikan teks tetap ditampilkan normal ketika perangkat offline.
- **Judul halaman:** 24 sp, semi-bold/bold.
- **Judul bagian:** 18 sp, semi-bold.
- **Judul kartu:** 16 sp, semi-bold.
- **Isi:** 14–16 sp, regular.
- **Metadata:** 12–13 sp; jangan gunakan ukuran kecil untuk informasi penting.
- **Spasi dasar:** kelipatan 4 atau 8 dp, misalnya 8, 12, 16, 24, dan 32 dp.
- **Padding halaman:** sekitar 20 dp; gunakan 16 dp pada layar yang lebih sempit jika diperlukan.
- **Tinggi tombol utama:** 48–52 dp.
- **Sudut kartu:** 16 dp; input 12–14 dp; chip berbentuk pil. Jangan membuat semua komponen terlalu bulat.
- **Area sentuh:** kontrol interaktif idealnya minimal 48 × 48 dp.
- **Ikon:** gunakan satu set ikon outline yang konsisten. Gunakan ikon hanya untuk membantu pemahaman, bukan sebagai dekorasi.

### Gaya komponen

- **Kartu laporan:** foto berbentuk persegi kecil, informasi utama jelas, metadata ringkas, dan tanpa bayangan tebal. Gunakan border lembut atau pemisah seperlunya.
- **Pencarian:** bidang dengan latar `surface`, border lembut, ikon pencarian, dan placeholder yang jelas.
- **Chip kategori:** bentuk pil dengan latar netral; chip aktif memakai `primarySoft` dan teks `primary`.
- **Tombol utama:** latar `primary`, teks putih, sudut 14 dp. Hindari beberapa tombol primer dalam satu bagian.
- **Navigasi bawah:** latar putih, label pendek, ikon konsisten, dan indikator aktif indigo yang sederhana. Tombol + di tengah lebih menonjol tetapi tidak terlalu besar.
- **Status laporan:** gunakan chip berwarna lembut dengan label yang mudah dibaca.
- **Feedback:** animasi transisi singkat dan halus saja; jangan menunda aksi pengguna demi animasi.

### Komponen standar


- Search field dengan ikon pencarian dan tombol filter.
- Chip untuk kategori dan pilihan jenis laporan.
- Kartu laporan dengan foto/placeholder, nama barang, label status, lokasi, dan tanggal.
- Input dengan label yang selalu terlihat; jangan mengandalkan placeholder saja.
- Bottom sheet untuk filter agar pengguna tidak perlu meninggalkan Beranda.
- Dialog konfirmasi sebelum menghapus laporan atau menandai laporan selesai.
- Snackbar atau pesan konfirmasi singkat setelah aksi berhasil.

## 4. Navigasi Aplikasi

Navigasi utama memakai **tiga item di bagian bawah**:

```text
+------------------------------------------------+
|                                                |
|                 ISI HALAMAN                    |
|                                                |
+------------------------------------------------+
|       [⌂ Beranda]       [+ Lapor]   [○ Profil] |
+------------------------------------------------+
```

### Fungsi navigasi

- **Beranda:** daftar laporan aktif, pencarian, filter, dan akses ke rekomendasi kecocokan.
- **Lapor (+):** membuka formulir laporan. Jika pengguna belum login, arahkan ke Login/Daftar terlebih dahulu. Setelah login berhasil, lanjutkan langsung ke formulir.
- **Profil:** pengguna login melihat laporan miliknya dan pengaturan akun. Pengunjung melihat pilihan Masuk/Daftar.

### Aturan navigasi

- Pencarian utama berada di Beranda; tidak perlu item navigasi khusus “Cari”.
- Menekan kotak pencarian membuka layar hasil pencarian yang dapat memiliki filter tambahan.
- Bottom navigation tampil pada halaman utama: Beranda dan Profil. Tombol Lapor adalah aksi tengah yang menonjol.
- Pada Login, Daftar, Form Laporan, dan Detail Barang, bottom navigation boleh disembunyikan agar layar lebih fokus. Tombol kembali tetap tersedia.
- Tombol kembali mempertahankan kata kunci dan filter yang sebelumnya dipilih.
- Ketika pengguna login setelah menekan Lapor, aplikasi harus membuka Form Laporan, bukan mengembalikannya ke Beranda.
- Admin membuka dashboard berdasarkan peran akun. Akun biasa tidak boleh melihat atau mengakses fungsi admin.

## 5. Wireframe ASCII

Wireframe di bawah berfokus pada tata letak dan alur, bukan desain visual final. Label dan komponen dapat disempurnakan setelah uji coba.

### 5.1 Beranda — pengguna tamu maupun pengguna login

```text
+------------------------------------+
| FoundIt                        [○] |
| Lost Today, Found Tomorrow.        |
|------------------------------------|
| [ Cari nama barang...          ][≡]|
|------------------------------------|
| [Semua] [Hilang] [Ditemukan]       |
|------------------------------------|
| KATEGORI                           |
| [Elektronik] [Dompet] [Kartu]  ->  |
|------------------------------------|
| Kemungkinan cocok             [Lihat]
| Laporan yang mungkin sesuai        |
|------------------------------------|
| LAPORAN TERBARU                    |
| +--------+  Dompet hitam           |
| |  FOTO  |  [Ditemukan]            |
| |        |  Teknik · Gedung B3     |
| +--------+  15 Okt                 |
|------------------------------------|
| +--------+  KTM biru               |
| |  FOTO  |  [Hilang]               |
| |        |  FEB · Gedung/area      |
| +--------+  14 Okt                 |
|------------------------------------|
|    [⌂ Beranda]     [+]     [Profil]|
+------------------------------------+
```

**Catatan UX:**
- Search field tampil dekat bagian atas.
- Tab “Semua/Hilang/Ditemukan” memberi penyaringan cepat tanpa membuka panel filter.
- Bagian kemungkinan cocok tidak boleh mendominasi layar; bila tidak ada hasil, tampilkan pesan singkat dan tetap tampilkan laporan terbaru.
- Foto barang boleh opsional; jika tidak ada foto, tampilkan placeholder konsisten.

### 5.2 Pencarian dan filter

Filter dibuka dari tombol filter pada Beranda. Panel filter sebaiknya memakai bottom sheet, bukan layar yang penuh kontrol kecil.

```text
+------------------------------------+
| Cari Barang                   [X]  |
|------------------------------------|
| [ Nama barang atau deskripsi... ]  |
|------------------------------------|
| Jenis laporan                      |
| [Semua] [Hilang] [Ditemukan]       |
|                                    |
| Kategori                           |
| [ Pilih kategori                v] |
|                                    |
| Fakultas / area                    |
| [ Pilih fakultas/area           v] |
|                                    |
| Gedung / fasilitas                 |
| [ Pilih gedung/fasilitas        v] |
|                                    |
| Tanggal kejadian                   |
| [7 hari terakhir                v] |
|------------------------------------|
| [Reset]           [Terapkan Filter]|
+------------------------------------+
```

**Filter MVP:** kata kunci, jenis laporan, kategori, fakultas/area, gedung/fasilitas, dan rentang tanggal. Jika gedung belum dipetakan untuk suatu area, tetap izinkan “Lainnya” atau titik lokasi berupa teks.

Setelah filter diterapkan, hasil ditampilkan sebagai daftar kartu. Sediakan tombol “Hapus filter” atau “Reset” agar pengguna mudah kembali ke daftar umum.

### 5.3 Detail barang

```text
+------------------------------------+
| [< Kembali]        Detail Barang   |
|------------------------------------|
| +--------------------------------+ |
| |                                | |
| |          FOTO BARANG           | |
| |                                | |
| +--------------------------------+ |
| Dompet hitam                      |
| [Ditemukan]                       |
|------------------------------------|
| Kategori: Dompet & Uang           |
| Lokasi: Fakultas Teknik           |
| Gedung: Gedung B3                 |
| Titik: Lantai 2, dekat ...        |
| Tanggal: 15 Okt 2026              |
|------------------------------------|
| DESKRIPSI                         |
| Dompet hitam dengan ciri umum...  |
|------------------------------------|
| Kemungkinan cocok                 |
| [Laporan lain yang relevan]       |
|------------------------------------|
| [ Hubungi pelapor via WhatsApp ]  |
| [ Tandai/ laporkan masalah ]      |
+------------------------------------+
```

**Aturan privasi:** jangan menampilkan nomor telepon mentah atau ciri rahasia barang yang bisa dipakai untuk klaim palsu. Tombol WhatsApp hanya tersedia sesuai aturan akses dan persetujuan pelapor. Pengunjung boleh melihat detail publik, tetapi aksi yang memerlukan akun meminta login.

### 5.4 Formulir buat laporan

```text
+------------------------------------+
| [< Kembali]       Buat Laporan     |
|------------------------------------|
| [ Barang Hilang ] [ Barang Temuan ]|
|------------------------------------|
| +--------------------------------+ |
| |      + Tambah foto (opsional)  | |
| +--------------------------------+ |
|                                    |
| Nama barang *                      |
| [ Contoh: Dompet hitam          ]  |
|                                    |
| Kategori *                         |
| [ Pilih kategori                v] |
|                                    |
| Deskripsi / ciri-ciri              |
| [ Jelaskan ciri barang...       ]  |
|                                    |
| Fakultas / area *                  |
| [ Pilih fakultas/area           v] |
|                                    |
| Gedung / fasilitas                 |
| [ Pilih gedung/fasilitas        v] |
|                                    |
| Titik spesifik (opsional)          |
| [ Lantai, ruangan, dekat apa... ]  |
| [ ] Tidak tahu lokasi persis       |
|                                    |
| Tanggal kejadian *                 |
| [ Pilih tanggal                  ] |
|------------------------------------|
| [          Kirim Laporan         ] |
+------------------------------------+
```

**Aturan formulir:**
- Nama barang, kategori, lokasi umum, dan tanggal kejadian wajib diisi.
- Foto dan titik lokasi yang sangat spesifik opsional.
- Deskripsi membantu pencocokan; minta pengguna tidak menuliskan nomor identitas atau data sensitif.
- Validasi input sebelum submit dan tampilkan pesan di dekat field yang bermasalah.
- Setelah berhasil, tunjukkan konfirmasi dan arahkan ke halaman detail laporan atau Laporan Saya.
- Jika upload foto gagal, beri pilihan mencoba lagi atau mengirim laporan tanpa foto.

### 5.5 Login dan registrasi

```text
+------------------------------------+
|                FoundIt             |
|                                    |
|        Selamat datang kembali      |
|                                    |
| Email                              |
| [ Masukkan email                ]  |
|                                    |
| Password                           |
| [ Masukkan password             ]  |
|                         Lupa password?
|                                    |
| [              Masuk             ] |
|                                    |
| Belum punya akun? Daftar           |
|------------------------------------|
| Jelajahi laporan tanpa login       |
+------------------------------------+
```

Form registrasi menambah nama lengkap dan nomor WhatsApp, disertai penjelasan bahwa nomor hanya digunakan untuk menghubungi pengguna terkait laporan dan tidak ditampilkan pada daftar publik. Minta persetujuan eksplisit sebelum nomor digunakan untuk kontak.

### 5.6 Profil dan Laporan Saya

```text
+------------------------------------+
| Profil                             |
|------------------------------------|
| [○] Nama pengguna                  |
|     Mahasiswa UNSRAT               |
|------------------------------------|
| [ Laporan Saya                  >] |
| [ Kemungkinan Cocok             >] |
| [ Edit Profil                   >] |
|------------------------------------|
| LAPORAN SAYA                       |
| [Aktif] [Selesai]                 |
|                                    |
| +--------+  KTM biru               |
| |  FOTO  |  [Aktif]                |
| +--------+  Teknik · 14 Okt        |
|            [Edit] [Lainnya]        |
|------------------------------------|
| [ Keluar dari akun ]               |
|------------------------------------|
|    [⌂ Beranda]     [+]     [Profil]|
+------------------------------------+
```

Untuk pengguna tamu, Profil menampilkan tombol “Masuk” dan “Daftar”, serta penjelasan singkat bahwa akun diperlukan untuk membuat dan mengelola laporan.

### 5.7 Kemungkinan cocok

```text
+------------------------------------+
| [< Kembali]    Kemungkinan Cocok   |
|------------------------------------|
| Berdasarkan laporan aktif kamu     |
|                                    |
| +--------------------------------+ |
| | [FOTO]  Dompet hitam           | |
| |         Skor kecocokan: 82/100 | |
| |         Teknik · Gedung B3     | |
| |         [Lihat detail]         | |
| +--------------------------------+ |
|                                    |
| Skor adalah rekomendasi, bukan     |
| kepastian barang yang sama.        |
+------------------------------------+
```

Jika belum ada laporan yang berpotensi cocok, tampilkan empty state yang membantu, misalnya “Belum ada laporan yang cocok. Kami akan menampilkan kemungkinan lain saat kamu memeriksa kembali.” Jangan mengklaim notifikasi otomatis bila fitur notifikasi belum dibuat.

### 5.8 Dashboard admin (minimal)

```text
+------------------------------------+
| FoundIt Admin                      |
|------------------------------------|
| [Semua] [Ditandai] [Dinonaktifkan] |
|------------------------------------|
| Laporan: Dompet hitam              |
| Pelapor: pengguna terdaftar        |
| Status: Aktif                      |
| [Tinjau] [Sembunyikan laporan]     |
|------------------------------------|
| Laporan: KTM biru                  |
| Alasan: Konten bermasalah          |
| [Tinjau] [Sembunyikan laporan]     |
|------------------------------------|
| [Keluar]                           |
+------------------------------------+
```

Admin harus masuk melalui autentikasi yang sama, tetapi tampilan dan izin admin hanya diberikan untuk akun yang sudah ditetapkan oleh proses tepercaya. Jangan menambahkan opsi “Daftar sebagai admin” pada aplikasi.

## 6. Status UI yang wajib dirancang

Jangan hanya merancang keadaan saat data berhasil dimuat. Setiap layar data harus punya keadaan berikut:

- **Loading:** indikator proses yang tidak menghalangi seluruh aplikasi jika tidak diperlukan.
- **Empty state:** teks yang menjelaskan belum ada laporan, hasil pencarian kosong, atau belum ada kecocokan.
- **Error state:** pesan yang mudah dimengerti dan tombol coba lagi jika relevan.
- **Success state:** konfirmasi singkat setelah laporan dibuat, diubah, atau diselesaikan.
- **Offline/gangguan jaringan:** beri tahu pengguna bila data belum berhasil dikirim; jangan menyatakan laporan berhasil sebelum server mengonfirmasi.
- **Submit berulang:** nonaktifkan tombol kirim saat proses berlangsung agar tidak membuat laporan duplikat.

## 7. Alur Pengguna Utama

### A. Mencari barang

```text
Buka aplikasi
    -> Beranda publik
    -> Cari nama barang / pilih filter
    -> Buka detail laporan
    -> Periksa lokasi dan deskripsi
    -> Login bila diperlukan untuk menghubungi
    -> Hubungi pelapor via WhatsApp
    -> Verifikasi ciri khusus barang
```

### B. Melaporkan barang

```text
Tekan tombol +
    -> Sudah login?
       -> Tidak: Login / Daftar
          -> kembali ke formulir laporan
       -> Ya: Formulir laporan
    -> Isi data dan opsional foto
    -> Kirim laporan
    -> Konfirmasi berhasil
    -> Laporan muncul di Beranda dan Laporan Saya
    -> Sistem dapat merekomendasikan laporan yang cocok
```

## 8. Aksesibilitas dan Kemudahan Penggunaan

- Gunakan label teks pada ikon navigasi; jangan memakai ikon tanpa label.
- Pertahankan ukuran teks dan area sentuh yang nyaman.
- Jangan membedakan status hanya berdasarkan warna.
- Pastikan formulir dapat digulir dengan baik dan tombol utama tidak tertutup keyboard.
- Beri pesan kesalahan yang menyebutkan apa yang perlu diperbaiki.
- Jangan menghapus input pengguna ketika terjadi kegagalan jaringan.
- Setelah login dari alur Lapor, lanjutkan ke tujuan yang diminta pengguna.
- Hindari pop-up yang tidak perlu dan minta konfirmasi hanya untuk aksi penting seperti menghapus laporan.

## 9. Checklist Penerimaan UI/UX

- [ ] Pengguna baru memahami fungsi aplikasi dari Beranda tanpa tutorial panjang.
- [ ] Tamu dapat mencari dan membuka detail tanpa login.
- [ ] Tombol + mudah ditemukan dan mengarahkan tamu ke autentikasi sebelum formulir.
- [ ] Setelah login, pengguna langsung kembali ke alur pelaporan yang dimulai.
- [ ] Pengguna dapat memahami status laporan tanpa mengandalkan warna saja.
- [ ] Filter mudah diterapkan dan dihapus.
- [ ] Formulir menjelaskan field wajib dan opsional.
- [ ] Loading, hasil kosong, error, dan sukses dirancang untuk alur utama.
- [ ] Informasi pribadi dan ciri rahasia tidak ditampilkan pada laporan publik.
- [ ] Navigasi konsisten dan pengguna selalu memiliki cara untuk kembali.

## 10. Catatan Implementasi

Dokumen ini adalah panduan desain MVP, bukan implementasi final. Saat membangun UI Flutter, gunakan komponen yang dapat dipakai ulang seperti `ReportCard`, `StatusChip`, `SearchBar`, `LocationSelector`, `EmptyState`, dan `PrimaryButton`. Jangan menghubungkan semua fitur sekaligus; mulai dari layar statis dengan data dummy, validasi navigasi, lalu integrasikan backend setelah tampilan utama stabil.


## 11. Backend integration notes (Supabase)

- Keep UI screens independent of database calls where practical: use small repository/service classes so mock data can be replaced with Supabase data without rewriting the widgets.
- Public report feed/detail should read from the restricted `public_reports` view. Never fetch `user_contacts` directly for another user.
- For public report photos, use the `report-photos` bucket and store only `photo_path` in the report row. Build the public image URL at runtime from the Storage client.
- Public bucket URLs may be viewed by anyone who obtains the URL. Do not allow sensitive identity documents or bank-card photos; show this warning beside the upload control.
- Report submission should create the database row first, upload the optional photo second, then update `photo_path`. If upload fails, preserve the report and explain that it was saved without a photo.
- Use an authenticated database function for WhatsApp contact lookup; show the contact action only if the user is signed in and the reporter opted in. Do not display raw phone numbers.
- Keep all Supabase database access behind repositories/services rather than placing query logic directly in large widget build methods.
- Supabase RLS, database grants, RPC permissions, and Storage policies are part of the feature, not optional setup. The app UI must never be treated as an authorization boundary.
