# 🏗️ BACKEND & DATA ARCHITECTURE - Water Meter App

## 📋 Tổng quan kiến trúc

Dự án này sử dụng kiến trúc **OFFLINE-FIRST** với 3 tầng:
1. **Mobile App (Flutter)** - Ứng dụng di động
2. **Local Database (SQLite)** - Database trên điện thoại
3. **Backend Server (API)** - Server trung tâm

```
┌────────────────────────────────────────────────────────────────┐
│                    KIẾN TRÚC TỔNG QUAN                         │
└────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│  MOBILE APP     │ ← Nhân viên sử dụng
│  (Flutter)      │
└────────┬────────┘
         │
         │ ↕ Read/Write (OFFLINE)
         │
┌────────▼────────┐
│  LOCAL DB       │ ← Lưu trên điện thoại
│  (SQLite)       │   (Hoạt động không cần mạng)
└────────┬────────┘
         │
         │ ↕ Sync (ONLINE - khi có mạng)
         │
┌────────▼────────┐
│  BACKEND API    │ ← Server trung tâm
│  (REST API)     │
└────────┬────────┘
         │
         │ ↕ CRUD
         │
┌────────▼────────┐
│  SERVER DB      │ ← Database chính
│  (PostgreSQL/   │   (Lưu tất cả dữ liệu)
│   MySQL)        │
└─────────────────┘
```

---

## 📱 1. LOCAL DATABASE (SQLite trên điện thoại)

### 📍 Vị trí lưu trữ

**Android:**
```
/data/data/com.example.water_meter_app/databases/water_meter_app.db
```

**iOS:**
```
<Application Directory>/Documents/water_meter_app.db
```

### 🗄️ Database Schema

```sql
-- ============================================
-- BẢNG 1: users (Nhân viên)
-- ============================================
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  fullName TEXT NOT NULL,
  role TEXT DEFAULT 'staff',
  phoneNumber TEXT,
  email TEXT,
  staffCode TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT
);

-- ============================================
-- BẢNG 2: customers (Khách hàng)
-- ============================================
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  serverId INTEGER,                    -- ID từ server (để sync)
  customerCode TEXT UNIQUE NOT NULL,
  customerName TEXT NOT NULL,
  address TEXT NOT NULL,
  phoneNumber TEXT,
  areaId INTEGER,                      -- Khu vực
  areaName TEXT,
  lastReading REAL,                    -- Chỉ số lần trước
  lastReadingDate TEXT,
  pricePerUnit REAL DEFAULT 15000,
  status TEXT DEFAULT 'active',        -- active, inactive
  createdAt TEXT NOT NULL,
  updatedAt TEXT
);

-- Index để search nhanh
CREATE INDEX idx_customer_code ON customers(customerCode);
CREATE INDEX idx_customer_area ON customers(areaId);

-- ============================================
-- BẢNG 3: meter_readings (Ghi chỉ số)
-- ============================================
CREATE TABLE meter_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  serverId INTEGER,                    -- ID từ server (sau khi sync)
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  customerName TEXT NOT NULL,
  
  oldReading REAL NOT NULL,
  newReading REAL NOT NULL,
  consumption REAL NOT NULL,           -- Tiêu thụ = new - old
  
  imagePath TEXT,                      -- Đường dẫn ảnh local
  imageUrl TEXT,                       -- URL ảnh trên server (sau sync)
  
  readingDate TEXT NOT NULL,
  month TEXT NOT NULL,                 -- YYYY-MM
  
  collectorId INTEGER NOT NULL,        -- ID nhân viên ghi
  collectorName TEXT NOT NULL,
  
  amount REAL NOT NULL,                -- Tiền tháng này
  notes TEXT,
  
  isSynced INTEGER DEFAULT 0,          -- 0: chưa sync, 1: đã sync
  syncedAt TEXT,
  
  createdAt TEXT NOT NULL,
  
  FOREIGN KEY (customerId) REFERENCES customers(id)
);

CREATE INDEX idx_reading_synced ON meter_readings(isSynced);
CREATE INDEX idx_reading_customer ON meter_readings(customerId);
CREATE INDEX idx_reading_month ON meter_readings(month);

-- ============================================
-- BẢNG 4: debts (Công nợ)
-- ============================================
CREATE TABLE debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  serverId INTEGER,
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  
  month TEXT NOT NULL,                 -- Tháng nợ (YYYY-MM)
  amount REAL NOT NULL,                -- Số tiền nợ
  consumption REAL,                    -- Tiêu thụ tháng đó
  
  status TEXT DEFAULT 'unpaid',        -- unpaid, partial, paid
  paidAmount REAL DEFAULT 0,           -- Số tiền đã trả
  remainingAmount REAL,                -- Số tiền còn nợ
  
  isSynced INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT,
  
  FOREIGN KEY (customerId) REFERENCES customers(id)
);

CREATE INDEX idx_debt_customer ON debts(customerId);
CREATE INDEX idx_debt_status ON debts(status);

-- ============================================
-- BẢNG 5: payments (Thu tiền)
-- ============================================
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  serverId INTEGER,
  customerId INTEGER NOT NULL,
  customerCode TEXT NOT NULL,
  
  readingId INTEGER,                   -- Link đến meter_readings
  month TEXT NOT NULL,                 -- Tháng thu (YYYY-MM)
  
  currentMonthAmount REAL NOT NULL,    -- Tiền tháng hiện tại
  debtAmount REAL DEFAULT 0,           -- Tổng tiền nợ
  totalAmount REAL NOT NULL,           -- Tổng phải thu
  amountPaid REAL NOT NULL,            -- Số tiền đã thu
  remainingDebt REAL DEFAULT 0,        -- Còn nợ sau khi thu
  
  paymentDate TEXT NOT NULL,
  paymentMethod TEXT DEFAULT 'cash',   -- cash, transfer
  
  collectorId INTEGER NOT NULL,
  collectorName TEXT NOT NULL,
  
  notes TEXT,
  receiptNumber TEXT,                  -- Số biên lai
  
  isSynced INTEGER DEFAULT 0,
  syncedAt TEXT,
  
  createdAt TEXT NOT NULL,
  
  FOREIGN KEY (customerId) REFERENCES customers(id),
  FOREIGN KEY (readingId) REFERENCES meter_readings(id)
);

CREATE INDEX idx_payment_synced ON payments(isSynced);
CREATE INDEX idx_payment_customer ON payments(customerId);
CREATE INDEX idx_payment_date ON payments(paymentDate);

-- ============================================
-- BẢNG 6: sync_log (Log đồng bộ)
-- ============================================
CREATE TABLE sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recordType TEXT NOT NULL,            -- reading, payment, debt, customer
  recordId INTEGER NOT NULL,           -- ID của bản ghi
  
  syncStatus TEXT NOT NULL,            -- pending, success, failed
  errorMessage TEXT,
  
  syncDate TEXT NOT NULL,
  retryCount INTEGER DEFAULT 0
);

CREATE INDEX idx_sync_status ON sync_log(syncStatus);

-- ============================================
-- BẢNG 7: app_settings (Cấu hình app)
-- ============================================
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

-- Insert default settings
INSERT INTO app_settings (key, value, updatedAt) VALUES
  ('lastSyncDate', '', datetime('now')),
  ('autoSyncEnabled', '1', datetime('now')),
  ('serverUrl', 'https://api.watermeter.com', datetime('now')),
  ('currentUserId', '', datetime('now'));
```

### 📊 Dung lượng ước tính

| Loại data | Kích thước | Số lượng | Tổng |
|-----------|------------|----------|------|
| 1 Customer | ~500 bytes | 100 | ~50 KB |
| 1 Reading | ~800 bytes | 500 | ~400 KB |
| 1 Image | ~200 KB | 500 | ~100 MB |
| **TỔNG** | | | **~100 MB** |

**Lưu ý:** Ảnh là phần chiếm nhiều dung lượng nhất.

---

## 🌐 2. BACKEND SERVER (API)

### 🔧 Công nghệ đề xuất

#### Option 1: Node.js + Express (Đơn giản, phổ biến)
```javascript
// Backend structure
backend/
├── src/
│   ├── controllers/      // Business logic
│   ├── models/          // Database models
│   ├── routes/          // API routes
│   ├── middleware/      // Auth, validation
│   ├── services/        // Services (upload, sync)
│   └── config/          // Config (DB, env)
├── uploads/             // Ảnh đồng hồ
├── .env                 // Environment variables
├── package.json
└── server.js
```

**Dependencies:**
- `express` - Web framework
- `pg` / `mysql2` - Database driver
- `multer` - File upload
- `jsonwebtoken` - Authentication
- `bcrypt` - Password hashing
- `cors` - CORS handling

#### Option 2: Python + Django/FastAPI
```python
# Backend structure
backend/
├── api/
│   ├── views.py         # API endpoints
│   ├── models.py        # Database models
│   ├── serializers.py   # Data serialization
│   └── urls.py          # Routes
├── uploads/
├── requirements.txt
└── manage.py
```

#### Option 3: Java Spring Boot (Enterprise)
```java
backend/
├── src/main/java/com/watermeter/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── model/
│   └── config/
└── pom.xml
```

### 📍 Nơi deploy backend

#### Option 1: Cloud Hosting (Đề xuất)
- **AWS** (Amazon Web Services)
  - EC2: Server
  - RDS: Database
  - S3: Lưu ảnh
  
- **Google Cloud Platform**
  - Compute Engine: Server
  - Cloud SQL: Database
  - Cloud Storage: Ảnh

- **Azure**
  - App Service
  - Azure Database
  - Blob Storage

#### Option 2: VPS (Giá rẻ)
- **DigitalOcean** (~$5/month)
- **Vultr**
- **Linode**

#### Option 3: Free Tier (Học tập/Demo)
- **Heroku** (Free tier)
- **Railway.app**
- **Render.com**
- **Vercel** (cho API)

---

## 🗄️ 3. SERVER DATABASE

### Đề xuất: PostgreSQL (Mạnh mẽ, mở nguồn)

**Vị trí:** Trên cloud (AWS RDS, Google Cloud SQL, DigitalOcean Managed DB)

### Database Schema (giống với local, có thêm fields)

```sql
-- ============================================
-- BẢNG: staff (Nhân viên - trên server)
-- ============================================
CREATE TABLE staff (
  id SERIAL PRIMARY KEY,
  staff_code VARCHAR(20) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(15),
  email VARCHAR(100),
  role VARCHAR(20) DEFAULT 'staff',
  area_id INTEGER,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- BẢNG: areas (Khu vực)
-- ============================================
CREATE TABLE areas (
  id SERIAL PRIMARY KEY,
  area_code VARCHAR(20) UNIQUE NOT NULL,
  area_name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- BẢNG: customers (Khách hàng)
-- ============================================
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  customer_code VARCHAR(20) UNIQUE NOT NULL,
  customer_name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  phone_number VARCHAR(15),
  area_id INTEGER REFERENCES areas(id),
  price_per_unit DECIMAL(10,2) DEFAULT 15000,
  last_reading DECIMAL(10,2),
  last_reading_date DATE,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- BẢNG: meter_readings (Ghi chỉ số)
-- ============================================
CREATE TABLE meter_readings (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  customer_code VARCHAR(20) NOT NULL,
  
  old_reading DECIMAL(10,2) NOT NULL,
  new_reading DECIMAL(10,2) NOT NULL,
  consumption DECIMAL(10,2) NOT NULL,
  
  image_url TEXT,
  
  reading_date TIMESTAMP NOT NULL,
  month VARCHAR(7) NOT NULL,
  
  collector_id INTEGER REFERENCES staff(id),
  
  amount DECIMAL(10,2) NOT NULL,
  notes TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  synced_at TIMESTAMP
);

-- ============================================
-- BẢNG: debts (Công nợ)
-- ============================================
CREATE TABLE debts (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  
  month VARCHAR(7) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  consumption DECIMAL(10,2),
  
  status VARCHAR(20) DEFAULT 'unpaid',
  paid_amount DECIMAL(10,2) DEFAULT 0,
  remaining_amount DECIMAL(10,2),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- BẢNG: payments (Thu tiền)
-- ============================================
CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  reading_id INTEGER REFERENCES meter_readings(id),
  
  month VARCHAR(7) NOT NULL,
  
  current_month_amount DECIMAL(10,2) NOT NULL,
  debt_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL,
  remaining_debt DECIMAL(10,2) DEFAULT 0,
  
  payment_date TIMESTAMP NOT NULL,
  payment_method VARCHAR(20) DEFAULT 'cash',
  
  collector_id INTEGER REFERENCES staff(id),
  
  notes TEXT,
  receipt_number VARCHAR(50),
  
  created_at TIMESTAMP DEFAULT NOW(),
  synced_at TIMESTAMP
);
```

---

## 🔄 4. API ENDPOINTS

### Authentication

```
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh-token
GET    /api/auth/me
```

### Staff Management

```
GET    /api/staff
GET    /api/staff/:id
POST   /api/staff
PUT    /api/staff/:id
DELETE /api/staff/:id
```

### Data Download (ONLINE - trước khi đi thu)

```
GET    /api/download/customers?staffId=1
GET    /api/download/assigned-customers/:staffId
GET    /api/download/debts?customerId=1
GET    /api/download/history?customerId=1
```

**Response example:**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 1,
        "customerCode": "KH001",
        "customerName": "Nguyễn Văn A",
        "address": "123 ABC",
        "phoneNumber": "0901234567",
        "lastReading": 100.5,
        "lastReadingDate": "2026-04-25",
        "pricePerUnit": 15000,
        "debt": {
          "totalDebt": 450000,
          "debtMonths": 3,
          "debtDetails": [...]
        }
      }
    ]
  }
}
```

### Image Upload

```
POST   /api/upload/image
```

**Request:**
```
Content-Type: multipart/form-data

file: <binary>
customerCode: KH001
type: meter_reading
```

**Response:**
```json
{
  "success": true,
  "imageUrl": "https://storage.example.com/images/abc123.jpg"
}
```

### Sync Data (ONLINE - sau khi ghi số)

```
POST   /api/sync/readings
POST   /api/sync/payments
POST   /api/sync/bulk
```

**Request:**
```json
{
  "readings": [
    {
      "customerCode": "KH001",
      "oldReading": 100.5,
      "newReading": 125.3,
      "consumption": 24.8,
      "imageUrl": "https://...",
      "readingDate": "2026-05-19T10:30:45Z",
      "amount": 372000,
      "collectorId": 1
    }
  ],
  "payments": [
    {
      "customerCode": "KH001",
      "month": "2026-05",
      "totalAmount": 822000,
      "amountPaid": 500000,
      "remainingDebt": 322000,
      "paymentDate": "2026-05-19T10:30:45Z"
    }
  ]
}
```

### Customers

```
GET    /api/customers
GET    /api/customers/:id
POST   /api/customers
PUT    /api/customers/:id
DELETE /api/customers/:id
```

### Meter Readings

```
GET    /api/readings
GET    /api/readings/:id
GET    /api/readings/customer/:customerId
POST   /api/readings
```

### Payments

```
GET    /api/payments
GET    /api/payments/:id
GET    /api/payments/customer/:customerId
POST   /api/payments
```

### Reports

```
GET    /api/reports/daily?date=2026-05-19
GET    /api/reports/monthly?month=2026-05
GET    /api/reports/staff/:staffId
GET    /api/reports/debts
```

---

## 📂 5. IMAGE STORAGE

### Option 1: Cloud Storage (Đề xuất)

**AWS S3:**
```
Bucket: water-meter-images
Structure:
├── readings/
│   ├── 2026/
│   │   ├── 05/
│   │   │   ├── KH001_20260519_103045.jpg
│   │   │   └── KH002_20260519_110000.jpg
```

**URL format:**
```
https://water-meter-images.s3.amazonaws.com/readings/2026/05/KH001_20260519_103045.jpg
```

**Cost:** ~$0.023/GB/month

### Option 2: Server Storage

```
/var/www/water-meter/uploads/
├── readings/
│   ├── 2026-05/
│   │   ├── KH001_20260519_103045.jpg
```

**URL format:**
```
https://api.watermeter.com/uploads/readings/2026-05/KH001_20260519_103045.jpg
```

### Local Storage (trên điện thoại)

**Android:**
```
/storage/emulated/0/Android/data/com.example.water_meter_app/files/images/
├── KH001_20260519_103045.jpg
```

**iOS:**
```
<Application Directory>/Documents/images/
├── KH001_20260519_103045.jpg
```

---

## 🔐 6. AUTHENTICATION & SECURITY

### JWT Token Authentication

```
Login flow:
1. User login with username/password
2. Server verify credentials
3. Server generate JWT token
4. App store token in secure storage
5. App send token in every API request

Header: Authorization: Bearer <token>
```

### Token Structure

```json
{
  "userId": 1,
  "username": "staff01",
  "role": "staff",
  "exp": 1685534400
}
```

### Security Best Practices

1. **Password:** Hash với bcrypt (server)
2. **HTTPS:** Bắt buộc cho mọi API call
3. **Token:** Expire sau 24h, có refresh token
4. **API Rate Limiting:** Chống spam
5. **Input Validation:** Validate mọi input
6. **SQL Injection:** Dùng prepared statements

---

## 🔄 7. SYNC MECHANISM

### Sync Strategy

```
┌────────────────────────────────────────────────────┐
│              CHIẾN LƯỢC ĐỒNG BỘ                    │
└────────────────────────────────────────────────────┘

1. DOWNLOAD (ONLINE - trước khi đi thu)
   ├─ Tải danh sách khách hàng được phân công
   ├─ Tải công nợ
   ├─ Tải lịch sử
   └─ Lưu vào SQLite local

2. WORK OFFLINE (Không cần mạng)
   ├─ Ghi chỉ số
   ├─ Chụp ảnh
   ├─ Thu tiền
   └─ Lưu local (isSynced = 0)

3. SYNC (ONLINE - khi có mạng)
   ├─ Lấy tất cả records có isSynced = 0
   ├─ Upload từng record
   │  ├─ Upload ảnh trước
   │  └─ Upload data với imageUrl
   ├─ Server trả về ID
   ├─ Update serverId + isSynced = 1
   └─ Xóa ảnh local (optional)
```

### Conflict Resolution

**Trường hợp:** 2 nhân viên ghi cùng 1 khách hàng trong cùng tháng

**Giải pháp:**
```
Rule: Last Write Wins (LWW)
- So sánh timestamp
- Giữ bản ghi có timestamp mới nhất
- Notify user về conflict
```

### Retry Logic

```javascript
// Pseudo code
async function syncRecord(record) {
  const maxRetries = 3;
  let attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      await api.sync(record);
      return { success: true };
    } catch (error) {
      attempt++;
      if (attempt < maxRetries) {
        await wait(2 ** attempt * 1000); // Exponential backoff
      }
    }
  }
  
  return { success: false, error: 'Max retries exceeded' };
}
```

---

## 💰 8. CHI PHÍ ƯỚC TÍNH

### Hosting (Monthly)

| Service | Provider | Cost |
|---------|----------|------|
| Server (1 CPU, 1GB RAM) | DigitalOcean | $6 |
| Database (PostgreSQL) | DigitalOcean | $15 |
| Storage (50GB) | AWS S3 | $1.15 |
| Bandwidth (100GB) | - | $0 (included) |
| Domain | Namecheap | $1 |
| **TỔNG** | | **~$23/month** |

### Free Tier (Học tập/Demo)

| Service | Provider | Limit |
|---------|----------|-------|
| Server | Heroku/Railway | 500 hours/month |
| Database | Heroku Postgres | 10K rows |
| Storage | Cloudinary | 25GB bandwidth |
| **TỔNG** | | **$0** |

---

## 📝 9. IMPLEMENTATION PLAN

### Phase 1: Setup Backend (1-2 tuần)

- [ ] Setup Node.js/Express server
- [ ] Setup PostgreSQL database
- [ ] Create database tables
- [ ] Implement authentication
- [ ] Deploy to server

### Phase 2: API Development (2-3 tuần)

- [ ] CRUD APIs cho customers
- [ ] CRUD APIs cho readings
- [ ] CRUD APIs cho payments
- [ ] Upload image API
- [ ] Sync API
- [ ] Download data API

### Phase 3: Integration (1-2 tuần)

- [ ] Connect Flutter app với API
- [ ] Implement sync service
- [ ] Test sync mechanism
- [ ] Handle errors & edge cases

### Phase 4: Testing & Optimization (1 tuần)

- [ ] Load testing
- [ ] Security testing
- [ ] Performance optimization
- [ ] Bug fixes

---

## 🛠️ 10. DEVELOPMENT TOOLS

### Backend Development

- **Postman** - Test API
- **pgAdmin** - Manage PostgreSQL
- **Docker** - Containerization
- **Git** - Version control

### Monitoring

- **PM2** - Process manager (Node.js)
- **Sentry** - Error tracking
- **Google Analytics** - Usage analytics

---

**Tóm tắt:**
- **Local DB:** SQLite trên điện thoại (OFFLINE)
- **Backend:** Node.js/Express API trên cloud (ONLINE)
- **Server DB:** PostgreSQL trên cloud
- **Images:** AWS S3 / Cloud Storage
- **Cost:** ~$23/month (hoặc FREE cho demo)
