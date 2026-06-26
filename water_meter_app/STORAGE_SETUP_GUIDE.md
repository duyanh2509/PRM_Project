# 📦 Hướng Dẫn Cấu Hình Firebase Storage

## 🎯 Mục Đích

Hướng dẫn cấu hình Firebase Storage để lưu trữ ảnh minh chứng (meter readings và payments) dưới dạng **URL công khai** có thể xem trực tiếp từ trình duyệt.

---

## 📋 Yêu Cầu

- Firebase Project đã được tạo
- Firebase CLI đã cài đặt: `npm install -g firebase-tools`
- Đã đăng nhập Firebase: `firebase login`

---

## 🚀 Các Bước Thực Hiện

### **Bước 1: Kiểm tra Storage Rules hiện tại**

File `storage.rules` trong project:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /meter_images/{fileName} {
      // Cho phép đọc công khai (để xem ảnh từ URL)
      allow read: if true;
      
      // Cho phép upload ảnh < 15MB, định dạng image/*
      allow write: if request.resource.size < 15 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

**Giải thích:**
- `allow read: if true` → Cho phép **mọi người** đọc ảnh từ URL (public read)
- `allow write: if ...` → Chỉ cho phép upload file:
  - Kích thước < 15MB
  - Định dạng image/* (jpg, png, webp...)

---

### **Bước 2: Deploy Storage Rules lên Firebase**

#### **Option 1: Deploy qua Firebase Console (Web UI)**

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Storage** → **Rules**
4. Copy nội dung từ file `storage.rules` vào editor
5. Click **Publish**

#### **Option 2: Deploy qua Firebase CLI (Khuyến nghị)**

```bash
cd water_meter_app

# Khởi tạo Firebase (nếu chưa làm)
firebase init storage

# Deploy rules
firebase deploy --only storage
```

**Output khi thành công:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/your-project/overview
```

---

### **Bước 3: Kiểm tra Storage đã hoạt động**

#### **Test 1: Upload ảnh từ app**

1. Chạy app Flutter
2. Vào màn hình **Ghi chỉ số** hoặc **Thu tiền**
3. Chụp/chọn ảnh minh chứng
4. Lưu record
5. Đồng bộ lên Firebase (Settings → Đồng bộ dữ liệu)

#### **Test 2: Kiểm tra URL trong Firestore**

1. Mở Firebase Console → **Firestore Database**
2. Vào collection `meter_readings` hoặc `payments`
3. Mở một document vừa tạo
4. Tìm field `proofImagePath`, nó phải có dạng:
   ```
   https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/meter_images%2FKH001_1234567890.jpg?alt=media&token=...
   ```
5. **Copy URL và mở trong tab mới của trình duyệt**
6. Ảnh phải hiển thị được!

---

## 🛡️ Security Best Practices

### **1. Giới hạn kích thước upload**

Storage Rules đã giới hạn 15MB. App cũng có validation:

```dart
// firebase_service.dart
final fileSize = await imageFile.length();
const maxSize = 15 * 1024 * 1024; // 15MB
if (fileSize > maxSize) {
  // Reject upload
}
```

### **2. Giới hạn định dạng file**

Rules chỉ chấp nhận `image/*`:
- ✅ image/jpeg
- ✅ image/png
- ✅ image/webp
- ❌ application/pdf
- ❌ text/html

### **3. Rate Limiting (Khuyến nghị thêm)**

Nếu muốn giới hạn số lần upload từ cùng một IP:

```javascript
// Thêm vào storage.rules
allow write: if request.resource.size < 15 * 1024 * 1024
  && request.resource.contentType.matches('image/.*')
  && request.time < timestamp.date(2025, 12, 31); // Expiry date
```

### **4. Xóa ảnh cũ (Cleanup)**

Để tránh tốn chi phí storage, nên xóa ảnh cũ khi không dùng:

```dart
// firebase_service.dart
await FirebaseService.instance.deleteImage(oldImageUrl);
```

---

## 🔧 Troubleshooting

### **Lỗi: "Permission denied"**

**Nguyên nhân:** Storage Rules chưa được deploy hoặc sai cấu hình.

**Giải pháp:**
1. Kiểm tra lại Rules trong Firebase Console
2. Đảm bảo `allow read: if true;` có trong rules
3. Deploy lại: `firebase deploy --only storage`

### **Lỗi: "File size exceeds limit"**

**Nguyên nhân:** File > 15MB.

**Giải pháp:**
- App đã tự động nén ảnh xuống 65% quality và maxWidth 1024px
- Nếu vẫn lỗi, giảm `imageQuality` trong code:
  ```dart
  final picked = await _imagePicker.pickImage(
    imageQuality: 50, // Giảm từ 65 xuống 50
  );
  ```

### **Lỗi: "Network error" khi upload**

**Nguyên nhân:** Không có kết nối internet hoặc Firebase Storage chưa được enable.

**Giải pháp:**
1. Kiểm tra internet
2. Vào Firebase Console → Storage → Click **Get Started** nếu chưa enable
3. Chọn region gần Việt Nam nhất (Singapore - asia-southeast1)

### **Ảnh không hiển thị khi mở URL**

**Nguyên nhân:** URL không có token hoặc CORS issue.

**Giải pháp:**
1. Đảm bảo URL có `?alt=media&token=...`
2. Check CORS settings trong Firebase Storage:
   ```bash
   gsutil cors set cors.json gs://your-bucket.appspot.com
   ```
   
   File `cors.json`:
   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

---

## 📊 Chi Phí Ước Tính

Firebase Storage pricing (tính đến 12/2024):

| Item | Giá | Ước tính/tháng |
|------|-----|----------------|
| Storage | $0.026/GB | 1000 ảnh (2MB mỗi ảnh) = $0.05 |
| Download | $0.12/GB | 10,000 lượt xem = $0.24 |
| Upload | $0.12/GB | 1000 uploads = $0.024 |
| **Tổng** | | **~$0.31/tháng** |

**Free tier:** 5GB storage, 1GB download/ngày → Đủ cho project nhỏ!

---

## ✅ Checklist Hoàn Thành

- [ ] Deploy Storage Rules lên Firebase
- [ ] Test upload ảnh từ app
- [ ] Verify URL trong Firestore
- [ ] Test mở URL trong browser
- [ ] Confirm ảnh hiển thị đúng
- [ ] Setup monitoring trong Firebase Console

---

## 📚 Tài Liệu Tham Khảo

- [Firebase Storage Rules](https://firebase.google.com/docs/storage/security)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Firebase Storage Pricing](https://firebase.google.com/pricing)

---

## 🎉 Kết Quả Mong Đợi

Sau khi hoàn thành:

1. ✅ Ảnh minh chứng được upload lên Firebase Storage
2. ✅ URL công khai được lưu vào Firestore (`proofImagePath`)
3. ✅ Copy URL từ Firestore → Paste vào browser → Xem được ảnh
4. ✅ Không cần login hoặc token để xem ảnh (public read)
5. ✅ Ảnh được tổ chức trong folder `meter_images/`

**Ví dụ URL:**
```
https://firebasestorage.googleapis.com/v0/b/water-meter-app.appspot.com/o/meter_images%2FKH001_1703001234567.jpg?alt=media&token=abc123...
```

---

**Lưu ý quan trọng:** 
- URL này là **CÔNG KHAI** (public), bất kỳ ai có link đều xem được
- Nếu cần bảo mật, thêm authentication vào Storage Rules:
  ```javascript
  allow read: if request.auth != null; // Chỉ user đã login
  ```
