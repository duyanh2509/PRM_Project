# WATER METER APP - INDEX TÌM KIẾM CODE

## MODELS (lib/models/)
- **customer_model.dart**: Model khách hàng (customerCode, customerName, address, totalDebt, lastReading, ...)
  - `fromMap()`, `toMap()`, `copyWith()`, `formattedDebt`, `formattedLastReading`

- **meter_record_model.dart**: Model bản ghi (ghi số + thu tiền)
  - recordType: 'meter' hoặc 'payment'
  - GHI SỐ: oldReading, newReading, consumedUnits, pricePerUnit
  - THU TIỀN: amountCollected, paymentMethod, paymentStatus
  - `fromMap()`, `toMap()`, `copyWith()`, `isSynced`

- **user_model.dart**: Model nhân viên (username, password, fullName, areaCode, areaName)
  - `fromMap()`, `toMap()`, `copyWith()`

## DATABASE (lib/database/)
- **database_helper.dart**: SQLite local database
  - TABLES: users, customers, reading_meter
  - LOGIN: `login(username, password)`
  - CUSTOMER: `getCustomersForUser()`, `upsertCustomer()`
  - GHI SỐ: `insertMeterRecord()` → auto update totalDebt TĂNG
  - THU TIỀN: `insertPaymentRecord()` → auto update totalDebt GIẢM
  - SYNC: `getRecordsForUser()`, `countPendingRecordsForUser()`, `markRecordAsSynced()`
  - CACHE: `clearSyncedLocalCache()`, `estimateCacheSizeMb()`

## PROVIDERS (lib/providers/)
- **auth_provider.dart**: Quản lý đăng nhập
  - STATE: `_currentUser`, `_isLoading`, `_errorMessage`
  - `login(username, password)`: Check local → Firebase → save local
  - `logout()`: Clear user

- **customer_list_provider.dart**: Danh sách khách hàng
  - STATE: `_customers`, `_searchQuery`
  - `loadCustomersForUser(user)`: Load từ DB
  - `updateSearchQuery(value)`: Real-time search
  - GETTER: `filteredCustomers`: Auto filter theo searchQuery

- **history_provider.dart**: Lịch sử ghi số/thu tiền
  - STATE: `_meterRecords`, `_paymentRecords`
  - `loadForUser(user)`: Load cả 2 loại
  - `addMeterRecord()`, `addPaymentRecord()`: Thêm → reload

- **settings_provider.dart**: Cài đặt & đồng bộ
  - STATE: `_isOnline`, `_isSyncing`, `_pendingSyncCount`, `_cacheSizeMb`
  - `toggleOnline()`: Bật/tắt online mode
  - `downloadLatestRoute(user)`: Tải khách hàng từ server
  - `syncNow(user)`: Đồng bộ records lên server
  - `clearCache()`: Xóa cache đã sync

## SERVICES (lib/services/)
- **firebase_service.dart**: Tương tác Firestore & Cloudinary
  - `authenticateStaff(username, password)`: Login verify từ Firestore
  - `downloadCustomers(areaCode)`: Query customers
  - `syncRecord(record)`: Upload record + ảnh lên Firestore/Cloudinary

- **api_service.dart**: Orchestrator cho download & sync
  - `downloadAssignedCustomers(user)`: Download customers → save local
  - `syncPendingRecords(user)`: Sync pending records → markSynced

- **connectivity_service.dart**: Quản lý kết nối mạng
  - STATE: `_manualOnline`, `_networkAvailable`
  - GETTER: `isOnline` (chỉ true khi CẢ 2 đều true)
  - `toggleManualOnline()`: User bật/tắt thủ công

- **cloudinary_service.dart**: Upload ảnh lên Cloudinary
  - `uploadImage(file, customerCode)`: Upload → return public URL

- **local_image_service.dart**: Lưu ảnh local
  - `saveProofImage(sourceFile, customerCode)`: Copy ảnh camera/gallery → app folder

- **sync_service.dart**, **download_service.dart**: Wrapper services
  - Forward requests sang ApiService

## SCREENS (lib/screens/)
- **login_screen.dart**: Màn hình đăng nhập
  - `_handleLogin()`: Validate → AuthProvider.login() → navigate
  - UI: Icon water_drop, TextField username/password, Button "Đăng nhập"

- **main_navigation_screen.dart**: Bottom Tab Navigation (4 tabs)
  - STATE: `_currentIndex` (0-3)
  - `_selectTab(index)`: Chuyển tab
  - IndexedStack: HomeScreen, CustomerListScreen, HistoryScreen, SettingsScreen

- **home_screen.dart**: Trang chủ (Dashboard)
  - UI: _HeroCard, _SyncBanner, 3× _StatCard, _ProgressCard, 4× _ActionCard
  - Consumer4: Lắng nghe 4 providers

- **customer_list_screen.dart**: Danh sách khách hàng
  - STATE: `_isGridView` (List/Grid toggle)
  - `_refreshCustomers()`: Pull-to-refresh
  - UI: Search box, _AreaBanner, List/Grid của _CustomerCard
  - Bấm card → Navigate to CustomerDetailScreen

- **customer_detail_screen.dart**: Chi tiết khách hàng
  - UI: _ProfileCard, _DebtCard, _UsageChartCard (CustomPainter), Gallery ảnh
  - _BottomActionBar: 2 nút "Ghi chỉ số" + "Thu tiền"

- **meter_reading_screen.dart**: Ghi chỉ số
  - CONTROLLERS: `_readingController`, `_noteController`
  - STATE: `_proofImage`
  - `_saveRecord()`: Validate → insertMeterRecord → reload → back
  - `_pickImage()`: Camera/Gallery → saveProofImage
  - UI: _SummaryCard, Input card (chỉ số cũ/mới, tự động tính tiêu thụ/phát sinh), Ảnh

- **payment_collection_screen.dart**: Thu tiền
  - CONTROLLERS: `_amountController`, `_noteController`
  - STATE: `_paymentMethod`, `_paymentStatus`, `_proofImage`
  - `_savePayment()`: Validate → insertPaymentRecord → reload → back
  - UI: _CustomerSummaryCard (breakdown nợ), _ReceiptProofCard, _PaymentDataCard (tự động tính còn lại)

- **history_screen.dart**: Lịch sử
  - STATE: `_segmentIndex` (0=Ghi số, 1=Thu tiền), `_searchQuery`
  - UI: _SegmentControl, Search, List của _HistoryCard
  - Mode meter: _MeterReadingPanel (chỉ số cũ/mới)
  - Mode payment: _PaymentPanel (số tiền + badges)

- **settings_screen.dart**: Hệ thống
  - `_handleLogout()`: Dialog xác nhận → logout
  - `_download()`: downloadLatestRoute → reload → show message
  - `_sync()`: syncNow → reload → show message
  - `_clearCache()`: clearCache → reload
  - UI: _ProfileCard, _StatusCard (4 metrics), _ActionPanel (2 buttons), _LogoutCard

## UTILS (lib/utils/)
- **collection_status_helper.dart**: Tính trạng thái thu tiền
  - ENUM: noReading, unpaid, partial, paid
  - `resolveCustomerCollectionStatus()`: Tính toán status

## MAIN (lib/)
- **main.dart**: Entry point
  - Lock orientation: PORTRAIT only
  - Firebase initialization
  - MultiProvider: 4 providers
  - MaterialApp: theme + LoginScreen

---

## SEARCH KEYWORDS

**TÌM LOGIC TÍNH CÔNG NỢ**: database_helper.dart → `_applyMeterEffectToLocalCustomer()`, `_applyPaymentEffectToLocalCustomer()`

**TÌM XỬ LÝ ĐĂNG NHẬP**: auth_provider.dart → `login()` + database_helper.dart → `login()` + firebase_service.dart → `authenticateStaff()`

**TÌM UPLOAD ẢNH**: firebase_service.dart → `syncRecord()` → `_uploadToCloudinary()` + cloudinary_service.dart → `uploadImage()`

**TÌM SYNC LOGIC**: api_service.dart → `syncPendingRecords()` → firebase_service.dart → `syncRecord()`

**TÌM DOWNLOAD LOGIC**: api_service.dart → `downloadAssignedCustomers()` → firebase_service.dart → `downloadCustomers()`

**TÌM UI CÔNG NỢ**: customer_detail_screen.dart → `_DebtCard`

**TÌM UI BIỂU ĐỒ**: customer_detail_screen.dart → `_UsageChartCard` → `_UsageChartPainter`

**TÌM SEARCH LOGIC**: customer_list_provider.dart → `filteredCustomers` getter

**TÌM REAL-TIME CALCULATION**: meter_reading_screen.dart → `build()` (consumedUnits, estimatedBill) + payment_collection_screen.dart → `build()` (remainingAmount)
