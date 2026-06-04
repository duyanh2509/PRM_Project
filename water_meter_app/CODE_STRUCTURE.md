# 📂 Cấu trúc code - Water Meter App

## 📁 Tổng quan cấu trúc thư mục

```
lib/
├── main.dart                      # Entry point - Khởi chạy app
├── models/                        # Data models
│   └── user_model.dart           # Model User (nhân viên)
├── database/                      # SQLite database
│   └── database_helper.dart      # Helper quản lý database
├── providers/                     # State management (Provider)
│   └── auth_provider.dart        # Provider quản lý authentication
└── screens/                       # UI Screens
    ├── login_screen.dart         # Màn hình đăng nhập
    └── home_screen.dart          # Màn hình chính
```

---

## 📄 Chi tiết từng file

### 1. `main.dart`
**Mục đích:** Entry point của ứng dụng, chỉ khởi chạy app

**Nội dung:**
- `main()`: Hàm khởi đầu
- `MyApp`: Root widget
- Setup Provider
- Setup MaterialApp
- Điều hướng đến `LoginScreen`

**Quy tắc:** Không viết logic nghiệp vụ trong file này

---

### 2. `models/user_model.dart`
**Mục đích:** Định nghĩa model User

**Nội dung:**
- Class `User` với các thuộc tính:
  - `id`: ID user trong database
  - `username`: Tên đăng nhập
  - `password`: Mật khẩu (đã hash trong production)
  - `fullName`: Tên đầy đủ
  - `role`: Vai trò (staff)
  - `createdAt`: Ngày tạo
- `fromMap()`: Chuyển Map → User object
- `toMap()`: Chuyển User object → Map
- `copyWith()`: Tạo bản sao với một số field thay đổi

**Khi nào dùng:** Khi cần lưu/đọc user từ database hoặc truyền data giữa các màn hình

---

### 3. `database/database_helper.dart`
**Mục đích:** Quản lý SQLite database

**Nội dung:**
- Singleton pattern: Đảm bảo chỉ có 1 instance database
- `_initDatabase()`: Khởi tạo database file
- `_createTables()`: Tạo các bảng (users, ...)
- `login()`: Kiểm tra username + password
- `getUserById()`: Lấy user theo ID
- `getAllUsers()`: Lấy tất cả users
- `insertUser()`: Thêm user mới
- `updateUser()`: Cập nhật user
- `deleteUser()`: Xóa user
- `close()`: Đóng database

**Demo accounts:**
- Username: `staff01`, Password: `12345678` (role: staff)
- Username: `staff02`, Password: `12345678` (role: staff)
- Username: `staff03`, Password: `12345678` (role: staff)

**Khi nào dùng:** Mọi thao tác với database đều thông qua class này

---

### 4. `providers/auth_provider.dart`
**Mục đích:** Quản lý state đăng nhập (Provider pattern)

**Nội dung:**
- `_currentUser`: User hiện tại (null = chưa đăng nhập)
- `_isLoading`: Trạng thái loading
- `_errorMessage`: Thông báo lỗi
- `login()`: Xử lý đăng nhập
  1. Validate input
  2. Gọi `DatabaseHelper.login()`
  3. Cập nhật state
  4. Thông báo UI (notifyListeners)
- `logout()`: Đăng xuất (set user = null)
- `clearError()`: Xóa error message

**Khi nào dùng:** 
- Trong UI: Dùng `Consumer<AuthProvider>` hoặc `Provider.of<AuthProvider>`
- Để lấy thông tin user hiện tại
- Để kiểm tra trạng thái đăng nhập

---

### 5. `screens/login_screen.dart`
**Mục đích:** Màn hình đăng nhập

**Nội dung:**
- Form với 2 field: Username, Password
- Validation:
  - Username không được rỗng
  - Password tối thiểu 6 ký tự
- Button "Đăng nhập"
- Loading indicator khi đang xử lý
- Hiển thị error nếu đăng nhập thất bại
- Chuyển sang `HomeScreen` nếu thành công
- Hiển thị thông tin tài khoản demo

**Flow đăng nhập:**
```
User nhập username + password
    ↓
Nhấn "Đăng nhập"
    ↓
Validate form
    ↓
Gọi AuthProvider.login()
    ↓
DatabaseHelper.login() → Check database
    ↓
├─ Đúng → Lưu user → Navigate to HomeScreen
└─ Sai → Hiển thị error
```

---

### 6. `screens/home_screen.dart`
**Mục đích:** Màn hình chính sau khi đăng nhập

**Nội dung:**
- AppBar với nút "Đăng xuất"
- Card hiển thị thông tin user:
  - Avatar với chữ cái đầu
  - Tên đầy đủ
  - Username
  - Role (staff)
- Grid 4 action cards:
  - Tải dữ liệu
  - Khách hàng
  - Lịch sử
  - Đồng bộ
- Dialog xác nhận khi đăng xuất

**Khi nào dùng:** Sau khi đăng nhập thành công

---

## 🔄 Luồng hoạt động (Flow)

### Luồng khởi động app
```
main()
  ↓
MyApp (setup Provider)
  ↓
MaterialApp
  ↓
LoginScreen (màn hình đầu tiên)
```

### Luồng đăng nhập
```
LoginScreen
  ↓
User nhập username + password
  ↓
Nhấn "Đăng nhập"
  ↓
AuthProvider.login()
  ├─ Validate input
  ├─ DatabaseHelper.login()
  └─ Kiểm tra database
      ↓
├─ Thành công: Lưu user → Navigate to HomeScreen
└─ Thất bại: Hiển thị error
```

### Luồng đăng xuất
```
HomeScreen
  ↓
Nhấn icon "Đăng xuất"
  ↓
Hiển thị dialog xác nhận
  ↓
User xác nhận
  ↓
AuthProvider.logout()
  ↓
Navigate về LoginScreen
```

---

## 🎨 Quy tắc đặt tên file

| Loại file | Quy tắc | Ví dụ |
|-----------|---------|-------|
| Screen | `<tên>_screen.dart` | `login_screen.dart` |
| Model | `<tên>_model.dart` | `user_model.dart` |
| Provider | `<tên>_provider.dart` | `auth_provider.dart` |
| Service | `<tên>_service.dart` | `api_service.dart` |
| Helper | `<tên>_helper.dart` | `database_helper.dart` |
| Widget | `<tên>_widget.dart` | `custom_button_widget.dart` |

**Lý do:** Đọc tên file là biết ngay nội dung bên trong

---

## 🔧 Dependencies đang sử dụng

```yaml
dependencies:
  # Camera và xử lý ảnh
  camera: ^0.10.5+5
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Database local (SQLite)
  sqflite: ^2.3.0
  
  # Kết nối mạng
  connectivity_plus: ^5.0.1
  http: ^1.1.0
  
  # State management
  provider: ^6.0.5
  
  # Hiển thị ảnh
  cached_network_image: ^3.3.0
  
  # Format ngày tháng
  intl: ^0.18.1
  
  # Permission
  permission_handler: ^11.0.1
```

---

## 📝 Các bước tiếp theo

1. ✅ Đã hoàn thành:
   - Setup project structure
   - User model
   - Database helper
   - Auth provider
   - Login screen
   - Home screen

2. 🔜 Cần làm tiếp:
   - Customer model
   - Meter reading model
   - Payment model
   - Debt model
   - Download data screen
   - Customer list screen
   - Add reading screen
   - Payment screen
   - History screen
   - Sync screen
   - API service
   - Camera service

---

## 💡 Lưu ý khi phát triển

1. **Không viết logic trong main.dart**
   - main.dart chỉ để khởi chạy app
   - Logic nghiệp vụ đặt trong provider/service

2. **Đặt tên file rõ ràng**
   - Đọc tên file phải biết ngay nội dung
   - Follow quy tắc `<tên>_<loại>.dart`

3. **Tách UI và Logic**
   - UI: Trong `screens/` và `widgets/`
   - Logic: Trong `providers/` và `services/`
   - Data: Trong `models/`
   - Database: Trong `database/`

4. **Sử dụng Provider đúng cách**
   - Dùng `Consumer` cho widget cần rebuild
   - Dùng `Provider.of(listen: false)` cho actions
   - Luôn gọi `notifyListeners()` sau khi thay đổi state

5. **Database operations**
   - Mọi thao tác database phải async
   - Luôn handle exceptions
   - Close database khi không dùng

---

**Cập nhật:** 2026-06-02
