# 🔄 DATA FLOW DIAGRAM - Water Meter App

## 📊 Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────────────────┐
│                    KIẾN TRÚC OFFLINE-FIRST                          │
└─────────────────────────────────────────────────────────────────────┘

          ┌──────────────────────────────────────┐
          │       NHÂN VIÊN SỬ DỤNG APP         │
          │    (Flutter trên điện thoại)        │
          └──────────────┬───────────────────────┘
                         │
                         │ ① User Action
                         │ (Login, Ghi số, Thu tiền...)
                         ▼
          ┌──────────────────────────────────────┐
          │         FLUTTER APP                  │
          │  ┌────────────────────────────────┐  │
          │  │  UI (Screens)                  │  │
          │  └────────────┬───────────────────┘  │
          │               │                       │
          │  ┌────────────▼───────────────────┐  │
          │  │  Logic (Providers/Services)    │  │
          │  └────────────┬───────────────────┘  │
          │               │                       │
          └───────────────┼───────────────────────┘
                          │
         ┌────────────────┴────────────────┐
         │                                 │
    ② OFFLINE                         ③ ONLINE
    (Không cần mạng)                  (Cần mạng)
         │                                 │
         ▼                                 ▼
┌─────────────────────┐         ┌──────────────────────┐
│   LOCAL DATABASE    │         │    BACKEND API       │
│     (SQLite)        │         │   (REST Server)      │
│                     │         │                      │
│  • users            │         │  POST /auth/login    │
│  • customers        │         │  GET  /customers     │
│  • meter_readings   │ ←──Sync─│  POST /sync/reading  │
│  • payments         │ ──Sync→ │  POST /sync/payment  │
│  • debts            │         │  POST /upload-image  │
│                     │         │                      │
│ Lưu trên điện thoại │         └──────────┬───────────┘
└─────────────────────┘                    │
                                           │ ④ CRUD
                                           ▼
                              ┌──────────────────────────┐
                              │   SERVER DATABASE        │
                              │   (PostgreSQL/MySQL)     │
                              │                          │
                              │  • staff                 │
                              │  • customers             │
                              │  • meter_readings        │
                              │  • payments              │
                              │  • debts                 │
                              │                          │
                              │ Lưu trên cloud server    │
                              └──────────────────────────┘

                    ┌──────────────────────────┐
                    │   IMAGE STORAGE          │
                    │   (AWS S3/Cloudinary)    │
                    │                          │
                    │  /readings/              │
                    │    KH001_xxx.jpg         │
                    │    KH002_xxx.jpg         │
                    └──────────────────────────┘
```

---

## 🔄 LUỒNG 1: ĐĂNG NHẬP

```
┌────────────┐
│  USER      │
│ (Nhân viên)│
└─────┬──────┘
      │
      │ ① Nhập username + password
      │
      ▼
┌─────────────────────────┐
│  LoginScreen            │
│  (Flutter UI)           │
└─────┬───────────────────┘
      │
      │ ② Gọi AuthProvider.login()
      │
      ▼
┌─────────────────────────┐
│  AuthProvider           │
│  (State Management)     │
└─────┬───────────────────┘
      │
      │ ③ Query database
      │
      ▼
┌─────────────────────────┐
│  DatabaseHelper         │
│  (SQLite local)         │
│                         │
│  SELECT * FROM users    │
│  WHERE username=?       │
│  AND password=?         │
└─────┬───────────────────┘
      │
      │ ④ Return User object (hoặc null)
      │
      ▼
┌─────────────────────────┐
│  AuthProvider           │
│  - Update state         │
│  - Set currentUser      │
│  - notifyListeners()    │
└─────┬───────────────────┘
      │
      │ ⑤ Navigate
      │
      ▼
┌─────────────────────────┐
│  HomeScreen             │
│  (Đăng nhập thành công) │
└─────────────────────────┘
```

---

## 📥 LUỒNG 2: TẢI DỮ LIỆU (ONLINE)

```
┌────────────┐
│  USER      │
└─────┬──────┘
      │ Nhấn "Tải dữ liệu"
      ▼
┌──────────────────────────────┐
│  DownloadDataScreen          │
└──────────┬───────────────────┘
           │
           │ ① Check network
           │
      ┌────▼────┐
      │ Online? │
      └────┬────┘
           │ Yes
           │ ② API Call
           ▼
┌────────────────────────────────────┐
│  Backend API                       │
│  GET /api/download/customers       │
│                                    │
│  Response: {                       │
│    customers: [...],               │
│    debts: [...],                   │
│    history: [...]                  │
│  }                                 │
└────────────┬───────────────────────┘
             │
             │ ③ Return JSON data
             │
             ▼
┌────────────────────────────────────┐
│  Flutter App                       │
│  - Parse JSON                      │
│  - Convert to Models               │
└────────────┬───────────────────────┘
             │
             │ ④ Save to local DB
             │
             ▼
┌────────────────────────────────────┐
│  SQLite Database                   │
│                                    │
│  DELETE FROM customers;            │
│  INSERT INTO customers VALUES(...);│
│  INSERT INTO debts VALUES(...);    │
└────────────┬───────────────────────┘
             │
             │ ⑤ Success
             │
             ▼
┌────────────────────────────────────┐
│  UI: "Đã tải 50 khách hàng"       │
│  Sẵn sàng làm việc OFFLINE         │
└────────────────────────────────────┘
```

---

## 📝 LUỒNG 3: GHI CHỈ SỐ (OFFLINE)

```
┌────────────┐
│  USER      │
└─────┬──────┘
      │ ① Chọn khách hàng
      ▼
┌──────────────────────────────┐
│  CustomerListScreen          │
│  - Load from SQLite          │
│  - Show list                 │
└──────────┬───────────────────┘
           │ ② Select customer
           ▼
┌──────────────────────────────┐
│  AddReadingScreen            │
│  - Show old reading          │
│  - Input new reading         │
└──────────┬───────────────────┘
           │
           │ ③ Open camera
           ▼
┌──────────────────────────────┐
│  CameraScreen                │
│  - Take photo                │
│  - Save to local storage     │
└──────────┬───────────────────┘
           │
           │ ④ Return image path
           │   /storage/.../KH001_xxx.jpg
           ▼
┌──────────────────────────────┐
│  AddReadingScreen            │
│  - Calculate consumption     │
│  - Calculate amount          │
│  - Show payment summary      │
└──────────┬───────────────────┘
           │
           │ ⑤ User confirm
           ▼
┌──────────────────────────────────────┐
│  DatabaseHelper (SQLite)             │
│                                      │
│  BEGIN TRANSACTION;                  │
│                                      │
│  INSERT INTO meter_readings (        │
│    customerId, oldReading,           │
│    newReading, consumption,          │
│    imagePath, amount,                │
│    isSynced <- 0  ❌ Chưa sync       │
│  ) VALUES (...);                     │
│                                      │
│  IF payment collected:               │
│    INSERT INTO payments (            │
│      customerId, amountPaid,         │
│      isSynced <- 0  ❌ Chưa sync     │
│    ) VALUES (...);                   │
│                                      │
│    UPDATE debts                      │
│    SET status = 'paid'...            │
│                                      │
│  COMMIT;                             │
└──────────┬───────────────────────────┘
           │
           │ ⑥ Success
           ▼
┌──────────────────────────────┐
│  UI: "Đã lưu thành công"    │
│  Badge: "15 bản ghi chưa sync"│
└──────────────────────────────┘
```

---

## 🔄 LUỒNG 4: ĐỒNG BỘ DỮ LIỆU (ONLINE)

```
┌────────────┐
│  USER      │
└─────┬──────┘
      │ Nhấn "Đồng bộ"
      ▼
┌──────────────────────────────┐
│  SyncScreen                  │
└──────────┬───────────────────┘
           │
           │ ① Check network
           │
      ┌────▼────┐
      │ Online? │
      └────┬────┘
           │ Yes
           │ ② Get unsynced records
           ▼
┌────────────────────────────────────┐
│  SQLite                            │
│  SELECT * FROM meter_readings      │
│  WHERE isSynced = 0                │
│                                    │
│  Result: 15 readings               │
└────────────┬───────────────────────┘
             │
             │ ③ Loop each record
             │
┌────────────▼───────────────────────┐
│  FOR EACH reading:                 │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ ④ Upload image first         │ │
│  │                              │ │
│  │ POST /api/sync/upload-image  │ │
│  │ Body: {                      │ │
│  │   image: <binary>            │ │
│  │ }                            │ │
│  │                              │ │
│  │ Response: {                  │ │
│  │   imageUrl: "https://..."    │ │
│  │ }                            │ │
│  └──────────┬───────────────────┘ │
│             │                      │
│  ┌──────────▼───────────────────┐ │
│  │ ⑤ Upload reading data        │ │
│  │                              │ │
│  │ POST /api/sync/reading       │ │
│  │ Body: {                      │ │
│  │   customerCode: "KH001",     │ │
│  │   oldReading: 100.5,         │ │
│  │   newReading: 125.3,         │ │
│  │   imageUrl: "https://...",   │ │
│  │   ...                        │ │
│  │ }                            │ │
│  │                              │ │
│  │ Response: {                  │ │
│  │   success: true,             │ │
│  │   id: 123                    │ │
│  │ }                            │ │
│  └──────────┬───────────────────┘ │
│             │                      │
│  ┌──────────▼───────────────────┐ │
│  │ ⑥ Update local DB            │ │
│  │                              │ │
│  │ UPDATE meter_readings        │ │
│  │ SET isSynced = 1,   ✅ Synced│ │
│  │     serverId = 123           │ │
│  │ WHERE id = ?                 │ │
│  │                              │ │
│  │ DELETE image file (optional) │ │
│  └──────────────────────────────┘ │
│                                    │
│  REPEAT for 14 remaining records   │
└────────────┬───────────────────────┘
             │
             │ ⑦ All done
             ▼
┌────────────────────────────────────┐
│  UI: "Đã đồng bộ 15/15 bản ghi"  │
│  Badge: "0 bản ghi chưa sync"     │
└────────────────────────────────────┘
```

---

## 💾 DỮ LIỆU LƯU Ở ĐÂU?

### 📱 Trên điện thoại (Local)

```
ANDROID:
/data/data/com.example.water_meter_app/
├── databases/
│   └── water_meter_app.db         ← SQLite database
└── files/
    └── images/
        ├── KH001_20260519.jpg     ← Ảnh chụp đồng hồ
        └── KH002_20260519.jpg

iOS:
<Application Directory>/
├── Documents/
│   ├── water_meter_app.db         ← SQLite database
│   └── images/
│       ├── KH001_20260519.jpg
│       └── KH002_20260519.jpg
```

**Dung lượng:**
- Database: ~10-50 MB
- Images: ~100-500 MB
- **Tổng:** ~110-550 MB

### ☁️ Trên server (Cloud)

```
BACKEND SERVER:
- API code: Railway / Heroku / AWS EC2
- Database: PostgreSQL trên cloud
- Storage size: ~5-10 GB (cho 1000 users)

IMAGE STORAGE:
- AWS S3 / Cloudinary / Firebase Storage
- Structure: /readings/YYYY/MM/KH001_xxx.jpg
- Storage size: ~100 GB/năm (ước tính)
```

**Địa chỉ ví dụ:**
```
API: https://water-meter-api.railway.app
DB:  postgresql://user:pass@host:5432/water_meter
Images: https://storage.cloudinary.com/water-meter/...
```

---

## 📊 LUỒNG BACKUP & RESTORE

```
┌─────────────────────────────────────────┐
│  BACKUP LOCAL DATA                      │
└─────────────────────────────────────────┘

Option 1: Auto backup khi sync
- Mỗi lần sync thành công
- Copy database file → backup/
- Giữ 7 bản backup gần nhất

Option 2: Manual backup
- User nhấn "Backup"
- Export database → external storage
- File: water_meter_backup_20260519.db

Option 3: Cloud backup
- Auto upload database lên Google Drive
- Mỗi ngày 1 lần (khi có mạng)
```

---

## 🔐 BẢO MẬT DỮ LIỆU

### Local Database
```
✅ SQLite file nằm trong app sandbox
✅ Android: /data/data/... (yêu cầu root để access)
✅ iOS: Encrypted by iOS security
❌ Không mã hóa database (có thể thêm SQLCipher)
```

### Network Transfer
```
✅ HTTPS cho mọi API call
✅ JWT Token authentication
✅ Token expire sau 24h
❌ Password hash trên server (bcrypt)
```

### Images
```
✅ Lưu local trong app sandbox
✅ Upload lên cloud có access control
❌ Không có watermark (có thể thêm)
```

---

**Tóm tắt:**
- **Local:** SQLite + Images trên điện thoại (OFFLINE)
- **Server:** PostgreSQL + S3 trên cloud (ONLINE)
- **Sync:** 2-way sync khi có mạng
- **Backup:** Auto/Manual backup database
