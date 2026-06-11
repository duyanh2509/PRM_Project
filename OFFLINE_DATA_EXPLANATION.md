# 📱 GIẢI THÍCH: DATA OFFLINE HOẠT ĐỘNG NHƯ THẾ NÀO?

## 🎯 Tổng quan

**Data offline** có nghĩa là:
- ✅ App hoạt động **KHÔNG CẦN INTERNET**
- ✅ Data lưu trên **ĐIỆN THOẠI** (SQLite)
- ✅ Đọc/Ghi data **NGAY LẬP TỨC** không cần mạng

---

## 📂 TRONG CODE HIỆN TẠI

### 1️⃣ **Khai báo SQLite Package**

**File:** `pubspec.yaml`

```yaml
dependencies:
  sqflite: ^2.3.0  # ← Package SQLite cho Flutter
  path: ^1.8.3     # ← Helper tìm đường dẫn
```

**Giải thích:**
- `sqflite`: Cho phép tạo, đọc, ghi database trên điện thoại
- `path`: Tìm đường dẫn lưu file database

---

### 2️⃣ **Tạo Database Helper**

**File:** `lib/database/database_helper.dart`

#### A. Import và Singleton Pattern

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper class để quản lý SQLite database
class DatabaseHelper {
  // ⭐ Singleton pattern - CHỈ TẠO 1 INSTANCE
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;
```

**Giải thích:**
- Singleton đảm bảo chỉ có 1 database connection
- Tránh mở nhiều kết nối gây lỗi

---

#### B. Khởi tạo Database (OFFLINE)

```dart
Future<Database> get database async {
  if (_database != null) return _database!;
  _database = await _initDatabase();  // ← Tạo database lần đầu
  return _database!;
}

Future<Database> _initDatabase() async {
  // 1. Lấy đường dẫn lưu database trên điện thoại
  final databasePath = await getDatabasesPath();
  
  // 2. Tạo tên file: water_meter_app.db
  final path = join(databasePath, 'water_meter_app.db');
  
  // 3. Mở/Tạo database file
  return await openDatabase(
    path,
    version: 1,
    onCreate: _createTables,  // ← Tạo bảng lần đầu
  );
}
```

**⚡ ĐÂY LÀ OFFLINE:**
- `getDatabasesPath()`: Lấy đường dẫn local trên điện thoại
- `openDatabase()`: Tạo file `.db` trên điện thoại
- **KHÔNG CẦN INTERNET!**

**Đường dẫn file database:**
```
Android: /data/data/com.example.water_meter_app/databases/water_meter_app.db
iOS: <App Directory>/Documents/water_meter_app.db
```

---

#### C. Tạo Bảng (OFFLINE)

```dart
Future<void> _createTables(Database db, int version) async {
  // ⭐ Tạo bảng users
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      fullName TEXT NOT NULL,
      role TEXT DEFAULT 'staff',
      createdAt TEXT NOT NULL
    )
  ''');

  // ⭐ Insert demo users OFFLINE
  await db.insert('users', {
    'username': 'admin',
    'password': '12345678',
    'fullName': 'Quản trị viên',
    'role': 'admin',
    'createdAt': DateTime.now().toIso8601String(),
  });

  await db.insert('users', {
    'username': 'staff01',
    'password': '12345678',
    'fullName': 'Nhân viên A',
    'role': 'staff',
    'createdAt': DateTime.now().toIso8601String(),
  });
}
```

**⚡ ĐÂY LÀ OFFLINE:**
- `db.execute()`: Chạy SQL trên database local
- `db.insert()`: Thêm data vào database local
- **Data lưu trong file .db trên điện thoại**
- **KHÔNG GỬI LÊN SERVER!**

---

#### D. Login Check (OFFLINE)

```dart
/// Đăng nhập: kiểm tra username và password
Future<User?> login(String username, String password) async {
  final db = await database;  // ← Lấy database local
  
  // ⭐ Query database LOCAL (OFFLINE)
  final results = await db.query(
    'users',
    where: 'username = ? AND password = ?',
    whereArgs: [username, password],
  );

  if (results.isEmpty) {
    return null; // Đăng nhập thất bại
  }

  return User.fromMap(results.first);
}
```

**⚡ ĐÂY LÀ OFFLINE:**
- `db.query()`: Đọc data từ database local
- `where` + `whereArgs`: SQL query trên file .db local
- **KHÔNG GỌI API!**
- **KHÔNG CẦN INTERNET!**

---

### 3️⃣ **Provider Sử Dụng Database**

**File:** `lib/providers/auth_provider.dart`

```dart
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  Future<bool> login(String username, String password) async {
    // ... validate input ...
    
    // ⭐ Gọi database LOCAL (OFFLINE)
    final user = await _dbHelper.login(username.trim(), password);
    
    if (user == null) {
      _errorMessage = 'Username hoặc password không đúng';
      return false;
    }
    
    // ⭐ Lưu user vào memory (RAM) - OFFLINE
    _currentUser = user;
    notifyListeners();
    return true;
  }
}
```

**⚡ ĐÂY LÀ OFFLINE:**
- Gọi `_dbHelper.login()` → Query database local
- Không có HTTP request
- Không cần internet
- Data từ file .db trên điện thoại

---

### 4️⃣ **UI Sử Dụng Provider**

**File:** `lib/screens/login_screen.dart`

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // ⭐ Gọi login (OFFLINE)
  final success = await authProvider.login(
    _usernameController.text,
    _passwordController.text,
  );
  
  if (success) {
    // ⭐ Navigate - KHÔNG CẦN INTERNET
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }
}
```

**⚡ ĐÂY LÀ OFFLINE:**
- User nhập username/password
- Gọi `authProvider.login()` → Query SQLite
- Thành công → Chuyển màn hình
- **TẤT CẢ ĐỀU OFFLINE!**

---

## 🔄 LUỒNG DATA OFFLINE HOÀN CHỈNH

### Lần đầu tiên mở app:

```
App khởi động
    ↓
DatabaseHelper.instance.database
    ↓
_initDatabase()
    ↓
getDatabasesPath() → "/data/data/.../databases/"
    ↓
openDatabase("water_meter_app.db")
    ↓
File không tồn tại → onCreate: _createTables()
    ↓
CREATE TABLE users
    ↓
INSERT demo users (admin, staff01)
    ↓
Database sẵn sàng - File .db đã được tạo trên điện thoại
    ↓
✅ APP HOẠT ĐỘNG OFFLINE!
```

---

### Khi user login:

```
User nhập username + password
    ↓
LoginScreen._handleLogin()
    ↓
AuthProvider.login(username, password)
    ↓
DatabaseHelper.instance.login()
    ↓
db.query('users', where: 'username=? AND password=?')
    ↓
SQL query chạy trên FILE .db LOCAL
    ↓
┌─────────────────────────────┐
│  ⚡ KHÔNG CẦN INTERNET!     │
│  ⚡ ĐỌC TỪ FILE LOCAL!     │
│  ⚡ NHANH CHÓNG!            │
└─────────────────────────────┘
    ↓
Return User object (hoặc null)
    ↓
Update UI
    ↓
✅ LOGIN THÀNH CÔNG (OFFLINE)
```

---

## 📂 VỊ TRÍ DATA OFFLINE

### File database trên điện thoại:

**Android:**
```
/data/data/com.example.water_meter_app/databases/water_meter_app.db
```

**iOS:**
```
<Application Directory>/Documents/water_meter_app.db
```

### Kiểm tra file (Android):

```bash
# Kết nối với device
adb shell

# Vào thư mục app
cd /data/data/com.example.water_meter_app/databases/

# Xem file
ls -la
# → water_meter_app.db  ← File SQLite OFFLINE

# Xem data
sqlite3 water_meter_app.db
SELECT * FROM users;
# → admin|12345678|Quản trị viên|admin|...
# → staff01|12345678|Nhân viên A|staff|...
```

---

## 🔍 DEMO: CHỨNG MINH OFFLINE

### Test 1: Tắt mạng

```dart
// 1. Mở app
// 2. ✈️ BẬT CHẾ ĐỘ MÁY BAY (Airplane mode)
// 3. Thử login: admin / 12345678
// 4. ✅ LOGIN THÀNH CÔNG!

// Tại sao?
// → Vì data đọc từ SQLite LOCAL trên điện thoại
// → KHÔNG GỌI API, KHÔNG CẦN INTERNET!
```

### Test 2: Xem network activity

```dart
// 1. Mở DevTools → Network tab
// 2. Login vào app
// 3. Xem network requests
// 4. ❌ KHÔNG CÓ HTTP REQUEST NÀO!

// Tại sao?
// → Vì app chỉ query SQLite local
// → Không gọi API
```

---

## 💡 SO SÁNH: OFFLINE vs ONLINE

### ❌ ONLINE (Cần internet):

```dart
// Login call API
Future<User?> loginOnline(String username, String password) async {
  // ⚠️ CẦN INTERNET
  final response = await http.post(
    Uri.parse('https://api.example.com/login'),
    body: {'username': username, 'password': password},
  );
  
  if (response.statusCode == 200) {
    return User.fromJson(jsonDecode(response.body));
  }
  return null;
}

// Nhược điểm:
// ❌ Cần internet
// ❌ Chậm (phải đợi server)
// ❌ Không hoạt động khi offline
```

### ✅ OFFLINE (Không cần internet):

```dart
// Login query SQLite
Future<User?> loginOffline(String username, String password) async {
  final db = await database;
  
  // ⚡ KHÔNG CẦN INTERNET
  final results = await db.query(
    'users',
    where: 'username = ? AND password = ?',
    whereArgs: [username, password],
  );
  
  if (results.isEmpty) return null;
  return User.fromMap(results.first);
}

// Ưu điểm:
// ✅ Không cần internet
// ✅ Nhanh (query local)
// ✅ Hoạt động mọi lúc
```

---

## 🎯 TÓM TẮT

### Data offline được thể hiện ở đâu?

| File | Chức năng | Offline? |
|------|-----------|----------|
| `database_helper.dart` | Tạo & quản lý SQLite | ✅ 100% |
| `auth_provider.dart` | Gọi database local | ✅ 100% |
| `login_screen.dart` | UI gọi provider | ✅ 100% |
| `user_model.dart` | Model data | ✅ 100% |

### Cách hoạt động:

```
User Input → Provider → DatabaseHelper → SQLite File → Return Data
                                            ↑
                                    ⚡ FILE LOCAL
                                    ⚡ KHÔNG CẦN MẠNG
                                    ⚡ TỐC ĐỘ CAO
```

### Khi nào cần internet?

Hiện tại: **KHÔNG BAO GIỜ** (100% offline)

Tương lai (Phase 4 - Sync):
- ✅ Download data từ server (ONLINE)
- ✅ Upload data lên server (ONLINE)
- ✅ Work với data local (OFFLINE)

---

## 📝 CODE EXAMPLE: THÊM DATA OFFLINE

```dart
// Thêm customer mới (OFFLINE)
Future<void> addCustomer() async {
  final db = await DatabaseHelper.instance.database;
  
  // ⚡ INSERT vào database LOCAL
  await db.insert('customers', {
    'customerCode': 'KH003',
    'customerName': 'Lê Văn C',
    'address': '789 Đường DEF',
    'phoneNumber': '0923456789',
  });
  
  // ✅ Data đã lưu OFFLINE trong file .db
  // ✅ KHÔNG GỬI LÊN SERVER
  // ✅ KHÔNG CẦN INTERNET
}

// Đọc customers (OFFLINE)
Future<List<Customer>> getCustomers() async {
  final db = await DatabaseHelper.instance.database;
  
  // ⚡ SELECT từ database LOCAL
  final results = await db.query('customers');
  
  // ✅ Data đọc từ file .db LOCAL
  // ✅ KHÔNG GỌI API
  // ✅ NHANH CHÓNG
  
  return results.map((map) => Customer.fromMap(map)).toList();
}
```

---

**Kết luận:**
- ✅ **100% code hiện tại hoạt động OFFLINE**
- ✅ **Data lưu trong file SQLite trên điện thoại**
- ✅ **Không cần internet để login**
- ✅ **DatabaseHelper là nơi xử lý tất cả data offline**
