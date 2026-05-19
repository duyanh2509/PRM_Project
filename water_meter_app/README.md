# 💧 Water Meter App - Ứng dụng Thu tiền nước

Ứng dụng di động hỗ trợ nhân viên thu tiền điện nước ghi chỉ số đồng hồ, chụp ảnh và đồng bộ dữ liệu. Hoạt động hoàn toàn OFFLINE, tự động đồng bộ khi có mạng.

## 🎯 Tính năng chính

### 1. ✅ Hoạt động OFFLINE - Không cần mạng
- Ghi chỉ số đồng hồ nước
- Chụp ảnh đồng hồ làm bằng chứng
- Lưu trữ dữ liệu local (SQLite)
- Xem danh sách khách hàng
- Xem lịch sử ghi số

### 2. 🔄 Đồng bộ tự động khi có mạng
- Tự động phát hiện kết nối internet
- Upload dữ liệu chưa đồng bộ lên server
- Upload ảnh đồng hồ
- Cập nhật trạng thái đồng bộ
- Xử lý lỗi và retry thông minh

### 3. 📊 Tổng hợp và báo cáo
- Danh sách tất cả khách hàng
- Lịch sử ghi số theo ngày/khách hàng
- Thống kê tiêu thụ nước
- Báo cáo số bản ghi chưa đồng bộ

---

## 📁 Cấu trúc thư mục dự án

```
water_meter_app/
│
├── lib/
│   ├── main.dart                           # Entry point của ứng dụng
│   │
│   ├── models/                             # Data Models
│   │   ├── customer.dart                   # Model khách hàng
│   │   └── meter_reading.dart              # Model chỉ số đồng hồ
│   │
│   ├── database/                           # SQLite Database
│   │   └── database_helper.dart            # Quản lý database local
│   │
│   ├── services/                           # Business Logic Services
│   │   ├── camera_service.dart             # Xử lý chụp ảnh
│   │   ├── sync_service.dart               # Logic đồng bộ dữ liệu
│   │   ├── api_service.dart                # HTTP API calls
│   │   └── connectivity_service.dart       # Kiểm tra kết nối mạng
│   │
│   ├── providers/                          # State Management (Provider)
│   │   ├── customer_provider.dart          # Quản lý state khách hàng
│   │   ├── reading_provider.dart           # Quản lý state ghi số
│   │   └── sync_provider.dart              # Quản lý state đồng bộ
│   │
│   ├── screens/                            # UI Screens
│   │   ├── home_screen.dart                # Màn hình chính (Dashboard)
│   │   ├── customer_list_screen.dart       # Danh sách khách hàng
│   │   ├── add_reading_screen.dart         # Ghi chỉ số mới + chụp ảnh
│   │   ├── reading_history_screen.dart     # Lịch sử ghi số
│   │   ├── summary_screen.dart             # Tổng hợp báo cáo
│   │   └── sync_screen.dart                # Màn hình đồng bộ
│   │
│   ├── widgets/                            # Reusable Widgets
│   │   ├── customer_card.dart              # Card hiển thị khách hàng
│   │   ├── reading_card.dart               # Card hiển thị lần ghi số
│   │   ├── sync_status_badge.dart          # Badge trạng thái đồng bộ
│   │   └── loading_overlay.dart            # Overlay loading
│   │
│   └── utils/                              # Utilities
│       ├── constants.dart                  # Constants (API URLs, colors...)
│       ├── helpers.dart                    # Helper functions
│       └── validators.dart                 # Input validators
│
├── assets/                                 # Assets (images, icons...)
│   └── images/
│       └── placeholder.png
│
├── test/                                   # Unit tests
│
├── pubspec.yaml                            # Dependencies
└── README.md                               # Documentation (file này)
```

---

## 🔄 Luồng hoạt động ứng dụng

### 📱 LUỒNG OFFLINE (Không có mạng)

```
┌─────────────────────────────────────────────────────────────────┐
│                    LUỒNG HOẠT ĐỘNG OFFLINE                      │
└─────────────────────────────────────────────────────────────────┘

1. MỞ ỨNG DỤNG
   ├── Kiểm tra kết nối mạng
   ├── Hiển thị trạng thái: "Chế độ Offline"
   └── Load dữ liệu từ SQLite local

2. XEM DANH SÁCH KHÁCH HÀNG
   ├── Query: SELECT * FROM customers
   ├── Hiển thị danh sách
   └── Tìm kiếm theo mã/tên khách hàng

3. CHỌN KHÁCH HÀNG CẦN GHI SỐ
   ├── Lấy thông tin khách hàng
   ├── Lấy chỉ số cũ (lần ghi gần nhất)
   └── Mở màn hình "Ghi số mới"

4. GHI CHỈ SỐ MỚI
   ├── Hiển thị thông tin:
   │   ├── Mã khách hàng: KH001
   │   ├── Tên: Nguyễn Văn A
   │   ├── Địa chỉ: 123 Đường ABC
   │   ├── Chỉ số cũ: 100.5 m³
   │   └── Chỉ số mới: [Nhập]
   │
   ├── CHỤP ẢNH ĐỒNG HỒ
   │   ├── Mở camera
   │   ├── Chụp ảnh
   │   ├── Lưu vào bộ nhớ local:
   │   │   Path: /storage/water_meter_images/KH001_20260519_103045.jpg
   │   └── Hiển thị preview ảnh
   │
   ├── NHẬP CHỈ SỐ MỚI
   │   ├── Validate: newReading > oldReading
   │   ├── Tính tiêu thụ: consumption = newReading - oldReading
   │   └── Thêm ghi chú (optional)
   │
   └── LƯU VÀO DATABASE LOCAL
       ├── INSERT INTO meter_readings (
       │     customerId, customerCode, customerName,
       │     oldReading, newReading, imagePath,
       │     readingDate, isSynced, notes
       │   ) VALUES (
       │     1, 'KH001', 'Nguyễn Văn A',
       │     100.5, 125.3, '/storage/.../KH001_xxx.jpg',
       │     '2026-05-19 10:30:45', 0, 'Đồng hồ hoạt động tốt'
       │   )
       │
       ├── isSynced = 0 (Chưa đồng bộ)
       └── Thông báo: "✓ Đã lưu thành công"

5. TIẾP TỤC GHI SỐ KHÁCH HÀNG KHÁC
   └── Quay lại bước 2

6. XEM LỊCH SỬ & THỐNG KÊ
   ├── Lịch sử ghi số hôm nay
   ├── Tổng số khách hàng đã ghi: 15
   ├── Tổng tiêu thụ: 450.5 m³
   └── Số bản ghi chưa đồng bộ: 15 ⚠️
```

---

### 🌐 LUỒNG ONLINE (Có mạng - Đồng bộ)

```
┌─────────────────────────────────────────────────────────────────┐
│                    LUỒNG HOẠT ĐỘNG ONLINE                       │
└─────────────────────────────────────────────────────────────────┘

1. PHÁT HIỆN KẾT NỐI MẠNG
   ├── App tự động lắng nghe connectivity changes
   ├── Phát hiện: WiFi hoặc Mobile Data
   ├── Hiển thị thông báo: "✓ Đã kết nối mạng"
   └── Hiển thị badge: "15 bản ghi chưa đồng bộ"

2. NGƯỜI DÙNG BẤM NÚT "ĐỒNG BỘ"
   ├── Kiểm tra lại kết nối
   ├── Nếu không có mạng → Thông báo lỗi
   └── Nếu có mạng → Tiếp tục

3. LẤY DANH SÁCH CHƯA ĐỒNG BỘ
   ├── Query: SELECT * FROM meter_readings WHERE isSynced = 0
   ├── Kết quả: 15 bản ghi
   └── Hiển thị danh sách cần sync

4. BẮT ĐẦU QUY TRÌNH ĐỒNG BỘ
   │
   ├── HIỂN THI PROGRESS
   │   ┌─────────────────────────────────┐
   │   │ Đang đồng bộ...                 │
   │   │ ████████░░░░░░░  8/15          │
   │   │                                 │
   │   │ ✓ KH001 - Nguyễn Văn A         │
   │   │ ✓ KH002 - Trần Thị B           │
   │   │ ⏳ KH008 - Đang upload...       │
   │   └─────────────────────────────────┘
   │
   └── XỬ LÝ TỪNG BẢN GHI:

       ┌──────────────────────────────────────────────┐
       │ BẢN GHI #1: KH001 - Nguyễn Văn A            │
       └──────────────────────────────────────────────┘
       
       BƯỚC 1: UPLOAD ẢNH
       ├── Đọc file: /storage/.../KH001_xxx.jpg
       ├── Nén ảnh (giảm dung lượng)
       ├── POST /api/upload-image
       │   Headers: {
       │     "Authorization": "Bearer <token>",
       │     "Content-Type": "multipart/form-data"
       │   }
       │   Body: {
       │     file: <binary>,
       │     customerCode: "KH001"
       │   }
       │
       ├── Response thành công:
       │   {
       │     "success": true,
       │     "imageUrl": "https://server.com/images/abc123.jpg"
       │   }
       └── Lưu imageUrl để dùng ở bước tiếp

       BƯỚC 2: UPLOAD DỮ LIỆU READING
       ├── POST /api/meter-readings
       │   Headers: {
       │     "Authorization": "Bearer <token>",
       │     "Content-Type": "application/json"
       │   }
       │   Body: {
       │     "customerCode": "KH001",
       │     "customerName": "Nguyễn Văn A",
       │     "address": "123 Đường ABC",
       │     "oldReading": 100.5,
       │     "newReading": 125.3,
       │     "consumption": 24.8,
       │     "readingDate": "2026-05-19T10:30:45Z",
       │     "imageUrl": "https://server.com/images/abc123.jpg",
       │     "notes": "Đồng hồ hoạt động tốt",
       │     "collectorId": "NV001"
       │   }
       │
       ├── Response thành công:
       │   {
       │     "success": true,
       │     "readingId": 12345,
       │     "message": "Đã lưu thành công"
       │   }
       └── Tiếp tục bước 3

       BƯỚC 3: CẬP NHẬT LOCAL DATABASE
       ├── UPDATE meter_readings 
       │   SET isSynced = 1 
       │   WHERE id = 1
       │
       ├── (Tùy chọn) Xóa ảnh local để tiết kiệm bộ nhớ
       │   File.delete('/storage/.../KH001_xxx.jpg')
       │
       └── Cập nhật UI: syncedCount = 1

       ┌──────────────────────────────────────────────┐
       │ LẶP LẠI CHO 14 BẢN GHI CÒN LẠI...           │
       └──────────────────────────────────────────────┘

5. XỬ LÝ LỖI (Nếu có)
   │
   ├── LỖI: MẤT MẠNG GIỮA CHỪNG
   │   ├── Dừng ngay lập tức
   │   ├── Giữ nguyên isSynced = 0 cho các bản ghi chưa upload
   │   └── Thông báo: "Mất kết nối. Đã đồng bộ 8/15 bản ghi"
   │
   ├── LỖI: SERVER 500 (Internal Server Error)
   │   ├── Retry lần 1 (đợi 2 giây)
   │   ├── Retry lần 2 (đợi 5 giây)
   │   ├── Retry lần 3 (đợi 10 giây)
   │   ├── Nếu vẫn lỗi → Bỏ qua, sync bản ghi tiếp theo
   │   └── Lưu log lỗi
   │
   ├── LỖI: UPLOAD ẢNH THẤT BẠI
   │   ├── Vẫn upload dữ liệu reading (imageUrl = null)
   │   └── Có thể upload ảnh lại sau
   │
   └── LỖI: DỮ LIỆU KHÔNG HỢP LỆ (400 Bad Request)
       ├── Không retry
       ├── Đánh dấu: syncError = true
       └── Cần xử lý thủ công

6. HIỂN THỊ KẾT QUẢ
   ┌─────────────────────────────────┐
   │ Đồng bộ hoàn tất!               │
   │                                 │
   │ ✅ Thành công: 13 bản ghi       │
   │ ❌ Thất bại: 2 bản ghi          │
   │                                 │
   │ Chi tiết lỗi:                   │
   │ • KH009: Lỗi kết nối            │
   │ • KH012: Dữ liệu không hợp lệ   │
   │                                 │
   │ [Thử lại]  [Đóng]               │
   └─────────────────────────────────┘

7. SAU KHI ĐỒNG BỘ THÀNH CÔNG
   ├── Dữ liệu đã lên server
   ├── isSynced = 1 trong local database
   ├── Có thể xem lại lịch sử
   └── Tiếp tục ghi số khách hàng mới
```

---

### 🔄 LUỒNG TỰ ĐỘNG ĐỒNG BỘ (Background Sync)

```
┌─────────────────────────────────────────────────────────────────┐
│              ĐỒNG BỘ TỰ ĐỘNG TRONG NỀN (OPTIONAL)              │
└─────────────────────────────────────────────────────────────────┘

1. App lắng nghe connectivity changes
   ├── Offline → Online: Trigger auto sync
   └── Kiểm tra định kỳ mỗi 30 phút

2. Nếu có bản ghi chưa sync VÀ có mạng
   ├── Hiển thị notification: "Đang đồng bộ ngầm..."
   ├── Chạy sync service trong background
   └── Không làm gián đoạn người dùng

3. Kết quả
   ├── Thành công → Notification: "✓ Đã đồng bộ 5 bản ghi"
   └── Thất bại → Notification: "⚠️ Đồng bộ thất bại, thử lại sau"
```

---

## 🗄️ Database Schema (SQLite)

### Bảng: `customers`
```sql
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerCode TEXT UNIQUE NOT NULL,
  customerName TEXT NOT NULL,
  address TEXT NOT NULL,
  phoneNumber TEXT,
  createdAt TEXT NOT NULL
);
```

### Bảng: `meter_readings`
```sql
CREATE TABLE meter_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  customerName TEXT NOT NULL,
  oldReading REAL NOT NULL,
  newReading REAL NOT NULL,
  imagePath TEXT,
  readingDate TEXT NOT NULL,
  isSynced INTEGER DEFAULT 0,  -- 0: chưa sync, 1: đã sync
  notes TEXT,
  FOREIGN KEY (customerId) REFERENCES customers(id)
);
```

---

## 🚀 Cài đặt và chạy ứng dụng

### Yêu cầu
- Flutter SDK >= 3.11.5
- Dart SDK >= 3.11.5
- Android Studio / VS Code
- Android device hoặc emulator

### Các bước cài đặt

1. **Clone repository**
```bash
git clone <repository-url>
cd water_meter_app
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Cấu hình API endpoint**
Sửa file `lib/utils/constants.dart`:
```dart
static const String API_BASE_URL = 'https://your-server.com/api';
```

4. **Chạy ứng dụng**
```bash
flutter run
```

---

## 📦 Dependencies chính

```yaml
dependencies:
  # Camera & Image
  camera: ^0.10.5+5
  image_picker: ^1.0.4
  
  # Local Storage
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  
  # Network
  connectivity_plus: ^5.0.1
  http: ^1.1.0
  
  # State Management
  provider: ^6.0.5
  
  # Utilities
  intl: ^0.18.1
  permission_handler: ^11.0.1
```

---

## 📝 Ghi chú quan trọng

### Quyền cần thiết (Android)
Thêm vào `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Quyền cần thiết (iOS)
Thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Cần quyền camera để chụp ảnh đồng hồ nước</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cần quyền truy cập thư viện ảnh</string>
```

---

## 👨‍💻 Phát triển bởi

- **Tên dự án**: Water Meter App
- **Môn học**: PRM393
- **Năm**: 2026

---

## 📄 License

This project is for educational purposes.
