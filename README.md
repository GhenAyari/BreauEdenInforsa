<h1 align="center">Aplikasi MyBreau</h1>

<p align="center">
  Sebuah aplikasi mobile sederhana untuk membantu Bureau Of Entrepreneurship Development dari Inforsa Unmul dalam menjalankan program kerja mereka 
  dibuat menggunakan <b>Flutter</b> dan juga tools & bahasa lainnya untuk mendukung aplikasi berjalan.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/HTML5-%23E34F26.svg?style=for-the-badge&logo=html5&logoColor=white" alt="HTML5">
  <img src="https://img.shields.io/badge/Bootstrap-%237952B3.svg?style=for-the-badge&logo=bootstrap&logoColor=white" alt="Bootstrap">
  <img src="https://img.shields.io/badge/JavaScript-%23F7DF1E.svg?style=for-the-badge&logo=javascript&logoColor=black" alt="JavaScript">
</p>

---

## Anggota Kelompok B9 Hitam Perkasa

| Kelas | Nama | NIM |
| :---: | :--- | :---: |
| B2024 | Christian Amsal Asimaro Lumban Tobing | 2409116053 |
| B2024 | Fikri Abiyyu Rahman | 2409116063 |
| B2024 | Dinathan Fahrezi | 2409116050 |
| B2024 | Ghendida Gantari Ayari | 2409116080 |

---

## Fitur Utama

* 🛒 **Point of Sale (POS) Dinamis**: Sistem kasir keranjang belanja dengan dukungan multi-sesi (Buka, Jeda, Tutup Stand).
* 💳 **Integrasi Pembayaran**: Mendukung pencatatan pembayaran Tunai (dengan kalkulasi kembalian) dan QRIS (dengan fitur upload bukti bayar).
* 📦 **Manajemen Stok Real-time**: CRUD stok barang yang terbagi dalam berbagai kategori (Stand, Eden/Gudang, dan Penyewaan) yang tersinkronisasi langsung dengan *database*.
* 🌐 **Web Form Generator (Pre-Order)**: Admin dapat membuat *form* pemesanan *custom* (teks, pilihan ganda, upload file) yang langsung menghasilkan *link* web publik untuk disebar ke mahasiswa.
* 🛍️ **Sistem Penyewaan**: Pelacakan status barang sewa (Dipinjam/Dikembalikan) beserta kalkulasi denda otomatis.
* 📊 **Laporan Keuangan Otomatis**: Rekapitulasi pendapatan kotor, pengeluaran modal, dan laba bersih dari seluruh divisi (POS, Sewa, PO).
* 📥 **Ekspor ke CSV**: Mengunduh dan membagikan laporan riwayat penjualan ke format Excel (.csv) dengan satu klik.
* 🔐 **Role-Based Access Control (RBAC)**: Pembatasan akses menu berdasarkan jabatan pengurus (Admin, POS_Barang, Penyewaan, PreOrder).
* 🌙 **Dark Mode**: Dukungan mode gelap yang tersimpan secara permanen (*local storage*).
* 👁️ **Privacy Toggle**: Fitur sembunyikan saldo total di *dashboard* ala M-Banking.

---

## Packages

Aplikasi ini dikembangkan menggunakan kerangka kerja Flutter dan memanfaatkan beberapa pustaka eksternal untuk mendukung berbagai fitur inti. Berikut adalah daftar pustaka utama yang digunakan:

### 1. Inti Sistem dan Database
* **supabase_flutter**: Digunakan sebagai antarmuka utama untuk berkomunikasi dengan layanan Supabase, meliputi operasi basis data (CRUD), autentikasi pengguna, dan penyimpanan berkas (storage).
* **flutter_dotenv**: Digunakan untuk mengelola variabel lingkungan (environment variables). Pustaka ini mengamankan kredensial penting seperti kunci layanan (service key) Supabase agar tidak tertulis langsung di dalam kode sumber.

### 2. Penyimpanan Lokal dan Perangkat
* **shared_preferences**: Digunakan untuk menyimpan data preferensi pengguna secara lokal di memori perangkat, seperti status sesi masuk (login), preferensi tema (gelap/terang), dan pengaturan visibilitas saldo.
* **device_info_plus**: Digunakan untuk mengambil informasi detail mengenai perangkat keras yang digunakan oleh pengguna (merek dan model), yang kemudian dicatat dalam log riwayat aktivitas sistem.

### 3. Manajemen Media dan Dokumen
* **image_picker**: Digunakan untuk mengambil gambar, baik melalui kamera perangkat maupun galeri lokal. Fitur ini diterapkan pada modul manajemen stok, pre-order, dan bukti transaksi.
* **csv**: Digunakan untuk memformat dan mengonversi data dari basis data menjadi berkas berekstensi CSV, yang berfungsi sebagai laporan untuk diunduh.
* **path_provider**: Digunakan untuk menemukan dan mengakses direktori sistem berkas lokal pada perangkat, yang diperlukan untuk menyimpan berkas CSV sementara sebelum dibagikan.
* **share_plus**: Digunakan untuk memanggil dialog berbagi bawaan sistem operasi (native share dialog), memungkinkan pengguna untuk mengirimkan berkas laporan ke aplikasi lain seperti email atau platform pesan instan.

### 4. Utilitas Eksternal
* **url_launcher**: Digunakan untuk membuka tautan eksternal di luar aplikasi, seperti membuka peramban web (browser) untuk menampilkan bukti gambar atau dokumen yang dikirimkan oleh pelanggan.

---

## Komponen Antarmuka (Widgets)

Antarmuka pengguna pada aplikasi ini dibangun dengan arsitektur komponen (widget) yang modular. Berikut adalah kategorisasi widget yang digunakan dalam proyek ini:

### 1. Struktur dan Tata Letak (Layouting)
* **Scaffold**: Kerangka dasar halaman yang menampung komponen seperti bilah aplikasi dan konten utama.
* **AppBar**: Bilah navigasi dan informasi di bagian atas layar.
* **Column & Row**: Pengatur tata letak elemen secara vertikal dan horizontal.
* **ListView & GridView**: Penampil daftar elemen yang dapat digulir, baik dalam bentuk baris maupun grid berskala.
* **Stack & Positioned**: Pengatur tata letak bertumpuk untuk elemen antarmuka yang saling tumpang tindih.
* **Container, Padding, SizedBox, Expanded**: Komponen dasar untuk mengatur ruang, jarak, margin, dan proporsi dimensi elemen.

### 2. Input dan Interaksi Pengguna
* **Button Components**: Meliputi `ElevatedButton`, `OutlinedButton`, `TextButton`, dan `IconButton` untuk memfasilitasi tindakan pengguna.
* **TextField**: Kolom masukan teks yang dilengkapi dengan `TextInputFormatter` untuk validasi format karakter dan angka secara langsung.
* **DropdownButtonFormField**: Menu tarik-turun untuk pemilihan opsi tunggal yang terintegrasi dengan validasi formulir.
* **SwitchListTile**: Komponen sakelar biner untuk pengaturan seperti mode gelap atau penanda status.
* **GestureDetector & InkWell**: Menambahkan kemampuan deteksi sentuhan dan gestur pada komponen statis.

### 3. Penampil Informasi (Display)
* **Text & Icon**: Komponen dasar penyajian tipografi dan ikonografi sistem.
* **Image**: Penampil grafis yang menangani gambar dari URL jaringan (`NetworkImage`) dan memori lokal (`MemoryImage`).
* **Card**: Penampil wadah elemen dengan efek bayangan (elevation) untuk memisahkan hierarki informasi visual.
* **ListTile & ExpansionTile**: Penampil baris data terstruktur, dilengkapi dengan kemampuan ekspansi untuk menampilkan rincian lebih lanjut.
* **CircleAvatar**: Penampil visual berbentuk lingkaran, umumnya digunakan untuk ikon profil atau indikator status.

### 4. Manajemen Status dan Asinkronus
* **FutureBuilder**: Membangun komponen berdasarkan status resolusi operasi asinkron tunggal (pengambilan data satu kali).
* **StreamBuilder**: Membangun komponen secara reaktif berdasarkan aliran data waktu nyata (real-time) dari basis data.
* **RefreshIndicator**: Mengimplementasikan mekanisme tarik-untuk-menyegarkan (pull-to-refresh) pada daftar gulir.
* **StatefulBuilder**: Memungkinkan pembaruan status pada sebagian kecil komponen tanpa merender ulang seluruh halaman, sangat berguna pada antarmuka dialog modal.
* **DefaultTabController, TabBar, TabBarView**: Mengelola dan menyajikan antarmuka navigasi berbasis tab untuk pergantian tampilan kategori.

### 5. Lapisan Tampilan (Overlay & Dialog)
* **AlertDialog**: Menampilkan kotak dialog modal untuk konfirmasi tindakan kritis atau peringatan.
* **BottomSheet**: Menampilkan panel yang muncul dari bawah layar untuk memberikan opsi tambahan atau merender formulir sementara.
* **SnackBar**: Menyajikan pesan notifikasi singkat di bagian bawah layar terkait keberhasilan atau kegagalan suatu proses.

---

## Dokumentasi

### Tampilan Login
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/1237fb39-c785-4b86-987d-1adae3d264a4" />

---
### Tampilan Home
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/f11f90b8-a842-4581-a9bc-72c48c8fd395" />

---
### Tampilan POS
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/795f3cba-c75d-4bfe-8ac4-a792b9d94221" />

---
### Tampilan Manajemen Stok (Store)
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/23c395a0-9de7-4ea2-a4d8-f8ffbfe01dad" />

---
### Tampilan Manajemen Stok (Stand)
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/bf8941ba-8b36-4151-8d96-76bb417e69f7" />

---
### Tampilan Manajemen Stok (Eden)
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/ec47141c-e844-44a7-a2a2-245247650663" />

---
### Tampilan Manajemen Stok (Penyewaan)
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/66d8b841-deec-4576-aac7-9877ec5e3c69" />

---
### Tampilan Pengaturan & Akun
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/6c8d4a0e-8afe-41f4-95e4-e8c6953e2826" />

---
### Tampilan Penyewaan Barang
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/434e17f4-1331-48f6-aeca-f2d35b225a8a" />

---
### Tampilan Manajemen Pre-Order
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/ce92b13f-eebc-4f33-a291-8d73076b0afb" />

---
### Tampilan Riwayat Aktivitas
<img width="375" height="667" alt="image" src="https://github.com/user-attachments/assets/6b31ab32-ee1e-4859-ba05-e9080256a715" />

---
