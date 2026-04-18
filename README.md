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

