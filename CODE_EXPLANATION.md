# 📚 GIẢI THÍCH CODE - WATER METER APP (REFACTORED)

**Tài liệu giải thích cấu trúc code sau khi refactor**

---

## 🎯 Tổng quan

Ứng dụng đã được **refactor hoàn toàn** với mục tiêu:
- ✅ Login đơn giản: username + password check database SQLite
- ✅ Tổ chức code rõ ràng: models/database/providers/screens
- ✅ main.dart CHỈ để khởi chạy app (32 dòng)
- ✅ Đặt tên file dễ hiểu: `<tên>_<loại>.dart`
- ✅ Tách logic ra khỏi UI

---

## 📂 Cấu trúc thư mục

```
water_meter_app/
└── lib/
    ├── main.dart                      # Entry point (32 dòng)
    │
    ├── models/                        # Data Models
    │   └── user_model.dart           # Model User
    │
    ├── database/                      # SQLite Database
    │   └── database_helper.dart      # Database operations + login logic
    │
    ├── providers/                     # State Management
    │   └── auth_provider.dart        # Provider quản lý authentication
    │
    └── screens/                       # UI Screens
        ├── login_screen.dart         # Màn hình đăng nhập
        └── home_screen.dart          # Màn hình chính
```

---

## 📄 CHI TIẾT TỪNG FILE

### 1️⃣ `main.dart` - Entry Point

**📝 Là gì:**
File khởi chạy ứng dụng, KHÔNG chứa logic nghiệp vụ.

**📦 Nội dung:**
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Water Meter App',
        home: const LoginScreen(),
      ),
    );
  }
}
```

**✨ Nhiệm vụ:**
- Khởi chạy app
- Setup Provider (AuthProvider)
- Setup MaterialApp
- Điều hướng đến LoginScreen

**📊 Số dòng:** 32 dòng

---

### 2️⃣ `models/user_model.dart` - User Model

**📝 Là gì:**
Định nghĩa cấu trúc dữ liệu User (nhân viên).

**📦 Properties:**
```dart
class User {
  final int? id;              // ID trong database
  final String username;      // Tên đăng nhập
  final String password;      // Mật khẩu
  final String fullName;      // Tên đầy đủ
  final String role;          // Vai trò: 'staff' / 'admin'
  final DateTime createdAt;   // Ngày tạo
}
```

**🔧 Methods:**

| Method | Chức năng |
|--------|-----------|
| `fromMap()` | Chuyển Map (từ database) → User object |
| `toMap()` | Chuyển User object → Map (để lưu database) |
| `copyWith()` | Tạo bản sao với một số field thay đổi |

**💡 Khi nào dùng:**
- Khi lưu/đọc user từ database
- Khi truyền user data giữa các màn hình
- Khi hiển thị thông tin user trong UI

**📊 Số dòng:** 58 dòng

---

### 3️⃣ `database/database_helper.dart` - Database Helper

**📝 Là gì:**
Class quản lý SQLite database (Singleton pattern).

**🗄️ Database Schema:**

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  fullName TEXT NOT NULL,
  role TEXT DEFAULT 'staff',
  createdAt TEXT NOT NULL
)
```

**🔧 Methods:**

| Method | Chức năng | Return |
|--------|-----------|--------|
| `database` | Lấy database instance | `Future<Database>` |
| `_initDatabase()` | Khởi tạo database | `Future<Database>` |
| `_createTables()` | Tạo bảng + insert demo users | `Future<void>` |
| `login()` | **Kiểm tra login** | `Future<User?>` |
| `getUserById()` | Lấy user theo ID | `Future<User?>` |
| `getAllUsers()` | Lấy tất cả users | `Future<List<User>>` |
| `insertUser()` | Thêm user mới | `Future<int>` |
| `updateUser()` | Cập nhật user | `Future<int>` |
| `deleteUser()` | Xóa user | `Future<int>` |

**🔐 Login Logic:**

```dart
Future<User?> login(String username, String password) async {
  final db = await database;
  final results = await db.query(
    'users',
    where: 'username = ? AND password = ?',
    whereArgs: [username, password],
  );
  
  if (results.isEmpty) return null; // Login failed
  return User.fromMap(results.first); // Login success
}
```

**👥 Demo Accounts:**

| Username | Password | Role |
|----------|----------|------|
| `admin` | `12345678` | admin |
| `staff01` | `12345678` | staff |

**💡 Khi nào dùng:**
Mọi thao tác với database đều thông qua class này.

**📊 Số dòng:** 108 dòng

---

### 4️⃣ `providers/auth_provider.dart` - Auth Provider

**📝 Là gì:**
Provider quản lý trạng thái đăng nhập (State Management).

**📦 State Variables:**

```dart
User? _currentUser;        // User hiện tại (null = chưa login)
bool _isLoading;           // Trạng thái loading
String? _errorMessage;     // Thông báo lỗi
```

**🔧 Methods:**

| Method | Chức năng | Return |
|--------|-----------|--------|
| `login()` | Xử lý đăng nhập | `Future<bool>` |
| `logout()` | Đăng xuất | `Future<void>` |
| `clearError()` | Xóa error message | `void` |

**🔐 Login Flow:**

```dart
Future<bool> login(String username, String password) async {
  // 1. Set loading state
  _isLoading = true;
  notifyListeners();
  
  // 2. Validate input
  if (username.isEmpty || password.isEmpty) {
    _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 3. Check database
  final user = await DatabaseHelper.instance.login(username, password);
  
  // 4. Update state
  if (user == null) {
    _errorMessage = 'Username hoặc password không đúng';
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  _currentUser = user;
  _isLoading = false;
  notifyListeners();
  return true;
}
```

**💡 Khi nào dùng:**
- Trong UI: `Consumer<AuthProvider>` hoặc `Provider.of<AuthProvider>`
- Để lấy thông tin user hiện tại
- Để kiểm tra trạng thái đăng nhập
- Để xử lý login/logout

**📊 Số dòng:** 73 dòng

---

### 5️⃣ `screens/login_screen.dart` - Login Screen

**📝 Là gì:**
Màn hình đăng nhập.

**🎨 UI Components:**

1. **Logo & Title**
   - Icon nước (water_drop)
   - Text "Water Meter App"
   - Subtitle "Đăng nhập để tiếp tục"

2. **Form Fields**
   - Username field (TextFormField)
   - Password field (TextFormField + show/hide button)

3. **Validation**
   - Username: Không được rỗng
   - Password: Tối thiểu 6 ký tự

4. **Login Button**
   - Hiển thị loading indicator khi đang xử lý
   - Disable khi đang loading

5. **Demo Info Card**
   - Hiển thị tài khoản demo để test

**🔄 Login Flow:**

```
User nhập username + password
    ↓
Nhấn "Đăng nhập"
    ↓
Validate form (_formKey.currentState!.validate())
    ↓
Gọi AuthProvider.login()
    ↓
├─ Success → Navigator.pushReplacement(HomeScreen)
└─ Failed → Hiển thị SnackBar error
```

**💻 Code quan trọng:**

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final success = await authProvider.login(
    _usernameController.text,
    _passwordController.text,
  );
  
  if (success) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authProvider.errorMessage!)),
    );
  }
}
```

**📊 Số dòng:** 244 dòng

---

### 6️⃣ `screens/home_screen.dart` - Home Screen

**📝 Là gì:**
Màn hình chính sau khi đăng nhập thành công.

**🎨 UI Components:**

1. **AppBar**
   - Title "Trang chủ"
   - Nút Đăng xuất (icon logout)

2. **User Info Card**
   - Avatar (chữ cái đầu của tên)
   - Tên đầy đủ
   - Username (@username)
   - Badge role (Admin/Nhân viên)

3. **Quick Actions Grid** (2x2)
   - Tải dữ liệu (blue)
   - Khách hàng (green)
   - Lịch sử (orange)
   - Đồng bộ (purple)

**🔄 Logout Flow:**

```
User nhấn icon Logout
    ↓
Hiển thị AlertDialog xác nhận
    ↓
User xác nhận
    ↓
AuthProvider.logout()
    ↓
Navigator.pushAndRemoveUntil(LoginScreen, ...)
```

**💻 Code quan trọng:**

```dart
// Lấy user hiện tại
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    final user = authProvider.currentUser;
    return Text(user?.fullName ?? 'Guest');
  },
)

// Đăng xuất
await Provider.of<AuthProvider>(context, listen: false).logout();
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => LoginScreen()),
  (route) => false,
);
```

**📊 Số dòng:** 252 dòng

---

## 🔄 LUỒNG HOẠT ĐỘNG TỔNG THỂ

### Luồng khởi động app

```
main()
  ↓
MyApp
  ├─ Setup MultiProvider
  │   └─ AuthProvider
  └─ MaterialApp
      └─ home: LoginScreen
```

### Luồng đăng nhập

```
LoginScreen
  ↓
User nhập username + password
  ↓
Nhấn "Đăng nhập"
  ↓
Validate form
  ↓
AuthProvider.login(username, password)
  ├─ Validate input
  ├─ DatabaseHelper.instance.login()
  │   └─ Query: SELECT * FROM users WHERE username=? AND password=?
  └─ Update state (_currentUser, _isLoading, _errorMessage)
  └─ notifyListeners()
      ↓
├─ Success (user != null)
│   └─ Navigate to HomeScreen
│
└─ Failed (user == null)
    └─ Show SnackBar error
```

### Luồng đăng xuất

```
HomeScreen
  ↓
Nhấn icon Logout
  ↓
Show AlertDialog
  ↓
User confirm
  ↓
AuthProvider.logout()
  ├─ Set _currentUser = null
  └─ notifyListeners()
      ↓
Navigate to LoginScreen (remove all routes)
```

---

## 📦 DEPENDENCIES ĐÃ SỬ DỤNG

### Setup (pubspec.yaml)

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # Camera & Image
  camera: ^0.10.5+5
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Database (SQLite)
  sqflite: ^2.3.0          # ✅ Đã dùng cho login
  
  # Network
  connectivity_plus: ^5.0.1
  http: ^1.1.0
  
  # State Management
  provider: ^6.0.5         # ✅ Đã dùng cho AuthProvider
  
  # Other
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  permission_handler: ^11.0.1
```

### ❌ Đã xóa (không dùng nữa)

- `flutter_secure_storage` - Không cần, dùng SQLite thay thế
- `google_sign_in` - Không cần, chỉ login bằng username/password

---

## 💡 QUY TẮC ĐẶT TÊN FILE

| Loại | Quy tắc | Ví dụ | Lý do |
|------|---------|-------|-------|
| Screen | `<tên>_screen.dart` | `login_screen.dart` | Biết ngay là màn hình |
| Model | `<tên>_model.dart` | `user_model.dart` | Biết ngay là model |
| Provider | `<tên>_provider.dart` | `auth_provider.dart` | Biết ngay là provider |
| Service | `<tên>_service.dart` | `api_service.dart` | Biết ngay là service |
| Helper | `<tên>_helper.dart` | `database_helper.dart` | Biết ngay là helper |

**Mục đích:** Đọc tên file là biết ngay nội dung!

---

## ✅ CHECKLIST ĐÃ HOÀN THÀNH

- [x] ✅ Refactor authentication với login cơ bản
- [x] ✅ Xóa flutter_secure_storage, google_sign_in
- [x] ✅ Tạo User model với đầy đủ methods
- [x] ✅ Tạo DatabaseHelper với SQLite
- [x] ✅ Tạo AuthProvider cho state management
- [x] ✅ Tạo LoginScreen với form validation
- [x] ✅ Tạo HomeScreen với user info
- [x] ✅ main.dart chỉ 32 dòng, không có logic
- [x] ✅ Đặt tên file theo quy tắc
- [x] ✅ Tách logic ra khỏi UI
- [x] ✅ Tài liệu đầy đủ

---

## 🔜 TIẾP THEO CẦN LÀM

### Phase 2: Customer Management
- [ ] `models/customer_model.dart`
- [ ] `database/` - Thêm bảng customers
- [ ] `screens/download_data_screen.dart`
- [ ] `screens/customer_list_screen.dart`
- [ ] `screens/customer_detail_screen.dart`

### Phase 3: Meter Reading & Payment
- [ ] `models/meter_reading_model.dart`
- [ ] `models/payment_model.dart`
- [ ] `models/debt_model.dart`
- [ ] `services/camera_service.dart`
- [ ] `screens/add_reading_screen.dart`
- [ ] `screens/payment_screen.dart`

### Phase 4: Sync & History
- [ ] `services/api_service.dart`
- [ ] `services/sync_service.dart`
- [ ] `providers/sync_provider.dart`
- [ ] `screens/history_screen.dart`
- [ ] `screens/sync_screen.dart`

---

## 📚 TÀI LIỆU THAM KHẢO

Trong thư mục `water_meter_app/`:

1. **`CODE_STRUCTURE.md`**
   - Chi tiết cấu trúc code
   - Giải thích từng file
   - Luồng hoạt động

2. **`GETTING_STARTED.md`**
   - Hướng dẫn setup và chạy app
   - Troubleshooting
   - Tips & tricks

3. **`QUICK_REFERENCE.md`**
   - Tham khảo nhanh
   - Code snippets
   - Conventions

4. **`REFACTOR_SUMMARY.md`**
   - Tóm tắt thay đổi
   - So sánh trước/sau
   - Best practices

---

**Cập nhật:** 2026-06-02  
**Trạng thái:** ✅ Hoàn thành Phase 1 - Authentication
