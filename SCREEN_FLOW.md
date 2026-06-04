# Water Meter App - Screen Flow (Ứng dụng cho Nhân viên Thu tiền nước)

## 🎯 Đối tượng sử dụng: NHÂN VIÊN THU TIỀN ĐIỆN NƯỚC

## Sơ đồ luồng màn hình (Screen Flow Diagram)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SPLASH SCREEN                              │
│                     (Màn hình khởi động)                            │
│                                                                     │
│                    [Logo ứng dụng]                                  │
│                    Loading...                                       │
│                    Kiểm tra kết nối mạng                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         LOGIN SCREEN                                │
│                   (Đăng nhập cho nhân viên)                         │
│                                                                     │
│  ┌──────────────────────────────────────────────┐                   │
│  │  Mã nhân viên: [_____________]               │                   │
│  │  Mật khẩu:     [_____________]               │                   │
│  │                                              │                   │
│  │  [ ] Ghi nhớ đăng nhập                       │                   │
│  │                                              │                   │
│  │         [ĐĂNG NHẬP]                          │                   │
│  │                                              │                   │
│  │  Trạng thái: 🔴 Offline / 🟢 Online          │                   │
│  └──────────────────────────────────────────────┘                   │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         HOME SCREEN                                 │
│                   (Dashboard - Màn hình chính)                      │
│                                                                     │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  👤 Nhân viên: Nguyễn Văn A (NV001)                 │            │
│  │  📅 Hôm nay: 25/05/2026                             │            │
│  │  🌐 Trạng thái: 🟢 Online / 🔴 Offline              │            │
│  │  ⚠️ Chưa đồng bộ: 15 bản ghi                        │            │
│  │  📥 Dữ liệu: Cập nhật 2 giờ trước                   │            │
│  └─────────────────────────────────────────────────────┘            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────┐            │
│  │  📊 THỐNG KÊ HÔM NAY                                │            │
│  │  ├─ Đã ghi: 25 khách hàng                           │            │
│  │  ├─ Tổng tiêu thụ: 450.5 m³                         │            │
│  │  ├─ 💰 Đã thu: 6,500,000 VNĐ                        │            │
│  │  ├─ ⚠️ Còn nợ: 2,300,000 VNĐ                        │            │
│  │  └─ Chưa ghi: 10 khách hàng                         │            │
│  └─────────────────────────────────────────────────────┘            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ TẢI DỮ LIỆU  │  │ DANH SÁCH    │  │ ĐỒNG BỘ      │              │
│  │ MỚI          │  │ KHÁCH HÀNG   │  │ DỮ LIỆU      │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                      │
└─────────┼─────────────────┼─────────────────┼──────────────────────┘
          │                 │                 │
          ▼                 │                 ▼
┌──────────────────┐        │       ┌──────────────────┐
│ DOWNLOAD DATA    │        │       │  SYNC SCREEN     │
│ (Tải dữ liệu)    │        │       │  (Đồng bộ)       │
│                  │        │       │                  │
│ 🌐 Cần mạng!     │        │       │ - 15 bản ghi     │
│                  │        │       │   chưa sync      │
│ - Tải DS KH      │        │       │ - [Đồng bộ]      │
│ - Công nợ        │        │       │ - Progress bar   │
│ - Lịch sử TT     │        │       │ - Xem lỗi        │
│ - [TẢI NGAY]     │        │       └──────────────────┘
│                  │        │
│ Progress:        │        │
│ ████░░ 35/50     │        │
└──────────────────┘        │
                            ▼
                  ┌──────────────────┐
                  │ CUSTOMER LIST    │
                  │ (DS Khách hàng)  │
                  │                  │
                  │ - Tìm kiếm       │
                  │ - Filter         │
                  │ - ⚠️ Badge nợ    │
                  │ - Chọn KH        │
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ CUSTOMER DETAIL  │
                  │ (Chi tiết KH)    │
                  │                  │
                  │ KH: KH001        │
                  │ Tên: Nguyễn Văn A│
                  │ Địa chỉ: 123 ABC │
                  │                  │
                  │ 💰 CÔNG NỢ:      │
                  │ ⚠️ Nợ 3 tháng   │
                  │ 450,000 VNĐ      │
                  │                  │
                  │ Lịch sử ghi số   │
                  │ Lịch sử TT       │
                  │                  │
                  │ [GHI SỐ MỚI]     │
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ ADD READING      │
                  │ (Ghi chỉ số mới) │
                  │                  │
                  │ KH: KH001        │
                  │ Tên: Nguyễn Văn A│
                  │                  │
                  │ Chỉ số cũ: 100.5 │
                  │ Chỉ số mới: [__] │
                  │ Tiêu thụ: 24.8   │
                  │                  │
                  │ [Chụp ảnh]       │
                  │                  │
                  │ 💰 TÍNH TIỀN:    │
                  │ Tháng này:       │
                  │ 372,000 VNĐ      │
                  │ Tiền nợ:         │
                  │ 450,000 VNĐ      │
                  │ ─────────────    │
                  │ TỔNG:            │
                  │ 822,000 VNĐ      │
                  │                  │
                  │ [THU TIỀN]       │
                  └────────┬─────────┘
                           │
                           ├──────────────┐
                           │              │
                           ▼              ▼
                  ┌──────────────┐ ┌──────────────┐
                  │ CAMERA       │ │ PAYMENT      │
                  │ SCREEN       │ │ SCREEN       │
                  │              │ │              │
                  │ [Preview]    │ │ Tổng phải    │
                  │              │ │ thu:         │
                  │ Hướng dẫn:   │ │ 822,000 VNĐ  │
                  │ Chụp rõ      │ │              │
                  │ chỉ số       │ │ Số tiền thu: │
                  │              │ │ [________]   │
                  │ [Chụp] [Hủy] │ │              │
                  └──────────────┘ │ ☐ Thu đủ     │
                                   │ ☐ Thu 1 phần │
                                   │              │
                                   │ Ghi chú:     │
                                   │ [_________]  │
                                   │              │
                                   │ [XÁC NHẬN]   │
                                   └──────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                    BOTTOM NAVIGATION BAR                            │
│                  (Thanh điều hướng dưới)                            │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  [Home]  │  │[Khách hàng]│  │ [Lịch sử] │  │ [Cài đặt] │            │
│  │   🏠     │  │   👥     │  │   📊     │  │   ⚙️     │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │             │             │             │                   │
└───────┼─────────────┼─────────────┼─────────────┼───────────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
   HOME SCREEN   CUSTOMER     HISTORY       SETTINGS
                 LIST         SCREEN        SCREEN
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ HISTORY SCREEN   │
                                    │ (Lịch sử)        │
                                    │                  │
                                    │ Tab 1: Ghi số    │
                                    │ - Hôm nay: 25    │
                                    │ - Tuần: 150      │
                                    │ - Tháng: 600     │
                                    │                  │
                                    │ Tab 2: Thu tiền  │
                                    │ - Đã thu:        │
                                    │   6.5M VNĐ       │
                                    │ - Còn nợ:        │
                                    │   2.3M VNĐ       │
                                    │                  │
                                    │ Filter: Ngày/KH  │
                                    └────────┬─────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │ DETAIL SCREENS   │
                                    │                  │
                                    │ • Reading Detail │
                                    │ • Payment Detail │
                                    │                  │
                                    │ [Sửa] [Xóa]      │
                                    └──────────────────┘
                                    
                                    ┌──────────────────┐
                                    │ SETTINGS SCREEN  │
                                    │ (Cài đặt)        │
                                    │                  │
                                    │ - Thông tin NV   │
                                    │ - Đổi mật khẩu   │
                                    │ - Cài đặt sync   │
                                    │ - Xóa cache      │
                                    │ - Về ứng dụng    │
                                    │ - [Đăng xuất]    │
                                    └──────────────────┘
```

## Mô tả chi tiết các màn hình (CHO NHÂN VIÊN)

### 1. **Splash Screen** (Màn hình khởi động)
- Hiển thị logo ứng dụng
- Loading animation
- **Kiểm tra kết nối mạng** (Online/Offline)
- Load dữ liệu từ SQLite local
- Tự động chuyển sang Login hoặc Home (nếu đã đăng nhập)

### 2. **Login Screen** (Màn hình đăng nhập nhân viên)
- Input: **Mã nhân viên**, Mật khẩu
- Checkbox: Ghi nhớ đăng nhập
- Button: Đăng nhập
- Hiển thị trạng thái: 🟢 Online / 🔴 Offline
- **Không có chức năng đăng ký** (Admin tạo tài khoản)

### 3. **Home Screen** (Dashboard - Màn hình chính)
- **Header:**
  - Thông tin nhân viên: Tên, Mã NV
  - Ngày hiện tại
  - Trạng thái kết nối: Online/Offline
  - **Badge cảnh báo: Số bản ghi chưa đồng bộ**
  - **Thời gian cập nhật dữ liệu gần nhất**
  
- **Thống kê hôm nay:**
  - Số khách hàng đã ghi
  - Tổng tiêu thụ nước
  - **💰 Tổng tiền đã thu**
  - **⚠️ Tổng công nợ còn lại**
  - Số khách hàng chưa ghi
  
- **Quick Actions:**
  - **Tải dữ liệu mới** (cần mạng)
  - Danh sách khách hàng
  - Đồng bộ dữ liệu

### 4. **Download Data Screen** ⭐ (Tải dữ liệu - CẦN MẠNG)
- **Mục đích:** Tải thông tin KH trước khi đi thu
- **Yêu cầu:** Phải có kết nối internet
- **Hiển thị:**
  - Thời gian cập nhật lần cuối
  - Số lượng khách hàng sẽ tải
  - Button: [TẢI DỮ LIỆU NGAY]
- **Progress:**
  - Progress bar: X/Y khách hàng
  - Danh sách đang tải
  - Thời gian ước tính
- **Dữ liệu tải về:**
  - Thông tin khách hàng
  - Chỉ số tháng trước
  - **Công nợ chi tiết**
  - Lịch sử thanh toán
  - Đơn giá

### 5. **Customer List Screen** (Danh sách khách hàng)
- Danh sách tất cả khách hàng được phân công
- **Badge công nợ:** ⚠️ Nợ X tháng
- Tìm kiếm: Theo mã KH, tên, địa chỉ
- Filter: Đã ghi/Chưa ghi hôm nay, Có nợ/Không nợ
- Sắp xếp: Theo tên, mã, công nợ
- Tap vào khách hàng → Customer Detail

### 6. **Customer Detail Screen** ⭐ (Chi tiết khách hàng)
- **Thông tin cơ bản:**
  - Mã, Tên, Địa chỉ, SĐT
  - Chỉ số tháng trước
  
- **💰 Công nợ:**
  - Tổng nợ
  - Số tháng nợ
  - Chi tiết từng tháng nợ
  
- **Lịch sử:**
  - Lịch sử ghi số
  - Lịch sử thanh toán
  
- **Actions:**
  - Button: [GHI SỐ MỚI]

### 7. **Add Reading Screen** (Màn hình ghi chỉ số mới)
- **Hiển thị thông tin khách hàng:**
  - Mã khách hàng
  - Tên khách hàng
  - Địa chỉ
  - Chỉ số cũ (lần ghi gần nhất)
  
- **Input:**
  - Chỉ số mới (validate > chỉ số cũ)
  - Tự động tính tiêu thụ
  - Ghi chú (optional)
  
- **💰 Tính tiền tự động:**
  - Tiền tháng này = Tiêu thụ × Đơn giá
  - Tiền nợ (nếu có)
  - **TỔNG PHẢI THU**
  
- **Chụp ảnh đồng hồ** (bắt buộc)
- Button: **[THU TIỀN]** → Chuyển sang Payment Screen

### 8. **Payment Screen** ⭐ (Thu tiền)
- **Hiển thị:**
  - Tiền tháng hiện tại
  - Tiền nợ (chi tiết từng tháng)
  - **TỔNG PHẢI THU**
  
- **Input:**
  - Số tiền thu: [______] VNĐ
  - Radio: Thu đủ / Thu một phần
  - Ghi chú
  
- **Tính toán thông minh:**
  - Nếu thu đủ → Trả hết nợ + tháng này
  - Nếu thu một phần → Ưu tiên trả nợ cũ trước
  
- Button: [XÁC NHẬN THU TIỀN]
- **Lưu vào SQLite:** payments table

### 9. **Camera Screen** (Màn hình chụp ảnh đồng hồ)
- Camera preview
- Hướng dẫn: "Chụp rõ chỉ số đồng hồ"
- Buttons: Chụp ảnh, Hủy
- Preview ảnh vừa chụp
- Buttons: Chụp lại, Xác nhận

### 10. **History Screen** (Lịch sử)
- **Tab 1: Lịch sử ghi số**
  - Danh sách các lần ghi
  - Badge: ✅ Đã sync / ⏳ Chưa sync
  - Filter: Theo ngày, KH
  
- **Tab 2: Lịch sử thu tiền** ⭐
  - Danh sách các lần thu tiền
  - Tổng đã thu hôm nay/tuần/tháng
  - Công nợ còn lại
  - Filter: Theo ngày, KH, Thu đủ/Thu một phần

### 11. **Reading Detail Screen** (Chi tiết lần ghi)
- Mã khách hàng, Tên, Địa chỉ
- Ngày giờ ghi
- Chỉ số cũ / mới
- Tiêu thụ
- Ảnh đồng hồ (xem full size)
- Ghi chú
- **Trạng thái đồng bộ:** Đã sync / Chưa sync
- Buttons: Sửa, Xóa (chỉ khi chưa sync)

### 12. **Payment Detail Screen** ⭐ (Chi tiết thu tiền)
- Thông tin khách hàng
- Ngày giờ thu
- Tiền tháng hiện tại
- Tiền nợ đã trả
- Tổng đã thu
- Còn nợ
- Ghi chú
- **Trạng thái đồng bộ**
- Buttons: Xem, In biên lai (optional)

### 13. **Sync Screen** (Màn hình đồng bộ dữ liệu)
- **Hiển thị:**
  - Số bản ghi chưa đồng bộ (readings + payments)
  - Danh sách các bản ghi chưa sync
  - Trạng thái kết nối mạng
  
- **Button: ĐỒNG BỘ**
  - Chỉ hoạt động khi có mạng
  - Hiển thị progress bar
  - Upload: Ảnh + Chỉ số + **Thanh toán + Cập nhật nợ**
  - Cập nhật trạng thái real-time
  
- **Xử lý lỗi:**
  - Hiển thị bản ghi lỗi
  - Cho phép retry
  - Bỏ qua và sync tiếp

### 14. **Settings Screen** (Cài đặt)
- **Thông tin nhân viên:**
  - Mã nhân viên
  - Tên
  - Số điện thoại
  
- **Cài đặt:**
  - Đổi mật khẩu
  - Cài đặt đồng bộ tự động
  - Xóa cache/ảnh đã sync
  - Về ứng dụng
  
- Button: **Đăng xuất**

## Luồng chính (Main Flows) - CHO NHÂN VIÊN

### Flow 0: Chuẩn bị trước khi đi thu (CẦN MẠNG) ⭐
```
Login → Home → Download Data Screen → [Tải dữ liệu] → 
Download từ server (KH + Công nợ + Lịch sử) → Lưu SQLite → 
Sẵn sàng đi thu OFFLINE
```

### Flow 1: Đăng nhập
```
Splash → Login (Mã NV + Password) → Home
```

### Flow 2: Ghi chỉ số và thu tiền (OFFLINE) ⭐
```
Home → Customer List → Chọn KH → Customer Detail (xem công nợ) → 
Add Reading → Nhập chỉ số → Camera → Chụp ảnh → 
Tính tiền (tháng này + nợ) → Payment Screen → 
Nhập số tiền thu → Tính toán nợ còn lại → 
LƯU OFFLINE (readings + payments + update debts) → Home
```

### Flow 3: Xem lịch sử
```
Home → History → 
  Tab 1: Lịch sử ghi số → Reading Detail
  Tab 2: Lịch sử thu tiền → Payment Detail
```

### Flow 4: Đồng bộ dữ liệu lên server (ONLINE) ⭐
```
Home → Sync Screen → [Đồng bộ] → 
Upload từng bản ghi:
  1. Upload ảnh
  2. Upload chỉ số + thanh toán + cập nhật nợ
  3. Cập nhật isSynced = 1
→ Progress → Hoàn tất → Home
```

### Flow 5: Xem chi tiết khách hàng
```
Home → Customer List → Chọn KH → Customer Detail →
Xem công nợ + Lịch sử ghi + Lịch sử thanh toán
```

### Flow 6: Quản lý cài đặt
```
Home → Settings → [Đổi MK / Cài đặt sync / Xóa cache] → Home
```

### Flow 7: Đăng xuất
```
Home → Settings → [Đăng xuất] → Login
```

## Ghi chú kỹ thuật (CHO ỨNG DỤNG NHÂN VIÊN)

### Navigation
- Sử dụng **Named Routes** trong Flutter
- Bottom Navigation Bar cho 4 màn hình chính: Home, Khách hàng, Lịch sử, Cài đặt
- Stack navigation cho các màn hình phụ

### State Management
- Đề xuất: **Provider** (như trong README)
- **customer_provider.dart**: Quản lý danh sách khách hàng
- **reading_provider.dart**: Quản lý các lần ghi chỉ số
- **sync_provider.dart**: Quản lý trạng thái đồng bộ

### Data Persistence (OFFLINE-FIRST)
- **SQLite** (sqflite): Lưu trữ chính
  - Bảng `customers`: Danh sách khách hàng
  - Bảng `meter_readings`: Các lần ghi chỉ số
  - Trường `isSynced`: 0 = chưa sync, 1 = đã sync
  
- **Local Storage**: Lưu ảnh đồng hồ
  - Path: `/storage/water_meter_images/`
  - Format: `{customerCode}_{timestamp}.jpg`

### Sync Logic
- **Connectivity Service**: Lắng nghe thay đổi kết nối mạng
- **Sync Service**: 
  - Tự động sync khi có mạng (optional)
  - Manual sync qua Sync Screen
  - Upload ảnh trước, sau đó upload dữ liệu
  - Retry logic khi lỗi
  - Cập nhật `isSynced = 1` sau khi thành công

### API Integration
- **api_service.dart**: HTTP calls
- Endpoints:
  - `POST /api/upload-image`: Upload ảnh đồng hồ
  - `POST /api/meter-readings`: Upload dữ liệu ghi chỉ số
  - `GET /api/customers`: Lấy danh sách khách hàng
  - `POST /api/auth/login`: Đăng nhập nhân viên

### Camera & Image
- **camera**: Chụp ảnh đồng hồ
- **image_picker**: Chọn ảnh từ thư viện (backup)
- Nén ảnh trước khi lưu để tiết kiệm dung lượng
- OCR (optional): Đọc chỉ số tự động từ ảnh

### Permissions Required
- Camera
- Storage (Read/Write)
- Internet
- Network State

### Key Features
- ✅ **Hoạt động hoàn toàn OFFLINE**
- ✅ **Tự động đồng bộ khi có mạng**
- ✅ **Chụp ảnh làm bằng chứng**
- ✅ **Lưu trữ local an toàn**
- ✅ **Xử lý lỗi thông minh**

