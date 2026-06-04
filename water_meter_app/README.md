# 💧 Water Meter App - Ứng dụng Thu tiền nước

Ứng dụng di động hỗ trợ nhân viên thu tiền điện nước ghi chỉ số đồng hồ, chụp ảnh và đồng bộ dữ liệu. Hoạt động hoàn toàn OFFLINE, tự động đồng bộ khi có mạng.

## ✅ Trạng thái phát triển

- ✅ **Phase 1:** Cấu trúc project + Authentication (Hoàn thành)
  - Setup project structure
  - User model
  - Database SQLite
  - Login screen (username + password)
  - Home screen cơ bản
  - State management với Provider

- 🔜 **Phase 2:** Quản lý khách hàng (Đang phát triển)
  - Customer model
  - Download data screen
  - Customer list screen
  - Customer detail screen

- 🔜 **Phase 3:** Ghi số và thu tiền
  - Meter reading model
  - Payment model
  - Camera integration
  - Add reading screen
  - Payment screen

- 🔜 **Phase 4:** Đồng bộ và báo cáo
  - Sync service
  - History screens
  - Reports

---

## 🎯 Tính năng chính

### 1. 📥 Tải dữ liệu trước khi đi thu (ONLINE)
- **Download thông tin khách hàng** từ server về local
- Thông tin bao gồm:
  - Danh sách khách hàng được phân công
  - Chỉ số tháng trước
  - **Công nợ** (số tháng nợ, số tiền nợ)
  - Lịch sử thanh toán
- Lưu vào SQLite để dùng OFFLINE
- Cập nhật dữ liệu mới nhất trước mỗi ca làm việc

### 2. ✅ Hoạt động OFFLINE - Không cần mạng
- Ghi chỉ số đồng hồ nước
- Chụp ảnh đồng hồ làm bằng chứng
- **Thu tiền** (tiền tháng hiện tại + tiền nợ)
- Tính toán tự động:
  - Tiêu thụ = Chỉ số mới - Chỉ số cũ
  - Tiền tháng này = Tiêu thụ × Đơn giá
  - **Tổng thu = Tiền tháng này + Tiền nợ**
- Lưu trữ dữ liệu local (SQLite)
- Xem danh sách khách hàng
- Xem lịch sử ghi số

### 3. 💰 Quản lý thu tiền và công nợ
- Hiển thị **công nợ** của từng khách hàng
- Thu tiền tháng hiện tại
- Thu tiền nợ (có thể thu một phần hoặc toàn bộ)
- Ghi nhận số tiền đã thu
- Cập nhật trạng thái công nợ
- In/Lưu biên lai (optional)

### 4. 🔄 Đồng bộ tự động khi có mạng
- Tự động phát hiện kết nối internet
- Upload dữ liệu chưa đồng bộ lên server:
  - Chỉ số đồng hồ mới
  - Ảnh đồng hồ
  - **Thông tin thu tiền**
  - **Cập nhật trạng thái công nợ**
- Cập nhật trạng thái đồng bộ
- Xử lý lỗi và retry thông minh

### 5. 📊 Tổng hợp và báo cáo
- Danh sách tất cả khách hàng
- Lịch sử ghi số theo ngày/khách hàng
- Thống kê tiêu thụ nước
- **Thống kê thu tiền** (đã thu, chưa thu)
- **Báo cáo công nợ**
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
│   │   ├── meter_reading.dart              # Model chỉ số đồng hồ
│   │   ├── payment.dart                    # Model thu tiền
│   │   └── debt.dart                       # Model công nợ
│   │
│   ├── database/                           # SQLite Database
│   │   └── database_helper.dart            # Quản lý database local
│   │
│   ├── services/                           # Business Logic Services
│   │   ├── camera_service.dart             # Xử lý chụp ảnh
│   │   ├── sync_service.dart               # Logic đồng bộ dữ liệu
│   │   ├── download_service.dart           # Download dữ liệu từ server
│   │   ├── payment_service.dart            # Xử lý thu tiền
│   │   ├── api_service.dart                # HTTP API calls
│   │   └── connectivity_service.dart       # Kiểm tra kết nối mạng
│   │
│   ├── providers/                          # State Management (Provider)
│   │   ├── customer_provider.dart          # Quản lý state khách hàng
│   │   ├── reading_provider.dart           # Quản lý state ghi số
│   │   ├── payment_provider.dart           # Quản lý state thu tiền
│   │   └── sync_provider.dart              # Quản lý state đồng bộ
│   │
│   ├── screens/                            # UI Screens
│   │   ├── home_screen.dart                # Màn hình chính (Dashboard)
│   │   ├── download_data_screen.dart       # Tải dữ liệu từ server
│   │   ├── customer_list_screen.dart       # Danh sách khách hàng
│   │   ├── customer_detail_screen.dart     # Chi tiết KH (công nợ, lịch sử)
│   │   ├── add_reading_screen.dart         # Ghi chỉ số mới + chụp ảnh
│   │   ├── payment_screen.dart             # Thu tiền (tháng này + nợ)
│   │   ├── reading_history_screen.dart     # Lịch sử ghi số
│   │   ├── payment_history_screen.dart     # Lịch sử thu tiền
│   │   ├── summary_screen.dart             # Tổng hợp báo cáo
│   │   └── sync_screen.dart                # Màn hình đồng bộ
│   │
│   ├── widgets/                            # Reusable Widgets
│   │   ├── customer_card.dart              # Card hiển thị khách hàng
│   │   ├── reading_card.dart               # Card hiển thị lần ghi số
│   │   ├── payment_card.dart               # Card hiển thị thu tiền
│   │   ├── debt_badge.dart                 # Badge hiển thị công nợ
│   │   ├── sync_status_badge.dart          # Badge trạng thái đồng bộ
│   │   └── loading_overlay.dart            # Overlay loading
│   │
│   └── utils/                              # Utilities
│       ├── constants.dart                  # Constants (API URLs, colors...)
│       ├── helpers.dart                    # Helper functions
│       ├── price_calculator.dart           # Tính tiền nước
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

### 📥 LUỒNG CHUẨN BỊ (Trước khi đi thu - CẦN MẠNG)

```
┌─────────────────────────────────────────────────────────────────┐
│           LUỒNG TẢI DỮ LIỆU TRƯỚC KHI ĐI THU (ONLINE)          │
└─────────────────────────────────────────────────────────────────┘

1. ĐĂNG NHẬP
   ├── Nhân viên đăng nhập vào app
   ├── Kiểm tra kết nối mạng: ✓ Online
   └── Chuyển đến Home Screen

2. VÀO MÀNG HÌNH "TẢI DỮ LIỆU"
   ├── Home → [Tải dữ liệu mới]
   ├── Hiển thị: "Cần tải dữ liệu trước khi đi thu"
   └── Button: [TẢI DỮ LIỆU]

3. DOWNLOAD DỮ LIỆU TỪ SERVER
   ├── GET /api/staff/{staffId}/assigned-customers
   │   Response: {
   │     "customers": [
   │       {
   │         "customerId": 1,
   │         "customerCode": "KH001",
   │         "customerName": "Nguyễn Văn A",
   │         "address": "123 Đường ABC",
   │         "phoneNumber": "0901234567",
   │         "lastReading": 100.5,
   │         "lastReadingDate": "2026-04-25",
   │         "pricePerUnit": 15000,
   │         
   │         // THÔNG TIN CÔNG NỢ
   │         "debt": {
   │           "totalDebt": 450000,        // Tổng nợ
   │           "debtMonths": 3,            // Nợ 3 tháng
   │           "debtDetails": [
   │             {
   │               "month": "2026-02",
   │               "amount": 150000,
   │               "consumption": 10.0,
   │               "status": "unpaid"
   │             },
   │             {
   │               "month": "2026-03",
   │               "amount": 150000,
   │               "consumption": 10.0,
   │               "status": "unpaid"
   │             },
   │             {
   │               "month": "2026-04",
   │               "amount": 150000,
   │               "consumption": 10.0,
   │               "status": "unpaid"
   │             }
   │           ]
   │         },
   │         
   │         // LỊCH SỬ THANH TOÁN
   │         "paymentHistory": [
   │           {
   │             "month": "2026-01",
   │             "amount": 150000,
   │             "paidDate": "2026-02-05",
   │             "status": "paid"
   │           }
   │         ]
   │       },
   │       // ... các khách hàng khác
   │     ],
   │     "totalCustomers": 50
   │   }
   │
   ├── HIỂN THỊ PROGRESS
   │   ┌─────────────────────────────────┐
   │   │ Đang tải dữ liệu...             │
   │   │ ████████████░░░░  35/50        │
   │   │                                 │
   │   │ ✓ KH001 - Nguyễn Văn A         │
   │   │ ✓ KH002 - Trần Thị B           │
   │   │ ⏳ KH035 - Đang tải...          │
   │   └─────────────────────────────────┘
   │
   └── LƯU VÀO DATABASE LOCAL

4. LƯU DỮ LIỆU VÀO SQLITE
   ├── XÓA dữ liệu cũ (nếu có)
   │   DELETE FROM customers;
   │   DELETE FROM debts;
   │
   ├── INSERT customers
   │   INSERT INTO customers (
   │     customerId, customerCode, customerName,
   │     address, phoneNumber, lastReading,
   │     lastReadingDate, pricePerUnit
   │   ) VALUES (...);
   │
   ├── INSERT debts (công nợ)
   │   INSERT INTO debts (
   │     customerId, month, amount,
   │     consumption, status
   │   ) VALUES (...);
   │
   └── Cập nhật lastDownloadDate = NOW()

5. HOÀN TẤT
   ┌─────────────────────────────────┐
   │ ✅ Tải dữ liệu thành công!      │
   │                                 │
   │ 📊 Tổng quan:                   │
   │ • Tổng KH: 50                   │
   │ • KH có nợ: 15                  │
   │ • Tổng công nợ: 6,750,000 VNĐ  │
   │                                 │
   │ Bạn có thể làm việc OFFLINE!    │
   │                                 │
   │ [OK]                            │
   └─────────────────────────────────┘

6. SẴN SÀNG ĐI THU
   └── Giờ có thể tắt mạng và đi thu tiền OFFLINE
```

---

### 📱 LUỒNG OFFLINE (Không có mạng - Đi thu tiền)

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
   ├── **Hiển thị CÔNG NỢ (nếu có)**
   │   ⚠️ Khách hàng nợ 3 tháng: 450,000 VNĐ
   └── Mở màn hình "Ghi số mới"

4. GHI CHỈ SỐ MỚI VÀ THU TIỀN
   ├── Hiển thị thông tin:
   │   ├── Mã khách hàng: KH001
   │   ├── Tên: Nguyễn Văn A
   │   ├── Địa chỉ: 123 Đường ABC
   │   ├── Chỉ số cũ: 100.5 m³
   │   ├── Chỉ số mới: [Nhập]
   │   │
   │   ├── **CÔNG NỢ:**
   │   │   ⚠️ Nợ 3 tháng: 450,000 VNĐ
   │   │   • Tháng 02/2026: 150,000 VNĐ
   │   │   • Tháng 03/2026: 150,000 VNĐ
   │   │   • Tháng 04/2026: 150,000 VNĐ
   │   │
   │   └── **TÍNH TIỀN:**
   │       • Tiêu thụ tháng này: 24.8 m³
   │       • Tiền tháng này: 372,000 VNĐ
   │       • Tiền nợ: 450,000 VNĐ
   │       • **TỔNG PHẢI THU: 822,000 VNĐ**
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
   │   ├── Tính tiền: amount = consumption × pricePerUnit
   │   └── Thêm ghi chú (optional)
   │
   ├── **THU TIỀN**
   │   ├── Button: [THU TIỀN]
   │   ├── Mở Payment Screen
   │   │
   │   ├── Hiển thị:
   │   │   ┌─────────────────────────────────┐
   │   │   │ THU TIỀN - KH001               │
   │   │   │                                 │
   │   │   │ Tiền tháng này: 372,000 VNĐ    │
   │   │   │ Tiền nợ: 450,000 VNĐ           │
   │   │   │ ─────────────────────────────   │
   │   │   │ TỔNG: 822,000 VNĐ              │
   │   │   │                                 │
   │   │   │ Số tiền thu: [________] VNĐ    │
   │   │   │                                 │
   │   │   │ ☐ Thu đủ (822,000)             │
   │   │   │ ☐ Thu một phần                 │
   │   │   │                                 │
   │   │   │ Ghi chú: [________________]    │
   │   │   │                                 │
   │   │   │ [XÁC NHẬN THU TIỀN]            │
   │   │   └─────────────────────────────────┘
   │   │
   │   ├── TÍNH TOÁN KHI THU MỘT PHẦN:
   │   │   Ví dụ: Thu 500,000 VNĐ
   │   │   ├── Trả tháng này: 372,000 VNĐ (đủ)
   │   │   ├── Trả nợ: 128,000 VNĐ
   │   │   ├── Còn nợ: 322,000 VNĐ (2 tháng 02 + 1 phần tháng 03)
   │   │   └── Cập nhật debt status
   │   │
   │   └── LƯU THÔNG TIN THU TIỀN
   │       INSERT INTO payments (
   │         customerId, customerCode,
   │         month, readingId,
   │         currentMonthAmount, debtAmount,
   │         totalAmount, amountPaid,
   │         remainingDebt, paymentDate,
   │         notes, isSynced
   │       ) VALUES (
   │         1, 'KH001',
   │         '2026-05', 123,
   │         372000, 450000,
   │         822000, 500000,
   │         322000, '2026-05-19 10:30:45',
   │         'Thu một phần', 0
   │       )
   │
   └── LƯU VÀO DATABASE LOCAL
       ├── INSERT meter_readings (chỉ số đồng hồ)
       ├── INSERT payments (thông tin thu tiền)
       ├── UPDATE debts (cập nhật công nợ)
       │   • Nếu thu đủ → status = 'paid'
       │   • Nếu thu một phần → cập nhật số tiền còn nợ
       │
       ├── isSynced = 0 (Chưa đồng bộ)
       └── Thông báo: "✓ Đã lưu và thu tiền thành công"

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

       BƯỚC 2: UPLOAD DỮ LIỆU READING VÀ PAYMENT
       ├── POST /api/meter-readings-with-payment
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
       │     "collectorId": "NV001",
       │     
       │     // THÔNG TIN THU TIỀN
       │     "payment": {
       │       "month": "2026-05",
       │       "currentMonthAmount": 372000,
       │       "debtAmount": 450000,
       │       "totalAmount": 822000,
       │       "amountPaid": 500000,
       │       "remainingDebt": 322000,
       │       "paymentDate": "2026-05-19T10:30:45Z",
       │       "notes": "Thu một phần"
       │     },
       │     
       │     // CẬP NHẬT CÔNG NỢ
       │     "debtUpdate": {
       │       "paidDebts": [
       │         {
       │           "month": "2026-02",
       │           "amount": 150000,
       │           "status": "paid"
       │         }
       │       ],
       │       "partialPaidDebts": [
       │         {
       │           "month": "2026-03",
       │           "paidAmount": 128000,
       │           "remainingAmount": 22000,
       │           "status": "partial"
       │         }
       │       ],
       │       "unpaidDebts": [
       │         {
       │           "month": "2026-04",
       │           "amount": 150000,
       │           "status": "unpaid"
       │         }
       │       ]
       │     }
       │   }
       │
       ├── Response thành công:
       │   {
       │     "success": true,
       │     "readingId": 12345,
       │     "paymentId": 67890,
       │     "message": "Đã lưu và cập nhật công nợ thành công"
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
  lastReading REAL,
  lastReadingDate TEXT,
  pricePerUnit REAL NOT NULL DEFAULT 15000,
  createdAt TEXT NOT NULL,
  updatedAt TEXT
);
```

### Bảng: `debts` (Công nợ)
```sql
CREATE TABLE debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  month TEXT NOT NULL,              -- Format: YYYY-MM
  amount REAL NOT NULL,             -- Số tiền nợ
  consumption REAL,                 -- Tiêu thụ tháng đó
  status TEXT DEFAULT 'unpaid',     -- unpaid, partial, paid
  paidAmount REAL DEFAULT 0,        -- Số tiền đã trả (nếu trả một phần)
  remainingAmount REAL,             -- Số tiền còn nợ
  createdAt TEXT NOT NULL,
  FOREIGN KEY (customerId) REFERENCES customers(id)
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
  consumption REAL NOT NULL,
  imagePath TEXT,
  readingDate TEXT NOT NULL,
  month TEXT NOT NULL,              -- Format: YYYY-MM
  isSynced INTEGER DEFAULT 0,       -- 0: chưa sync, 1: đã sync
  notes TEXT,
  FOREIGN KEY (customerId) REFERENCES customers(id)
);
```

### Bảng: `payments` (Thu tiền)
```sql
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  readingId INTEGER,                -- Link đến meter_readings
  month TEXT NOT NULL,              -- Tháng thu tiền (YYYY-MM)
  currentMonthAmount REAL NOT NULL, -- Tiền tháng hiện tại
  debtAmount REAL DEFAULT 0,        -- Tổng tiền nợ
  totalAmount REAL NOT NULL,        -- Tổng phải thu
  amountPaid REAL NOT NULL,         -- Số tiền đã thu
  remainingDebt REAL DEFAULT 0,     -- Số tiền còn nợ sau khi thu
  paymentDate TEXT NOT NULL,
  notes TEXT,
  isSynced INTEGER DEFAULT 0,       -- 0: chưa sync, 1: đã sync
  FOREIGN KEY (customerId) REFERENCES customers(id),
  FOREIGN KEY (readingId) REFERENCES meter_readings(id)
);
```

### Bảng: `sync_log` (Log đồng bộ)
```sql
CREATE TABLE sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recordType TEXT NOT NULL,         -- reading, payment, debt
  recordId INTEGER NOT NULL,
  syncStatus TEXT NOT NULL,         -- success, failed, pending
  errorMessage TEXT,
  syncDate TEXT NOT NULL
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
