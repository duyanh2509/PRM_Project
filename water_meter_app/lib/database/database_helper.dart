import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

/// Helper class de quan ly SQLite database.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'water_meter_app.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT DEFAULT 'staff',
        areaCode TEXT NOT NULL,
        areaName TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerCode TEXT UNIQUE NOT NULL,
        customerName TEXT NOT NULL,
        address TEXT NOT NULL,
        phoneNumber TEXT,
        areaCode TEXT NOT NULL,
        areaName TEXT NOT NULL,
        lastReading REAL,
        lastReadingDate TEXT,
        pricePerUnit REAL NOT NULL DEFAULT 15000,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    await _seedDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createTables(db, newVersion);
    }
  }

  Future<void> _seedDemoData(Database db) async {
    final now = DateTime.now().toIso8601String();

    final demoUsers = <Map<String, Object?>>[
      {
        'username': 'staff01',
        'password': '12345678',
        'fullName': 'Nhan vien A',
        'role': 'staff',
        'areaCode': 'KV01',
        'areaName': 'Khu vuc 1',
        'createdAt': now,
      },
      {
        'username': 'staff02',
        'password': '12345678',
        'fullName': 'Nhan vien B',
        'role': 'staff',
        'areaCode': 'KV02',
        'areaName': 'Khu vuc 2',
        'createdAt': now,
      },
      {
        'username': 'staff03',
        'password': '12345678',
        'fullName': 'Nhan vien C',
        'role': 'staff',
        'areaCode': 'KV03',
        'areaName': 'Khu vuc 3',
        'createdAt': now,
      },
    ];

    for (final user in demoUsers) {
      await db.insert('users', user);
    }

    final demoCustomers = <Map<String, Object?>>[
      {
        'customerCode': 'KH001',
        'customerName': 'Nguyen Van An',
        'address': '12 Duong Hoa Sen, Phuong 1',
        'phoneNumber': '0901000001',
        'areaCode': 'KV01',
        'areaName': 'Khu vuc 1',
        'lastReading': 128.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH002',
        'customerName': 'Tran Thi Binh',
        'address': '34 Duong Le Loi, Phuong 2',
        'phoneNumber': '0901000002',
        'areaCode': 'KV01',
        'areaName': 'Khu vuc 1',
        'lastReading': 96.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH003',
        'customerName': 'Le Quoc Cuong',
        'address': '56 Duong Tran Phu, Phuong 3',
        'phoneNumber': '0901000003',
        'areaCode': 'KV01',
        'areaName': 'Khu vuc 1',
        'lastReading': 145.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH004',
        'customerName': 'Pham Thi Dung',
        'address': '78 Duong Nguyen Hue, Phuong 4',
        'phoneNumber': '0901000004',
        'areaCode': 'KV01',
        'areaName': 'Khu vuc 1',
        'lastReading': 88.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH005',
        'customerName': 'Vu Minh Duc',
        'address': '90 Duong Phan Dang Luu, Phuong 5',
        'phoneNumber': '0901000005',
        'areaCode': 'KV02',
        'areaName': 'Khu vuc 2',
        'lastReading': 174.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15500.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH006',
        'customerName': 'Bui Ngoc Ha',
        'address': '11 Duong Quang Trung, Phuong 6',
        'phoneNumber': '0901000006',
        'areaCode': 'KV02',
        'areaName': 'Khu vuc 2',
        'lastReading': 112.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH007',
        'customerName': 'Dang Gia Huy',
        'address': '25 Duong Cach Mang Thang 8, Phuong 7',
        'phoneNumber': '0901000007',
        'areaCode': 'KV02',
        'areaName': 'Khu vuc 2',
        'lastReading': 67.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH008',
        'customerName': 'Ho Thi Lan',
        'address': '39 Duong Hai Ba Trung, Phuong 8',
        'phoneNumber': '0901000008',
        'areaCode': 'KV02',
        'areaName': 'Khu vuc 2',
        'lastReading': 132.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15200.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH009',
        'customerName': 'Ngo Van Minh',
        'address': '47 Duong Ly Thuong Kiet, Phuong 9',
        'phoneNumber': '0901000009',
        'areaCode': 'KV03',
        'areaName': 'Khu vuc 3',
        'lastReading': 121.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH010',
        'customerName': 'Duong Thu Thao',
        'address': '63 Duong Hoang Hoa Tham, Phuong 10',
        'phoneNumber': '0901000010',
        'areaCode': 'KV03',
        'areaName': 'Khu vuc 3',
        'lastReading': 159.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15800.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH011',
        'customerName': 'Mai Cong Tan',
        'address': '71 Duong Pasteur, Phuong 11',
        'phoneNumber': '0901000011',
        'areaCode': 'KV03',
        'areaName': 'Khu vuc 3',
        'lastReading': 104.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'customerCode': 'KH012',
        'customerName': 'To Ngoc Yen',
        'address': '88 Duong Pham Ngu Lao, Phuong 12',
        'phoneNumber': '0901000012',
        'areaCode': 'KV03',
        'areaName': 'Khu vuc 3',
        'lastReading': 140.0,
        'lastReadingDate': '2026-05-01',
        'pricePerUnit': 15000.0,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (final customer in demoCustomers) {
      await db.insert('customers', customer);
    }
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (results.isEmpty) {
      return null;
    }

    return User.fromMap(results.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) {
      return null;
    }

    return User.fromMap(results.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final results = await db.query('users');
    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return db.query('customers', orderBy: 'customerCode ASC');
  }

  Future<List<Map<String, dynamic>>> getCustomersByArea(String areaCode) async {
    final db = await database;
    return db.query(
      'customers',
      where: 'areaCode = ?',
      whereArgs: [areaCode],
      orderBy: 'customerCode ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCustomersForUser(User user) async {
    return getCustomersByArea(user.areaCode);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
