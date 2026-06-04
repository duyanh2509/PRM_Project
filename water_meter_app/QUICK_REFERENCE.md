# ⚡ Quick Reference - Water Meter App

## 🏃 Chạy nhanh

```bash
cd water_meter_app
flutter pub get
flutter run
```

## 🔑 Login

| Username | Password | Role | Area |
|----------|----------|------|------|
| `staff01` | `12345678` | Staff | `KV01 - Khu vuc 1` |
| `staff02` | `12345678` | Staff | `KV02 - Khu vuc 2` |
| `staff03` | `12345678` | Staff | `KV03 - Khu vuc 3` |

---

## 📂 Cấu trúc quan trọng

```
lib/
├── main.dart                      # Entry point (32 dòng)
├── models/user_model.dart         # User data model
├── database/database_helper.dart  # SQLite + login logic
├── providers/auth_provider.dart   # State management
└── screens/
    ├── login_screen.dart         # Login UI
    └── home_screen.dart          # Home UI
```

---

## 🎯 Các file chính và mục đích

| File | Mục đích | Khi nào dùng |
|------|----------|--------------|
| `main.dart` | Khởi chạy app | Chỉ để setup app |
| `user_model.dart` | Model User | Khi làm việc với user data |
| `database_helper.dart` | Database operations | Mọi thao tác database |
| `auth_provider.dart` | Quản lý login state | Kiểm tra đăng nhập, lấy user |
| `login_screen.dart` | UI đăng nhập | Màn hình login |
| `home_screen.dart` | UI trang chính | Sau khi login |

---

## 🔄 Luồng đăng nhập

```
User nhập username + password
    ↓
login_screen.dart → AuthProvider.login()
    ↓
AuthProvider → DatabaseHelper.login()
    ↓
Query: SELECT * FROM users WHERE username=? AND password=?
    ↓
Tìm thấy? → Yes → Lưu user → Navigate to HomeScreen
         → No  → Hiển thị error
```

---

## 💻 Code snippets hay dùng

### Lấy user hiện tại

```dart
// Trong Widget
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    final user = authProvider.currentUser;
    return Text(user?.fullName ?? 'Guest');
  },
)
```

### Kiểm tra đã login chưa

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
if (authProvider.isLoggedIn) {
  // Đã đăng nhập
}
```

### Đăng xuất

```dart
await Provider.of<AuthProvider>(context, listen: false).logout();
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => LoginScreen()),
);
```

---

## 🗄️ Database queries

### Login check

```dart
final user = await DatabaseHelper.instance.login(username, password);
```

### Lấy user theo ID

```dart
final user = await DatabaseHelper.instance.getUserById(1);
```

### Lấy tất cả users

```dart
final users = await DatabaseHelper.instance.getAllUsers();
```

### Thêm user mới

```dart
final newUser = User(
  username: 'staff02',
  password: '12345678',
  fullName: 'Nhân viên B',
);
await DatabaseHelper.instance.insertUser(newUser);
```

---

## 🐛 Debug commands

```bash
# Clean build
flutter clean && flutter pub get

# View logs
flutter logs

# Build APK
flutter build apk --debug

# Check devices
flutter devices

# Hot reload
# Nhấn 'r' trong terminal

# Hot restart
# Nhấn 'R' trong terminal
```

---

## 📝 Conventions

### Đặt tên file

- Screen: `<tên>_screen.dart`
- Model: `<tên>_model.dart`
- Provider: `<tên>_provider.dart`
- Service: `<tên>_service.dart`
- Helper: `<tên>_helper.dart`

### Đặt tên class

```dart
// Screen
class LoginScreen extends StatefulWidget { }

// Model
class User { }

// Provider
class AuthProvider with ChangeNotifier { }

// Helper
class DatabaseHelper { }
```

---

## 🎨 Theme colors

```dart
// Primary color
Colors.blue[700]

// Success
Colors.green[600]

// Error
Colors.red[600]

// Warning
Colors.orange[600]

// Info
Colors.blue[600]
```

---

## 📱 Screen navigation

```bash
# Push
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
);

# Replace
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => LoginScreen()),
);

# Remove all and push
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => LoginScreen()),
  (route) => false,
);
```

---

## 🔗 Đọc thêm

- `README.md` - Tổng quan dự án
- `CODE_STRUCTURE.md` - Chi tiết cấu trúc code
- `GETTING_STARTED.md` - Hướng dẫn setup
- `REFACTOR_SUMMARY.md` - Tóm tắt refactor

---

**Last updated:** 2026-06-02
