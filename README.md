# 💧 Water Meter App - PRM393 Project

Ứng dụng di động hỗ trợ nhân viên thu tiền nước ghi chỉ số đồng hồ, thu tiền và đồng bộ dữ liệu.  
Hoạt động hoàn toàn OFFLINE, tự động đồng bộ khi có mạng.

---

## 📚 BẮT ĐẦU NHANH

### 1️⃣ Chạy ứng dụng

```bash
cd water_meter_app
flutter pub get
flutter run
```

### 2️⃣ Đăng nhập

- **Admin:** `admin` / `admin123`
- **Lưu ý:** Tài khoản admin được tạo tự động khi cài đặt lần đầu

### 3️⃣ Đọc tài liệu

👉 Bắt đầu từ: **[`INDEX.md`](INDEX.md)** - Hướng dẫn tìm đúng tài liệu cần đọc

---

## 🎯 Tính năng chính

- ✅ **Đăng nhập** với username/password (SQLite)
- ✅ **Tải dữ liệu** khách hàng từ Firebase (ONLINE)
- ✅ **Ghi chỉ số** đồng hồ nước (OFFLINE)
- ✅ **Chụp ảnh** đồng hồ làm bằng chứng
- ✅ **Thu tiền** (tiền tháng hiện tại + tiền nợ)
- ✅ **Quản lý công nợ**
- ✅ **Đồng bộ** dữ liệu lên Firebase (ONLINE)
- ✅ **Lịch sử** ghi số và thu tiền
- ✅ **Chế độ offline-first** với SQLite sync

---

## 📂 Cấu trúc dự án

```
PRM_Project/
├── INDEX.md                        # 🎯 BẮT ĐẦU TỪ ĐÂY
├── README.md                       # File này
├── CODE_EXPLANATION.md            # Giải thích code chi tiết
├── SCREEN_FLOW.md                 # Sơ đồ luồng màn hình
├── REFACTOR_SUMMARY.md            # Tóm tắt refactor
│
└── water_meter_app/               # Flutter app
    ├── GETTING_STARTED.md         # Hướng dẫn chạy app
    ├── CODE_STRUCTURE.md          # Cấu trúc code
    ├── QUICK_REFERENCE.md         # Tra cứu nhanh
    │
    └── lib/
        ├── main.dart              # Entry point (32 dòng)
        ├── models/                # Data models
        ├── database/              # SQLite database
        ├── providers/             # State management
        └── screens/               # UI screens
```

---

## 📖 Tài liệu quan trọng

| Tài liệu | Mục đích | Đọc khi nào |
|----------|----------|-------------|
| **[`INDEX.md`](INDEX.md)** | **Hướng dẫn tìm tài liệu** | **Đọc đầu tiên** |
| [`water_meter_app/GETTING_STARTED.md`](water_meter_app/GETTING_STARTED.md) | Hướng dẫn chạy app | Muốn chạy app |
| [`CODE_EXPLANATION.md`](CODE_EXPLANATION.md) | Giải thích code | Muốn hiểu code |
| [`SCREEN_FLOW.md`](SCREEN_FLOW.md) | Luồng màn hình | Muốn hiểu UI |
| [`water_meter_app/CODE_STRUCTURE.md`](water_meter_app/CODE_STRUCTURE.md) | Cấu trúc code | Muốn code thêm |
| [`water_meter_app/QUICK_REFERENCE.md`](water_meter_app/QUICK_REFERENCE.md) | Tra cứu nhanh | Cần tìm nhanh |

---

## 🚀 Công nghệ sử dụng

- **Flutter** - UI framework
- **Dart** - Programming language
- **SQLite (sqflite)** - Local offline database
- **Firebase** - Backend (Firestore + Storage)
- **Provider** - State management
- **Camera** - Chụp ảnh đồng hồ
- **Connectivity Plus** - Network detection

---

## 📊 Tiến độ phát triển

- ✅ **Phase 1:** Authentication (Hoàn thành)
  - Login/Logout với SQLite
  - User model
  - Provider state management
  - UI Login & Home

- ✅ **Phase 2:** Customer Management (Hoàn thành)
  - Customer model
  - Firebase integration
  - Customer list & detail
  - List/Grid view toggle

- ✅ **Phase 3:** Meter Reading & Payment (Hoàn thành)
  - Reading & payment models
  - Camera integration
  - Payment collection
  - Offline-first workflow

- ✅ **Phase 4:** Sync & History (Hoàn thành)
  - Firebase service
  - Data synchronization (bidirectional)
  - History screens
  - Production APK build

- ✅ **PRODUCTION READY** - App hoàn thiện và sẵn sàng triển khai

---

## 🎓 Môn học

- **Môn:** PRM393 - Mobile Development
- **Dự án:** Water Meter App
- **Năm:** 2026

---

## 👥 Thành viên

_[Thêm thông tin thành viên nhóm ở đây]_

---

## 📞 Liên hệ

Gặp vấn đề? Đọc [`water_meter_app/GETTING_STARTED.md`](water_meter_app/GETTING_STARTED.md) phần Troubleshooting.

---

**🎯 Bắt đầu từ đây:** [`INDEX.md`](INDEX.md)
