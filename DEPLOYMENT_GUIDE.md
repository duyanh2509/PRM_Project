# 📦 DEPLOYMENT GUIDE - Water Meter App

Hướng dẫn triển khai ứng dụng Water Meter App lên thiết bị Android.

---

## 🎯 YÊU CẦU HỆ THỐNG

### Thiết bị
- **Android:** Phiên bản 5.0 (API 21) trở lên
- **Dung lượng:** Tối thiểu 100MB trống
- **Camera:** Có camera để chụp ảnh đồng hồ
- **Internet:** Cần cho lần đầu tải dữ liệu và đồng bộ

### Backend
- ✅ Firebase project đã được cấu hình
- ✅ Firestore database đã được tạo
- ✅ Firebase Storage đã được bật
- ✅ Dữ liệu đã được seed (36 customers)

---

## 📲 CÁCH 1: CÀI ĐẶT TỪ APK FILE

### Bước 1: Lấy file APK
File APK đã được build sẵn tại:
```
build\app\outputs\flutter-apk\app-release.apk
```
**Kích thước:** 48.6 MB

### Bước 2: Chuyển APK sang thiết bị
Có 3 cách:

**Option A: USB Cable**
1. Kết nối điện thoại với máy tính qua USB
2. Copy file `app-release.apk` vào thư mục Downloads của điện thoại
3. Rút cáp USB

**Option B: Email**
1. Gửi file APK qua email cho chính mình
2. Mở email trên điện thoại
3. Tải về APK file

**Option C: Cloud Storage**
1. Upload APK lên Google Drive / Dropbox
2. Mở link trên điện thoại
3. Tải về APK file

### Bước 3: Cài đặt APK
1. Mở app **Files** hoặc **My Files** trên điện thoại
2. Tìm file `app-release.apk` (thường ở thư mục Downloads)
3. Nhấn vào file để cài đặt
4. Nếu gặp cảnh báo "Install blocked":
   - Vào **Settings** → **Security** → Bật **Unknown sources**
   - Hoặc **Settings** → **Apps** → **Special access** → Bật **Install unknown apps** cho app Files
5. Nhấn **Install**
6. Đợi quá trình cài đặt hoàn tất
7. Nhấn **Open** để mở ứng dụng

---

## 🔧 CÁCH 2: BUILD VÀ CÀI TỪ SOURCE CODE

### Bước 1: Chuẩn bị môi trường
```bash
# Kiểm tra Flutter đã cài đặt
flutter doctor

# Kết nối thiết bị Android (USB hoặc emulator)
flutter devices
```

### Bước 2: Build và cài đặt
```bash
# Di chuyển vào thư mục project
cd water_meter_app

# Cài đặt dependencies
flutter pub get

# Build và cài trực tiếp lên thiết bị
flutter install --release
```

### Bước 3: Kiểm tra
App sẽ tự động được cài đặt và mở trên thiết bị.

---

## 🚀 HƯỚNG DẪN SỬ DỤNG LẦN ĐẦU

### 1. Khởi động app
1. Mở app **Water Meter App** trên điện thoại
2. Đợi màn hình login hiện ra

### 2. Đăng nhập admin
```
Username: admin
Password: admin123
```

**Lưu ý:** Tài khoản admin được tạo tự động khi cài đặt lần đầu.

### 3. Tải dữ liệu từ Firebase
1. Sau khi đăng nhập thành công
2. Vào tab **Settings** (biểu tượng ⚙️)
3. Nhấn nút **"Tải dữ liệu tuyến"**
4. Đợi download hoàn tất (36 customers)
5. Thông báo "Đã tải 36 khách hàng từ máy chủ"

### 4. Kiểm tra dữ liệu
1. Vào tab **Home** - Xem thống kê
2. Vào tab **Customers** - Xem danh sách 36 khách hàng
3. Nhấn vào 1 khách hàng để xem chi tiết

### 5. Test offline mode
1. Tắt WiFi và Mobile Data
2. Thử ghi chỉ số hoặc thu tiền
3. Dữ liệu sẽ được lưu local
4. Bật lại internet
5. Vào Settings → Nhấn **"Đồng bộ lên máy chủ"**

---

## 👥 THÊM NHÂN VIÊN MỚI

### Option 1: Thêm trực tiếp vào Firebase
1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project **Water Meter App**
3. Vào **Firestore Database**
4. Vào collection **staff**
5. Nhấn **Add document**
6. Nhập thông tin:
   ```json
   {
     "username": "staff01",
     "password": "staff123",
     "fullName": "Nguyễn Văn A",
     "role": "staff",
     "areaCode": "Q1",
     "areaName": "Quận 1",
     "createdAt": "2026-06-11T10:00:00Z"
   }
   ```
7. Nhấn **Save**

### Option 2: Thêm vào SQLite trực tiếp (Development only)
Không khuyến khích cho production. Chỉ dùng cho testing.

---

## 🗄️ CẤU TRÚC DỮ LIỆU FIREBASE

### Collection: staff
```json
{
  "username": "admin",
  "password": "admin123",
  "fullName": "Administrator",
  "role": "admin",
  "areaCode": "ALL",
  "areaName": "Tất cả khu vực",
  "createdAt": "2026-06-11T00:00:00Z"
}
```

### Collection: customers
```json
{
  "customerCode": "KH001",
  "customerName": "Nguyễn Văn A",
  "address": "123 Nguyễn Huệ, Q1",
  "phoneNumber": "0901234567",
  "areaCode": "Q1",
  "areaName": "Quận 1",
  "lastReading": 150.5,
  "lastReadingDate": "2026-05-01T00:00:00Z",
  "pricePerUnit": 15000,
  "totalDebt": 225000,
  "debtMonths": 1,
  "lastPaymentDate": "2026-04-15T00:00:00Z",
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2026-05-01T00:00:00Z"
}
```

### Collection: meter_readings
```json
{
  "customerCode": "KH001",
  "recordType": "meter",
  "oldReading": 135.0,
  "newReading": 150.5,
  "amountCollected": null,
  "syncStatus": "synced",
  "recordedAt": "2026-05-01T10:30:00Z",
  "collectorName": "admin",
  "note": "Bình thường",
  "billingMonth": "2026-05",
  "paymentMethod": null,
  "paymentStatus": null,
  "proofImagePath": null,
  "syncedAt": "2026-05-01T10:31:00Z"
}
```

### Collection: payments
```json
{
  "customerCode": "KH001",
  "recordType": "payment",
  "oldReading": null,
  "newReading": null,
  "amountCollected": 225000,
  "syncStatus": "synced",
  "recordedAt": "2026-05-01T11:00:00Z",
  "collectorName": "admin",
  "note": "Thu đủ",
  "billingMonth": "2026-05",
  "paymentMethod": "cash",
  "paymentStatus": "paid",
  "proofImagePath": null,
  "syncedAt": "2026-05-01T11:01:00Z"
}
```

---

## 🔐 PHÂN QUYỀN

### Admin (role: "admin")
- ✅ Xem tất cả khu vực
- ✅ Tải tất cả khách hàng
- ✅ Ghi chỉ số cho bất kỳ khách hàng nào
- ✅ Thu tiền cho bất kỳ khách hàng nào
- ✅ Đồng bộ tất cả dữ liệu

### Staff (role: "staff")
- ✅ Chỉ xem khu vực được gán (theo areaCode)
- ✅ Chỉ tải khách hàng trong khu vực của mình
- ✅ Chỉ ghi chỉ số cho khách hàng trong khu vực
- ✅ Chỉ thu tiền cho khách hàng trong khu vực
- ✅ Chỉ đồng bộ dữ liệu của khu vực mình

---

## 🧪 TESTING CHECKLIST

### Sau khi cài đặt, test các chức năng sau:

#### 1. Authentication
- [ ] Đăng nhập với admin/admin123
- [ ] Đăng xuất
- [ ] Đăng nhập lại

#### 2. Download Data
- [ ] Vào Settings
- [ ] Nhấn "Tải dữ liệu tuyến"
- [ ] Kiểm tra 36 customers được tải về
- [ ] Kiểm tra statistics trên Home screen

#### 3. Customer List
- [ ] Xem danh sách customers
- [ ] Toggle List/Grid view
- [ ] Search customer
- [ ] Nhấn vào customer → xem detail

#### 4. Meter Reading (Offline)
- [ ] Tắt internet
- [ ] Chọn 1 customer
- [ ] Nhấn "Ghi chỉ số"
- [ ] Nhập old reading và new reading
- [ ] Chụp ảnh đồng hồ (optional)
- [ ] Save
- [ ] Kiểm tra pending count tăng lên

#### 5. Payment Collection (Offline)
- [ ] Vẫn tắt internet
- [ ] Chọn 1 customer có nợ
- [ ] Nhấn "Thu tiền"
- [ ] Nhập số tiền
- [ ] Chọn payment method
- [ ] Save
- [ ] Kiểm tra debt giảm

#### 6. Sync (Online)
- [ ] Bật lại internet
- [ ] Vào Settings
- [ ] Nhấn "Đồng bộ lên máy chủ"
- [ ] Kiểm tra pending count = 0
- [ ] Kiểm tra lastSyncAt được update

#### 7. History
- [ ] Vào History tab
- [ ] Toggle giữa "Ghi số" và "Thu tiền"
- [ ] Xem chi tiết các records

---

## ⚠️ TROUBLESHOOTING

### Lỗi: "Install blocked"
**Giải pháp:**
1. Vào **Settings** → **Security**
2. Bật **Unknown sources**
3. Hoặc: **Settings** → **Apps** → **Special access** → **Install unknown apps**
4. Cho phép app Files cài đặt APK

### Lỗi: "App not installed"
**Giải pháp:**
1. Gỡ bỏ phiên bản cũ nếu có
2. Khởi động lại điện thoại
3. Cài lại APK

### Lỗi: "Firebase connection failed"
**Giải pháp:**
1. Kiểm tra internet
2. Kiểm tra file `google-services.json` đã được thêm
3. Rebuild APK: `flutter build apk --release`

### Lỗi: "No customers found"
**Giải pháp:**
1. Đảm bảo đã login
2. Đảm bảo có internet
3. Nhấn "Tải dữ liệu tuyến" trong Settings
4. Đợi download hoàn tất

### Lỗi: "Pending records not syncing"
**Giải pháp:**
1. Kiểm tra internet
2. Vào Settings → Nhấn "Đồng bộ lên máy chủ"
3. Kiểm tra Firebase Console xem data đã lên chưa

### Database bị lỗi
**Giải pháp:**
1. Vào Settings → Clear cache
2. Hoặc: Gỡ app và cài lại
3. Data sẽ được tải lại từ Firebase

---

## 📊 MONITORING

### Theo dõi Firebase Usage
1. Vào Firebase Console
2. Chọn project
3. Xem **Firestore** → Usage
4. Xem **Storage** → Usage
5. Đảm bảo không vượt quá free tier

### Free Tier Limits
- **Firestore:**
  - 50,000 document reads/day
  - 20,000 document writes/day
  - 1GB storage
- **Storage:**
  - 5GB storage
  - 1GB download/day

---

## 🎯 ROLLOUT PLAN

### Phase 1: Pilot Test (1 tuần)
- [ ] Cài đặt cho 2-3 nhân viên
- [ ] Test trong môi trường thực tế
- [ ] Thu thập feedback

### Phase 2: Limited Rollout (2 tuần)
- [ ] Cài đặt cho 50% nhân viên
- [ ] Monitor performance
- [ ] Fix bugs nếu có

### Phase 3: Full Rollout
- [ ] Cài đặt cho tất cả nhân viên
- [ ] Training session
- [ ] Full production use

---

## 📞 SUPPORT

### Khi gặp vấn đề
1. Kiểm tra phần Troubleshooting ở trên
2. Đọc lại documentation:
   - [`PRODUCTION_STATUS.md`](PRODUCTION_STATUS.md)
   - [`README.md`](README.md)
   - [`CODE_EXPLANATION.md`](CODE_EXPLANATION.md)

### Contact
- **Developer:** PRM393 Team
- **Firebase:** https://console.firebase.google.com
- **GitHub:** https://github.com/duyanh2509/PRM_Project

---

## ✅ DEPLOYMENT CHECKLIST

### Pre-Deployment
- [x] APK file built successfully
- [x] Firebase configured
- [x] Data seeded
- [x] Documentation complete
- [ ] Staff training completed

### Deployment Day
- [ ] Install APK on devices
- [ ] Login with admin credentials
- [ ] Download initial data
- [ ] Test core features
- [ ] Train staff on usage

### Post-Deployment
- [ ] Monitor Firebase usage
- [ ] Collect user feedback
- [ ] Fix bugs if any
- [ ] Plan future updates

---

**🎉 Chúc bạn deployment thành công!**
