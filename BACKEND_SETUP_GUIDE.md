# 🚀 HƯỚNG DẪN SETUP BACKEND - Water Meter App

Hướng dẫn chi tiết setup backend cho môn PRM393 (Demo/Học tập)

---

## 🎯 MỤC TIÊU

Setup backend **miễn phí** để:
- Test sync data từ app Flutter
- Demo chức năng upload ảnh
- Học cách kết nối mobile app với API

---

## 📋 CHUẨN BỊ

### Cần có:
- [x] Node.js >= 18.x (Download từ [nodejs.org](https://nodejs.org))
- [x] Git
- [x] Code editor (VS Code khuyên dùng)
- [x] Postman (để test API)

### Tài khoản miễn phí:
- [ ] [Railway.app](https://railway.app) - Hosting backend
- [ ] [Cloudinary](https://cloudinary.com) - Lưu ảnh miễn phí

---

## 🏗️ OPTION 1: BACKEND ĐƠN GIẢN (Đề xuất cho học tập)

### Bước 1: Tạo project backend

```bash
# Tạo folder
mkdir water-meter-backend
cd water-meter-backend

# Init npm
npm init -y

# Install dependencies
npm install express cors dotenv multer jsonwebtoken bcrypt pg
npm install --save-dev nodemon
```

### Bước 2: Tạo cấu trúc files

```
water-meter-backend/
├── src/
│   ├── config/
│   │   └── database.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── customerController.js
│   │   └── syncController.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── customers.js
│   │   └── sync.js
│   ├── middleware/
│   │   └── auth.js
│   └── app.js
├── uploads/
├── .env
├── .gitignore
├── package.json
└── server.js
```

### Bước 3: Code backend cơ bản

**package.json:**
```json
{
  "name": "water-meter-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "multer": "^1.4.5-lts.1",
    "jsonwebtoken": "^9.0.0",
    "bcrypt": "^5.1.0",
    "pg": "^8.11.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
```

**server.js:**
```javascript
require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📝 API Docs: http://localhost:${PORT}/api/health`);
});
```

**src/app.js:**
```javascript
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const customerRoutes = require('./routes/customers');
const syncRoutes = require('./routes/sync');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Water Meter API is running',
    timestamp: new Date().toISOString()
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/sync', syncRoutes);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: err.message 
  });
});

module.exports = app;
```

**src/routes/auth.js:**
```javascript
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const router = express.Router();

// Demo users (thay bằng database thật)
const users = [
  {
    id: 1,
    username: 'admin',
    password: '$2b$10$abcdefghijklmnopqrstuvwxyz', // '12345678' hashed
    fullName: 'Admin',
    role: 'admin'
  },
  {
    id: 2,
    username: 'staff01',
    password: '$2b$10$abcdefghijklmnopqrstuvwxyz',
    fullName: 'Nhân viên A',
    role: 'staff'
  }
];

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Find user
    const user = users.find(u => u.username === username);
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Username không tồn tại' 
      });
    }
    
    // Check password (demo: so sánh trực tiếp)
    if (password !== '12345678') {
      return res.status(401).json({ 
        success: false, 
        message: 'Password không đúng' 
      });
    }
    
    // Generate token
    const token = jwt.sign(
      { 
        userId: user.id, 
        username: user.username, 
        role: user.role 
      },
      process.env.JWT_SECRET || 'secret-key-for-demo',
      { expiresIn: '24h' }
    );
    
    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          fullName: user.fullName,
          role: user.role
        }
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

module.exports = router;
```

**src/routes/customers.js:**
```javascript
const express = require('express');
const router = express.Router();

// Demo data
let customers = [
  {
    id: 1,
    customerCode: 'KH001',
    customerName: 'Nguyễn Văn A',
    address: '123 Đường ABC',
    phoneNumber: '0901234567',
    lastReading: 100.5,
    pricePerUnit: 15000
  },
  {
    id: 2,
    customerCode: 'KH002',
    customerName: 'Trần Thị B',
    address: '456 Đường XYZ',
    phoneNumber: '0912345678',
    lastReading: 85.3,
    pricePerUnit: 15000
  }
];

// GET /api/customers
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: customers
  });
});

// GET /api/customers/:id
router.get('/:id', (req, res) => {
  const customer = customers.find(c => c.id == req.params.id);
  if (!customer) {
    return res.status(404).json({ 
      success: false, 
      message: 'Không tìm thấy khách hàng' 
    });
  }
  res.json({
    success: true,
    data: customer
  });
});

module.exports = router;
```

**src/routes/sync.js:**
```javascript
const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();

// Setup multer cho upload ảnh
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueName + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png/;
    const isValid = allowedTypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    if (isValid) {
      cb(null, true);
    } else {
      cb(new Error('Chỉ chấp nhận file ảnh (jpg, jpeg, png)'));
    }
  }
});

// POST /api/sync/upload-image
router.post('/upload-image', upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'Không có file được upload' 
      });
    }
    
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    
    res.json({
      success: true,
      data: {
        imageUrl,
        filename: req.file.filename,
        size: req.file.size
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// POST /api/sync/reading
router.post('/reading', (req, res) => {
  try {
    const reading = req.body;
    
    console.log('Received reading:', reading);
    
    // Trong thực tế: Lưu vào database
    // const result = await db.query('INSERT INTO meter_readings ...');
    
    res.json({
      success: true,
      message: 'Đã lưu reading thành công',
      data: {
        id: Math.floor(Math.random() * 1000), // Demo ID
        ...reading
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// POST /api/sync/payment
router.post('/payment', (req, res) => {
  try {
    const payment = req.body;
    
    console.log('Received payment:', payment);
    
    res.json({
      success: true,
      message: 'Đã lưu payment thành công',
      data: {
        id: Math.floor(Math.random() * 1000),
        ...payment
      }
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

module.exports = router;
```

**.env:**
```env
PORT=3000
JWT_SECRET=my-secret-key-for-demo-only
DATABASE_URL=postgresql://user:password@localhost:5432/water_meter
NODE_ENV=development
```

**.gitignore:**
```
node_modules/
uploads/
.env
*.log
```

### Bước 4: Chạy backend local

```bash
# Tạo folder uploads
mkdir uploads

# Install dependencies
npm install

# Chạy server
npm run dev
```

**Kết quả:**
```
🚀 Server running on port 3000
📝 API Docs: http://localhost:3000/api/health
```

### Bước 5: Test API với Postman

**1. Health Check:**
```
GET http://localhost:3000/api/health
```

**2. Login:**
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "12345678"
}
```

**3. Get Customers:**
```
GET http://localhost:3000/api/customers
```

**4. Upload Image:**
```
POST http://localhost:3000/api/sync/upload-image
Content-Type: multipart/form-data

image: [Select file]
```

---

## 🌐 OPTION 2: DEPLOY LÊN RAILWAY (MIỄN PHÍ)

### Bước 1: Push code lên GitHub

```bash
git init
git add .
git commit -m "Initial backend"
git branch -M main
git remote add origin https://github.com/your-username/water-meter-backend.git
git push -u origin main
```

### Bước 2: Deploy trên Railway

1. Truy cập [railway.app](https://railway.app)
2. Click "Start a New Project"
3. Chọn "Deploy from GitHub repo"
4. Chọn repository vừa tạo
5. Railway tự động deploy

### Bước 3: Lấy URL

Sau khi deploy xong, Railway sẽ cho URL:
```
https://water-meter-backend-production.up.railway.app
```

### Bước 4: Update trong Flutter app

```dart
// lib/utils/constants.dart
class Constants {
  static const String API_BASE_URL = 'https://water-meter-backend-production.up.railway.app';
}
```

---

## 📦 OPTION 3: SỬ DỤNG MOCKAPI (NHANH NHẤT)

Không muốn code backend? Dùng MockAPI!

### Bước 1: Tạo MockAPI

1. Truy cập [mockapi.io](https://mockapi.io)
2. Đăng ký miễn phí
3. Tạo project "water-meter"
4. Tạo các endpoints:
   - `/customers`
   - `/readings`
   - `/payments`

### Bước 2: Sử dụng trong Flutter

```dart
// API URL
const API_URL = 'https://65abc123.mockapi.io/api';

// GET customers
final response = await http.get(Uri.parse('$API_URL/customers'));

// POST reading
final response = await http.post(
  Uri.parse('$API_URL/readings'),
  body: jsonEncode(reading),
);
```

**Ưu điểm:**
- ✅ Không cần code backend
- ✅ Setup trong 5 phút
- ✅ Miễn phí

**Nhược điểm:**
- ❌ Không upload được ảnh
- ❌ Không có authentication thật
- ❌ Giới hạn 100 requests/ngày

---

## 🗄️ DATABASE

### Option 1: In-Memory (Demo đơn giản)

Code đã có sẵn trong ví dụ trên - lưu trong biến JavaScript.

### Option 2: PostgreSQL trên Railway

1. Trong Railway project, click "New"
2. Chọn "Database" → "PostgreSQL"
3. Copy connection string
4. Update `.env`:
   ```env
   DATABASE_URL=postgresql://...
   ```

### Option 3: SQLite (File-based)

```bash
npm install sqlite3

# Update code để dùng SQLite
```

---

## 📸 UPLOAD ẢNH

### Option 1: Upload lên server (đã có code trên)

**Pros:**
- Đơn giản
- Kiểm soát hoàn toàn

**Cons:**
- Tốn storage server
- Không có CDN

### Option 2: Cloudinary (Đề xuất)

```bash
npm install cloudinary
```

```javascript
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Upload
router.post('/upload-image', upload.single('image'), async (req, res) => {
  const result = await cloudinary.uploader.upload(req.file.path);
  res.json({
    success: true,
    imageUrl: result.secure_url
  });
});
```

**Free tier:**
- 25 GB storage
- 25 GB bandwidth/month

---

## 🧪 TESTING

### Test với Postman

1. Import collection (tạo file `postman_collection.json`)
2. Set environment variables
3. Test từng endpoint

### Test với curl

```bash
# Health check
curl http://localhost:3000/api/health

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"12345678"}'

# Get customers
curl http://localhost:3000/api/customers
```

---

## 📚 TÀI LIỆU THAM KHẢO

- [Express.js Docs](https://expressjs.com)
- [Multer (File Upload)](https://github.com/expressjs/multer)
- [JWT Authentication](https://jwt.io)
- [Railway Docs](https://docs.railway.app)

---

## 🎯 CHECKLIST SETUP

- [ ] Install Node.js
- [ ] Create backend project
- [ ] Install dependencies
- [ ] Create routes & controllers
- [ ] Test API locally
- [ ] Push to GitHub
- [ ] Deploy to Railway
- [ ] Update Flutter app với API URL
- [ ] Test integration

---

**Tổng thời gian setup:** ~2-3 giờ

**Khuyên dùng:** Option 1 (Backend đơn giản) + Railway (Deploy) + Cloudinary (Ảnh)
