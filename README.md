# 🍎 Retail Buah App (Fruit Store Management)

Aplikasi Full-Stack untuk manajemen toko buah retail. Aplikasi ini dirancang untuk mempermudah pengelolaan stok (Inventory) dan transaksi penjualan (Point of Sales) dengan pemisahan hak akses antara **Admin** dan **Staff**.

## ✨ Fitur Utama

### 🛡️ Autentikasi (Auth)
* **Login & Register:** Menggunakan JWT (JSON Web Token) untuk keamanan.
* **Role-Based Access:** Navigasi berbeda untuk Admin dan Staff.

### 👤 Admin Dashboard
* **Kelola Produk (CRUD):** Tambah, Edit, Hapus data buah.
* **Upload Gambar:** Upload foto buah dari galeri dengan kompresi otomatis.
* **Laporan Penjualan:** Melihat riwayat transaksi dan total pendapatan.
* **Search:** Pencarian buah berdasarkan nama.

### 🛒 Staff Dashboard (Kasir)
* **Katalog Visual:** Melihat daftar buah beserta foto dan sisa stok.
* **Indikator Stok:** Peringatan warna merah jika stok menipis (< 5kg).
* **Transaksi Penjualan:** Input jumlah (kg) dan pengurangan stok otomatis.
* **Validasi:** Mencegah penjualan jika stok tidak mencukupi.

---

## 🛠️ Tech Stack

**Frontend (Mobile/Web):**
* **Framework:** Flutter
* **HTTP Client:** Dio
* **Image Picker:** image_picker
* **Format Currency:** intl

**Backend (Server):**
* **Runtime:** Node.js
* **Framework:** Express.js
* **Database:** MongoDB (Atlas / Local)
* **Image Handling:** Multer (Local Storage)
* **Security:** Bcryptjs (Hash Password), JWT

---

## 🚀 Cara Menjalankan Project

Ikuti langkah-langkah di bawah ini secara berurutan.

### 1. Persiapan Backend (Server)

Pastikan Node.js dan MongoDB sudah terinstal.

1.  Buka terminal, masuk ke folder backend:
    ```bash
    cd retail-buah-backend
    ```
2.  Instal dependency:
    ```bash
    npm install express mongoose cors bcryptjs jsonwebtoken multer dotenv
    ```
3.  Buat file `.env` di root folder backend, isi dengan:
    ```env
    MONGO_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/retail_db
    PORT=3000
    ```
    *(Ganti `MONGO_URI` dengan koneksi MongoDB kamu)*
4.  Jalankan server:
    ```bash
    node server.js
    ```
    *Output sukses:* `🚀 Server jalan di http://localhost:3000`

---

### 2. Persiapan Frontend (Flutter App)

1.  Buka terminal baru, masuk ke folder aplikasi flutter:
    ```bash
    cd retail_buah_app
    ```
2.  Update `pubspec.yaml` (jika belum):
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      dio: ^5.4.0
      intl: ^0.19.0
      image_picker: ^1.0.7
    ```
3.  Download library:
    ```bash
    flutter pub get
    ```
4.  **PENTING (Konfigurasi URL):**
    Buka file `lib/screens/admin_dashboard.dart` dan `staff_dashboard.dart`. Pastikan URL sesuai dengan emulator/device:
    * **Android Emulator:** `http://10.0.2.2:3000`
    * **Web / iOS / Real Device:** `http://localhost:3000` (atau IP Address Laptop)

5.  Jalankan Aplikasi:
    * **Untuk Web (Rekomendasi Edge/Chrome):**
        ```bash
        flutter run -d edge --web-renderer html
        ```
    * **Untuk Android:**
        ```bash
        flutter run
        ```

---

## 📂 Struktur Folder Proyek

```text
retail_buah_app/
├── lib/
│   ├── models/
│   │   └── product_model.dart    # Model Data (JSON Parsing)
│   ├── screens/
│   │   ├── auth_screen.dart      # Login & Register
│   │   ├── admin_dashboard.dart  # UI Admin (CRUD + Upload)
│   │   ├── staff_dashboard.dart  # UI Staff (Transaksi)
│   │   └── report_screen.dart    # UI Laporan
│   └── main.dart                 # Entry Point
│
backend/
├── uploads/                      # Tempat penyimpanan gambar fisik
├── server.js                     # Kode Utama Server (API + DB Logic)
└── .env                          # Konfigurasi Environment
