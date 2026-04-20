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

## 🛠️ Tech Stack & Dependencies

### Backend & Core
* **[Flutter](https://flutter.dev/)**: SDK UI untuk *cross-platform app development*.
* **[Supabase Flutter](https://pub.dev/packages/supabase_flutter)**: Sebagai *Backend-as-a-Service* (BaaS) untuk Autentikasi, Database PostgreSQL (*Realtime updates*), dan Storage (Penyimpanan gambar).

### Local Storage & State Management
* **[Shared Preferences](https://pub.dev/packages/shared_preferences)**: Menyimpan sesi *Role* pengguna, preferensi *Dark Mode*, dan status visibilitas saldo.
* **[Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)**: Manajemen rahasia *Environment Variables* (.env).

### Utilities & Tools
* **[Image Picker](https://pub.dev/packages/image_picker)**: Mengambil foto dari kamera atau galeri untuk barang dan bukti transfer.
* **[CSV](https://pub.dev/packages/csv)**: Konversi data JSON transaksi ke format tabel Excel.
* **[Path Provider](https://pub.dev/packages/path_provider)**: Menemukan lokasi *temporary directory* pada *device* untuk menyimpan file CSV sementara.
* **[Share Plus](https://pub.dev/packages/share_plus)**: Membagikan file CSV laporan via aplikasi eksternal (WhatsApp, Drive, dll).
* **https://play.google.com/store/apps/details?id=com.nkart.launcher&hl=en(https://pub.dev/packages/url_launcher)**: Membuka link eksternal dari dalam aplikasi.

### UI & UX Components (Native Material 3)
* `NavigationBar` & `NavigationDestination` (Menu bawah dinamis).
* `StreamBuilder` & `FutureBuilder` (Reaktivitas data *Realtime*).
* `AnimatedSwitcher` & `AnimatedSize` (Transisi mulus dan laci keranjang POS).
* `showModalBottomSheet` & `AlertDialog` (Dialog konfirmasi dan rincian transaksi).

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
