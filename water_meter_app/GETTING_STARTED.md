# 🚀 Hướng dẫn chạy ứng dụng Water Meter App

## 📋 Yêu cầu hệ thống

- Flutter SDK >= 3.11.5
- Dart SDK >= 3.11.5
- Android Studio / VS Code
- Android device hoặc emulator (API level 21+)
- Git

---

## 🔧 Cài đặt

### 1. Clone repository

```bash
git clone <repository-url>
cd PRM_Project/water_meter_app
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Kiểm tra Flutter

```bash
flutter doctor
```

Đảm bảo tất cả check marks đều xanh (✓)

---

## ▶️ Chạy ứng dụng

### Chạy trên Android Emulator

1. Mở Android Emulator
2. Chạy lệnh:

```bash
flutter run
```

### Chạy trên thiết bị thật

1. Bật USB Debugging trên điện thoại
2. Kết nối điện thoại với máy tính
3. Kiểm tra device đã kết nối:

```bash
flutter devices
```

4. Chạy app:

```bash
flutter run
```

---

## 🔑 Tài khoản demo

Sau khi app chạy, bạn có thể đăng nhập bằng các tài khoản sau:

### Tài khoản Staff 1
- **Username:** `staff01`
- **Password:** `12345678`
- **Vai trò:** Nhân viên
- **Khu vực:** `KV01 - Khu vuc 1`

### Tài khoản Staff 2
- **Username:** `staff02`
- **Password:** `12345678`
- **Vai trò:** Nhân viên
- **Khu vực:** `KV02 - Khu vuc 2`

### Tài khoản Staff 3
- **Username:** `staff03`
- **Password:** `12345678`
- **Vai trò:** Nhân viên
- **Khu vực:** `KV03 - Khu vuc 3`

---

## 📂 Cấu trúc dự án

```
water_meter_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── models/                   # Data models
│   │   └── user_model.dart
│   ├── database/                 # SQLite database
│   │   └── database_helper.dart
│   ├── providers/                # State management
│   │   └── auth_provider.dart
│   └── screens/                  # UI screens
│       ├── login_screen.dart
│       └── home_screen.dart
├── pubspec.yaml                  # Dependencies
├── README.md                     # Tài liệu dự án
├── CODE_STRUCTURE.md            # Chi tiết cấu trúc code
└── GETTING_STARTED.md           # File này
```

Xem chi tiết cấu trúc code trong file `CODE_STRUCTURE.md`

---

## 🐛 Debug

### Xóa cache và build lại

```bash
flutter clean
flutter pub get
flutter run
```

### Xem logs

```bash
flutter logs
```

### Build APK để test

```bash
flutter build apk --debug
```

File APK sẽ được tạo tại:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 📝 Database

App sử dụng SQLite để lưu trữ dữ liệu local.

### Vị trí database file:
- **Android:** `/data/data/com.example.water_meter_app/databases/water_meter_app.db`
- **iOS:** `<Application Directory>/Documents/water_meter_app.db`

### Xem database (Android):

```bash
adb shell
cd /data/data/com.example.water_meter_app/databases/
sqlite3 water_meter_app.db
```

### Xem bảng users:

```sql
SELECT * FROM users;
```

### Reset database:

Xóa app và cài lại, database sẽ được tạo mới với data demo.

---

## 🔄 Hot Reload

Trong quá trình phát triển, bạn có thể sử dụng Hot Reload để thấy thay đổi ngay lập tức:

- **Hot Reload:** Nhấn `r` trong terminal hoặc Save file trong IDE
- **Hot Restart:** Nhấn `R` trong terminal
- **Quit:** Nhấn `q` trong terminal

---

## 📦 Dependencies chính

| Package | Mục đích |
|---------|----------|
| `sqflite` | SQLite database |
| `provider` | State management |
| `camera` | Chụp ảnh đồng hồ |
| `connectivity_plus` | Kiểm tra kết nối mạng |
| `http` | API calls |
| `intl` | Format ngày tháng |

---

## 🎓 Các bước phát triển tiếp theo

1. ✅ **Đã hoàn thành:**
   - Cấu trúc project
   - Authentication (Login/Logout)
   - SQLite database
   - Provider state management

2. 🔜 **Tiếp theo:**
   - Thêm Customer model
   - Download data screen
   - Customer list screen
   - Camera integration
   - Sync service

---

## 💡 Tips

1. **VS Code Extensions khuyên dùng:**
   - Flutter
   - Dart
   - Flutter Widget Snippets
   - Awesome Flutter Snippets

2. **Shortcuts hữu ích:**
   - `Ctrl + Space`: Show suggestions
   - `F2`: Rename symbol
   - `Ctrl + Click`: Go to definition

3. **Code snippets:**
   - `stless`: Tạo StatelessWidget
   - `stful`: Tạo StatefulWidget
   - `build`: Override build method

---

## ❓ Troubleshooting

### Lỗi: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Lỗi: "Waiting for another flutter command to release the startup lock"
```bash
# Windows
del %LOCALAPPDATA%\flutter_console\flutter.bat.lock

# macOS/Linux
rm ~/.flutter_console/flutter.bat.lock
```

### Lỗi: "Unable to locate Android SDK"
- Mở Android Studio
- Settings → Appearance & Behavior → System Settings → Android SDK
- Copy đường dẫn SDK
- Set environment variable: `ANDROID_HOME=<SDK_PATH>`

---

## 📞 Liên hệ

Nếu gặp vấn đề, vui lòng tạo issue trên GitHub hoặc liên hệ team.

---

**Cập nhật:** 2026-06-02
