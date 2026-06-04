# 📋 TÓM TẮT BACKEND - Water Meter App

## ❓ CÂU HỎI & TRẢ LỜI

### 1. **Backend của dự án này sẽ xử lý như thế nào?**

Backend sử dụng kiến trúc **OFFLINE-FIRST**:

```
Mobile App (Flutter)
    ↕ OFFLINE (không cần mạng)
Local Database (SQLite)
    ↕ ONLINE (khi có mạng)
Backend API (REST)
    ↕
Server Database (PostgreSQL)
```

**Xử lý:**
1. **OFFLINE:** App hoạt động hoàn toàn với SQLite local
2. **ONLINE:** Sync dữ liệu lên server khi có mạng
3. **Backend API:** Nhận data từ app, lưu vào database chính

---

### 2. **Dữ liệu lưu ở đâu?**

#### 📱 **TRÊN ĐIỆN THOẠI (Local - OFFLINE)**

**Vị trí:**
- **Android:** `/data/data/com.example.water_meter_app/databases/water_meter_app.db`
- **iOS:** `<App Directory>/Documents/water_meter_app.db`

**Lưu gì:**
```
SQLite Database:
├── users (nhân viên)
├── customers (khách hàng)
├── meter_readings (chỉ số đồng hồ)
├── payments (thu tiền)
└── debts (công nợ)

Images:
└── /storage/.../images/
    ├── KH001_20260519.jpg
    └── KH002_20260519.jpg
```

**Kích thước:**
- Database: ~10-50 MB
- Images: ~100-500 MB
- **Tổng:** ~110-550 MB

**Lý do:**
- ✅ Hoạt động không cần mạng
- ✅ Nhanh
- ✅ Không tốn data 4G

---

#### ☁️ **TRÊN SERVER (Cloud - ONLINE)**

**Backend API:**
- **Deploy ở:** Railway.app / Heroku / AWS (miễn phí hoặc ~$5-10/tháng)
- **URL ví dụ:** `https://water-meter-api.railway.app`

**Server Database:**
- **Loại:** PostgreSQL / MySQL
- **Deploy ở:** Railway / AWS RDS / DigitalOcean
- **Kích thước:** ~5-10 GB (cho 1000 users)

**Lưu gì:**
```
PostgreSQL Database:
├── staff (nhân viên)
├── customers (khách hàng)
├── meter_readings (chỉ số đồng hồ)
├── payments (thu tiền)
├── debts (công nợ)
└── areas (khu vực)
```

**Images:**
- **Lưu ở:** AWS S3 / Cloudinary / Firebase Storage
- **URL ví dụ:** `https://storage.cloudinary.com/water-meter/readings/KH001.jpg`
- **Kích thước:** ~100 GB/năm

**Lý do:**
- ✅ Dữ liệu tập trung
- ✅ Backup an toàn
- ✅ Nhiều user có thể truy cập
- ✅ Báo cáo tổng hợp

---

## 🔄 LUỒNG DỮ LIỆU

### 1️⃣ **Download Data (ONLINE)**
```
Server DB → API → App → SQLite Local
```

**Chi tiết:**
1. Nhân viên mở app, nhấn "Tải dữ liệu"
2. App gọi API: `GET /api/download/customers`
3. Server trả về JSON: danh sách KH + công nợ
4. App parse JSON → lưu vào SQLite
5. Sẵn sàng làm việc OFFLINE

---

### 2️⃣ **Work Offline (OFFLINE)**
```
User → App UI → SQLite Local
```

**Chi tiết:**
1. Nhân viên ghi chỉ số, chụp ảnh
2. App lưu vào SQLite (isSynced = 0)
3. Ảnh lưu trong thư mục local
4. Không cần mạng

---

### 3️⃣ **Sync Data (ONLINE)**
```
SQLite Local → App → API → Server DB
```

**Chi tiết:**
1. Nhân viên nhấn "Đồng bộ" (hoặc auto khi có mạng)
2. App lấy tất cả records có isSynced = 0
3. Upload từng record:
   - Upload ảnh lên S3/Cloudinary
   - Upload data + imageUrl lên API
4. Server lưu vào PostgreSQL
5. App update isSynced = 1
6. Xóa ảnh local (optional)

---

## 🛠️ CÔNG NGHỆ

### Mobile App
- **Framework:** Flutter + Dart
- **Database:** SQLite (sqflite package)
- **State:** Provider
- **Network:** http package

### Backend
- **Option 1:** Node.js + Express (đề xuất)
- **Option 2:** Python + Django/FastAPI
- **Option 3:** Java Spring Boot

### Database
- **Local:** SQLite
- **Server:** PostgreSQL (đề xuất) / MySQL

### Storage
- **Local:** App sandbox
- **Cloud:** AWS S3 / Cloudinary

### Hosting
- **Free:** Railway.app / Heroku / Render
- **Paid:** AWS / DigitalOcean (~$10-20/month)

---

## 💰 CHI PHÍ

### FREE (cho học tập/demo)
```
✅ Backend: Railway.app (500 hours/month)
✅ Database: Railway PostgreSQL (giới hạn)
✅ Images: Cloudinary (25GB/month)
✅ TỔNG: $0
```

### PAID (production)
```
• Server: DigitalOcean VPS        $6/month
• Database: Managed PostgreSQL     $15/month
• Storage: AWS S3                  $1-5/month
• Domain: .com                     $12/year
────────────────────────────────────────────
TỔNG:                             ~$23/month
```

---

## 📚 TÀI LIỆU CHI TIẾT

Đã tạo các tài liệu sau:

### 1. **[`BACKEND_ARCHITECTURE.md`](BACKEND_ARCHITECTURE.md)**
- Kiến trúc tổng quan chi tiết
- Database schema đầy đủ (SQLite + PostgreSQL)
- API endpoints specification
- Image storage strategy
- Sync mechanism
- Security best practices
- ~200+ dòng documentation

### 2. **[`BACKEND_SETUP_GUIDE.md`](BACKEND_SETUP_GUIDE.md)**
- Hướng dẫn setup backend từng bước
- Code backend mẫu (Node.js + Express)
- 3 options: Backend đơn giản / Deploy Railway / MockAPI
- Test với Postman
- ~300+ dòng code + hướng dẫn

### 3. **[`DATA_FLOW_DIAGRAM.md`](DATA_FLOW_DIAGRAM.md)**
- Sơ đồ luồng dữ liệu chi tiết
- 4 luồng chính: Login / Download / Work Offline / Sync
- ASCII diagrams
- Giải thích dữ liệu lưu ở đâu

---

## 🎯 KHUYẾN NGHỊ

### Cho môn học PRM393:

**Setup đơn giản:**
```
1. Mobile App: Flutter (đã có)
2. Local DB: SQLite (đã có)
3. Backend: Node.js + Express
4. Deploy: Railway.app (FREE)
5. Images: Cloudinary (FREE)
```

**Lý do:**
- ✅ Miễn phí hoàn toàn
- ✅ Setup nhanh (~2-3 giờ)
- ✅ Đủ tính năng để demo
- ✅ Dễ code, dễ maintain

**Không cần:**
- ❌ AWS (phức tạp, tốn tiền)
- ❌ Kubernetes (overkill)
- ❌ Microservices (không cần thiết)

---

## 📖 ĐỌC TIẾP

1. **Muốn hiểu chi tiết:**
   - Đọc [`BACKEND_ARCHITECTURE.md`](BACKEND_ARCHITECTURE.md)

2. **Muốn code backend:**
   - Đọc [`BACKEND_SETUP_GUIDE.md`](BACKEND_SETUP_GUIDE.md)
   - Copy code mẫu
   - Deploy lên Railway

3. **Muốn hiểu luồng data:**
   - Đọc [`DATA_FLOW_DIAGRAM.md`](DATA_FLOW_DIAGRAM.md)

4. **Muốn tích hợp app với API:**
   - Tạo `lib/services/api_service.dart`
   - Implement HTTP calls
   - Test với Postman trước

---

## ✅ CHECKLIST

### Phase 1: Setup Backend
- [ ] Setup Node.js project
- [ ] Code basic API endpoints
- [ ] Test locally với Postman
- [ ] Deploy lên Railway
- [ ] Test API trên cloud

### Phase 2: Integration
- [ ] Tạo `api_service.dart` trong Flutter
- [ ] Implement download customers
- [ ] Implement upload image
- [ ] Implement sync reading
- [ ] Test end-to-end

### Phase 3: Polish
- [ ] Handle errors
- [ ] Add loading indicators
- [ ] Optimize sync logic
- [ ] Write tests

---

## 🎓 HỌC TẬP

**Thời gian:**
- Đọc tài liệu: 1-2 giờ
- Setup backend: 2-3 giờ
- Integration: 3-4 giờ
- **Tổng:** ~6-9 giờ

**Kiến thức cần:**
- JavaScript cơ bản (cho Node.js)
- REST API concepts
- HTTP methods (GET, POST, PUT, DELETE)
- JSON format

**Kiến thức tốt nếu có:**
- Express.js
- PostgreSQL / SQL
- JWT authentication
- Async/await

---

**Kết luận:**
- ✅ Backend đơn giản với Node.js + Express
- ✅ Data lưu trên SQLite (local) + PostgreSQL (server)
- ✅ Images lưu trên Cloudinary
- ✅ Deploy miễn phí trên Railway
- ✅ Hoàn toàn đủ cho môn học PRM393
