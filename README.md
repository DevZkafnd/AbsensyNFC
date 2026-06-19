# 🟢 Absensy — Sistem Absensi Berbasis NFC

<p align="center">
  <img src="assets/images/checklist-1-18.png" alt="Absensy Logo" width="80"/>
</p>

<p align="center">
  <b>Aplikasi manajemen absensi karyawan berbasis Flutter + Firebase dengan integrasi NFC</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-green" />
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen" />
</p>

---

## 📋 Deskripsi Proyek

**Absensy** adalah sistem absensi karyawan digital yang dirancang untuk perusahaan yang menggunakan mesin absensi NFC. Aplikasi ini memiliki dua antarmuka utama:

- **Admin Panel (Desktop/Web)** — Dashboard lengkap untuk manajemen data absensi, kelola akun karyawan, dan laporan
- **Mobile App (Android)** — Aplikasi karyawan untuk melihat status absensi, riwayat, dan mengajukan izin

Data absensi dikumpulkan secara otomatis dari **mesin absensi NFC eksternal** yang mendorong data ke Cloud Firestore secara real-time, sehingga admin dan karyawan dapat memantau kehadiran kapan saja dan di mana saja.

---

## 🏛️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────────┐
│                        SISTEM ABSENSY                           │
│                                                                 │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │  Mesin NFC   │───▶│  Cloud Firestore │◀───│  Admin Panel  │  │
│  │  (External)  │    │   (Database)     │    │  (Web/Desktop)│  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
│         │                     │                                 │
│         │ Push absensi        │ Real-time sync                  │
│         ▼                     ▼                                 │
│  ┌──────────────┐    ┌─────────────────┐                        │
│  │  card_id     │    │  Mobile App     │                        │
│  │  karyawan    │    │  (Android)      │                        │
│  └──────────────┘    └─────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

### Alur Data

1. **Mesin NFC** membaca kartu karyawan → mengirim data ke Firestore collection `absensi`
2. **Firestore** menyimpan data dengan field: `card_id`, `timestamp`, `status`, `photo_url`
3. **Admin** melihat data real-time melalui dashboard, dapat menyetujui/menolak izin
4. **Karyawan** melihat riwayat absensi & status kehadiran melalui aplikasi mobile

### Struktur Folder

```
lib/
├── main.dart                    # Entry point + Admin Dashboard + routing
├── login.dart                   # Admin login page
├── register.dart                # Admin registration page
├── absensi.dart                 # Manajemen data absensi (admin)
├── kelolaakun.dart              # Manajemen akun karyawan (admin)
├── profile.dart                 # Profil admin
├── app_drawer.dart              # Side navigation drawer (admin)
├── firebase_options.dart        # Konfigurasi Firebase
└── pages/                       # Halaman mobile (karyawan)
    ├── main_user_page.dart      # Wrapper bottom nav karyawan
    ├── home_page.dart           # Beranda karyawan
    ├── riwayat_page.dart        # Riwayat absensi karyawan
    ├── form_izin_page.dart      # Form pengajuan izin
    ├── profile_page.dart        # Profil & registrasi NFC karyawan
    └── login_page.dart          # Login karyawan
```

---

## 🛠️ Tech Stack

| Kategori | Teknologi |
|---|---|
| **Framework** | Flutter 3.8.1 |
| **Bahasa** | Dart 3.8 |
| **Database** | Firebase Cloud Firestore |
| **State Management** | StatefulWidget + setState |
| **Grafik & Chart** | fl_chart ^0.66.2 |
| **Local Storage** | shared_preferences ^2.2.2 |
| **Internasionalisasi** | intl ^0.20.2 (id_ID locale) |
| **Image Handling** | image_picker ^1.1.2 |
| **Asset Icons** | flutter_svg ^2.0.7 |
| **Platform** | Android, Web |

### Firebase Collections

| Collection | Deskripsi |
|---|---|
| `users` | Data akun karyawan & admin (fullname, Username, password, position, phone_number, card_id, isAdmin) |
| `absensi` | Record absensi (card_id, timestamp, status, photo_url) |
| `izin` | Pengajuan izin karyawan (userId, alasan, tanggal, status: pending/approved/rejected) |

---

## ✨ Fitur Lengkap

### 👑 Admin Panel (Desktop/Web)

#### 🔐 Autentikasi Admin
- Login dengan username & password
- Validasi kredensial langsung ke Firestore (`isAdmin: true`)
- Session management menggunakan SharedPreferences
- Tampil/sembunyikan password
- Registrasi akun admin baru

#### 📊 Dashboard
- Selamat datang dengan nama admin dari session
- **Bar chart kehadiran** menggunakan fl_chart dengan rentang tanggal custom
- Statistik ringkas: total hadir, terlambat, izin, alpa
- **Auto-refresh data setiap 30 detik** (real-time feel)
- Konversi timezone otomatis ke WIB (UTC+7)
- Side navigation drawer untuk navigasi antar halaman

#### 📋 Manajemen Absensi
- Tabel data absensi karyawan dari Firestore
- Filter berdasarkan nama, ID, atau tanggal
- Pagination dengan pilihan entri per halaman (5, 10, 25)
- **Preview foto bukti absensi** langsung di aplikasi (zoomable)
- Approve / Reject pengajuan izin karyawan
- Format tanggal & waktu lokal Indonesia (id_ID)

#### 👥 Kelola Akun Karyawan
- Tambah akun karyawan baru (nama, posisi, no. HP, username, password)
- Edit data akun yang sudah ada
- Hapus akun karyawan
- Lihat `card_id` NFC yang terdaftar
- Pencarian akun berdasarkan nama/username
- Auto-increment ID karyawan

#### 👤 Profil Admin
- Tampil data profil admin yang sedang login
- Logout dari sesi

---

### 📱 Mobile App (Android — Karyawan)

#### 🔐 Login Karyawan
- Halaman login karyawan (UI tersedia)

#### 🏠 Beranda (Home)
- Greeting selamat datang dengan nama karyawan
- Tampilan status kehadiran hari ini
- Ringkasan riwayat absensi terbaru (5 data terakhir)
- Header gradient hijau dengan desain modern

#### 📅 Riwayat Absensi
- Daftar riwayat absensi lengkap dari Firestore (real-time)
- **Filter berdasarkan status**: Semua, Hadir, Terlambat, Izin, Alpa
- **Filter rentang tanggal** (date range picker)
- **Pagination** (10 data per halaman)
- Konversi waktu otomatis ke WIB
- Tampilan status dengan warna berbeda (Hadir = hijau, Alpa = merah, dsb.)

#### 📝 Form Pengajuan Izin
- Form input alasan izin
- UI tersedia untuk pengajuan izin tidak masuk

#### 👤 Profil Karyawan
- Tampil data profil (nama, posisi, no. HP)
- **Registrasi kartu NFC** — input ID kartu NFC untuk didaftarkan ke akun
- Validasi input NFC ID
- Logout dari sesi

---

## 🗂️ Struktur Database Firestore

### Collection: `users`
```json
{
  "docId": "auto-generated",
  "id": "001",
  "fullname": "Budi Santoso",
  "Username": "budi",
  "password": "password123",
  "position": "Staff Administrasi",
  "phone_number": "081234567890",
  "card_id": "A1B2C3D4",
  "isAdmin": false
}
```

### Collection: `absensi`
```json
{
  "card_id": "A1B2C3D4",
  "timestamp": "Firestore Timestamp",
  "status": "Hadir",
  "photo_url": "https://..."
}
```

### Collection: `izin`
```json
{
  "userId": "user-doc-id",
  "alasan": "Sakit",
  "tanggal": "Firestore Timestamp",
  "status": "pending"
}
```

---

## 🚀 Cara Menjalankan

### Prasyarat
- Flutter SDK `^3.8.1`
- Android Studio / VS Code dengan Flutter extension
- Akun Firebase dengan project yang sudah dikonfigurasi
- Android device / emulator (API 21+) atau browser untuk web

### Setup

1. **Clone repository**
   ```bash
   git clone https://github.com/DevZkafnd/AbsensyNFC.git
   cd AbsensyNFC
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**
   - Buat project di [Firebase Console](https://console.firebase.google.com)
   - Aktifkan Cloud Firestore
   - Download `google-services.json` (Android) dan letakkan di `android/app/`
   - File `firebase_options.dart` sudah tersedia (sesuaikan dengan project Anda)

4. **Jalankan aplikasi**
   ```bash
   # Android
   flutter run

   # Web
   flutter run -d chrome
   ```

---

## 📱 Screenshot

> Admin Dashboard | Manajemen Absensi | Kelola Akun | Mobile Home | Riwayat

---

## 🔮 Rencana Pengembangan

- [ ] Implementasi autentikasi karyawan yang lengkap
- [ ] Integrasi NFC langsung di Android (tanpa mesin eksternal)
- [ ] Notifikasi push untuk status izin
- [ ] Export laporan ke PDF/Excel
- [ ] Enkripsi password (bcrypt/SHA-256)
- [ ] Dark mode
- [ ] Offline mode dengan sinkronisasi

---

## 👨‍💻 Developer

| | |
|---|---|
| **GitHub** | [@DevZkafnd](https://github.com/DevZkafnd) |
| **Email** | toedoeng@gmail.com |
| **Project Code** | JDI0001 |

---

## 📄 Lisensi

Proyek ini bersifat privat dan dikembangkan untuk keperluan internal perusahaan.

---

<p align="center">Made with ❤️ using Flutter & Firebase</p>
