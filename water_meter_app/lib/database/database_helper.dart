import 'dart:math' as math;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer_model.dart';
import '../models/meter_record_model.dart';
import '../models/user_model.dart';

/// ============================================================================
/// DATABASE HELPER - Quản lý SQLite local database
/// ============================================================================
///
/// MỤC ĐÍCH:
/// - Quản lý SQLite database local cho offline mode
/// - Tự động cập nhật công nợ khách hàng khi ghi số / thu tiền
/// - Lưu trữ user, customers, meter records, payment records
///
/// TABLES:
/// 1. users: Thông tin nhân viên đăng nhập
///    - id, username, password_hash, full_name, area_code, area_name
///
/// 2. customers: Thông tin khách hàng (hộ gia đình)
///    - id, customer_code, customer_name, address, phone_number
///    - area_code, area_name, last_reading, last_reading_date
///    - total_debt, debt_months, price_per_unit, last_payment_date, is_active
///
/// 3. reading_meter: Bản ghi ghi số + thu tiền (dùng chung)
///    - id, customer_code, customer_name, address, area_code, area_name
///    - record_type ('meter' hoặc 'payment')
///    - old_reading, new_reading, amount_collected
///    - sync_status ('pending' hoặc 'synced')
///    - recorded_at, collector_name, note, proof_image_path
///    - price_per_unit, billing_month, payment_method, payment_status, synced_at
///
/// HÀM QUAN TRỌNG:
///
/// USER:
/// - login(username, password): Đăng nhập local
/// - upsertUser(user): Lưu/cập nhật user
///
/// CUSTOMER:
/// - getCustomersForUser(user): Lấy danh sách khách hàng theo khu vực
/// - upsertCustomer(customer): Lưu/cập nhật customer
/// - getDownloadedCustomerCountForUser(user): Đếm số khách hàng đã tải
///
/// METER RECORD (GHI CHỈ SỐ):
/// - insertMeterRecord(record): Lưu bản ghi ghi số
///   → Tự động gọi _applyMeterEffectToLocalCustomer()
///   → UPDATE customers SET total_debt = total_debt + (tiền nước mới phát sinh)
///   → UPDATE customers SET last_reading, last_reading_date
///
/// - _applyMeterEffectToLocalCustomer(record, txn): [PRIVATE] Core logic
///   + Tính tiền nước: consumedUnits × pricePerUnit
///   + TĂNG totalDebt
///   + Cập nhật lastReading, lastReadingDate
///
/// PAYMENT RECORD (THU TIỀN):
/// - insertPaymentRecord(record): Lưu bản ghi thu tiền
///   → Tự động gọi _applyPaymentEffectToLocalCustomer()
///   → UPDATE customers SET total_debt = total_debt - amountCollected
///   → UPDATE customers SET last_payment_date
///
/// - _applyPaymentEffectToLocalCustomer(record, txn): [PRIVATE] Core logic
///   + GIẢM totalDebt
///   + Cập nhật lastPaymentDate
///
/// SYNC:
/// - getRecordsForUser(user, recordType): Lấy records theo loại
/// - countPendingRecordsForUser(user): Đếm records chưa sync
/// - markRecordAsSynced(recordId): Đánh dấu đã sync
/// - clearSyncedLocalCache(user): Xóa records đã sync (dọn cache)
///
/// STATISTICS:
/// - estimateCacheSizeMb(): Ước tính dung lượng cache
/// - getLastLocalSyncTimeForUser(user): Lấy thời gian sync cuối
///
/// PATTERN:
/// - Singleton pattern (DatabaseHelper.instance)
/// - Sử dụng Transaction cho data integrity
/// - Tự động tạo tables nếu chưa có
/// ============================================================================

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _databaseFilePath();

    return openDatabase(
      path,
      version: 9,
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
        role TEXT NOT NULL DEFAULT 'staff',
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
        totalDebt REAL NOT NULL DEFAULT 0,
        debtMonths INTEGER NOT NULL DEFAULT 0,
        lastPaymentDate TEXT,
        routeStatus TEXT NOT NULL DEFAULT 'uncollected',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meter_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerCode TEXT NOT NULL,
        recordType TEXT NOT NULL,
        oldReading REAL,
        newReading REAL,
        amountCollected REAL,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        recordedAt TEXT NOT NULL,
        collectorName TEXT,
        note TEXT,
        billingMonth TEXT,
        paymentMethod TEXT,
        paymentStatus TEXT,
        proofImagePath TEXT,
        syncedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE server_customers (
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
        totalDebt REAL NOT NULL DEFAULT 0,
        debtMonths INTEGER NOT NULL DEFAULT 0,
        lastPaymentDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE server_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerCode TEXT NOT NULL,
        recordType TEXT NOT NULL,
        oldReading REAL,
        newReading REAL,
        amountCollected REAL,
        syncStatus TEXT NOT NULL DEFAULT 'synced',
        recordedAt TEXT NOT NULL,
        collectorName TEXT,
        note TEXT,
        billingMonth TEXT,
        paymentMethod TEXT,
        paymentStatus TEXT,
        proofImagePath TEXT,
        syncedAt TEXT
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      await db.execute('DROP TABLE IF EXISTS server_records');
      await db.execute('DROP TABLE IF EXISTS server_customers');
      await db.execute('DROP TABLE IF EXISTS meter_records');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createTables(db, newVersion);
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    // Chỉ tạo tài khoản admin mặc định
    final users = <Map<String, Object?>>[
      {
        'username': 'admin',
        'password': 'admin123',
        'fullName': 'Administrator',
        'role': 'admin',
        'areaCode': 'ALL',
        'areaName': 'Tất cả khu vực',
        'createdAt': nowIso,
      },
    ];

    for (final user in users) {
      await db.insert('users', user);
    }

    // Không tạo demo data - data sẽ được tải từ Firebase
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (results.isEmpty) {
      return null;
    }
    return User.fromMap(results.first);
  }

  Future<void> upsertUser(User user) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username],
      limit: 1,
    );

    final data = user.toMap()..remove('id');

    if (existing.isEmpty) {
      await db.insert('users', data);
      return;
    }

    await db.update(
      'users',
      data,
      where: 'username = ?',
      whereArgs: [user.username],
    );
  }

  Future<List<Map<String, dynamic>>> getCustomersForUser(User user) async {
    final db = await database;
    if (user.role == 'admin') {
      return db.query('customers', orderBy: 'areaCode ASC, customerCode ASC');
    }

    return db.query(
      'customers',
      where: 'areaCode = ?',
      whereArgs: [user.areaCode],
      orderBy: 'customerCode ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecordsForUser(
    User user, {
    String? recordType,
  }) async {
    final db = await database;
    final whereParts = <String>[];
    final args = <Object?>[];

    if (user.role != 'admin') {
      whereParts.add('c.areaCode = ?');
      args.add(user.areaCode);
    }
    if (recordType != null) {
      whereParts.add('r.recordType = ?');
      args.add(recordType);
    }

    final whereClause = whereParts.isEmpty
        ? ''
        : 'WHERE ${whereParts.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        r.id,
        r.customerCode,
        r.recordType,
        r.oldReading,
        r.newReading,
        r.amountCollected,
        r.syncStatus,
        r.recordedAt,
        r.collectorName,
        r.note,
        r.billingMonth,
        r.paymentMethod,
        r.paymentStatus,
        r.proofImagePath,
        r.syncedAt,
        c.customerName,
        c.address,
        c.pricePerUnit,
        c.areaCode,
        c.areaName
      FROM meter_records r
      INNER JOIN customers c ON c.customerCode = r.customerCode
      $whereClause
      ORDER BY r.recordedAt DESC, r.id DESC
    ''', args);
  }

  Future<int> countPendingRecordsForUser(User user) async {
    final db = await database;

    if (user.role == 'admin') {
      final result = await db.rawQuery(
        "SELECT COUNT(*) AS total FROM meter_records WHERE syncStatus = 'pending'",
      );
      return _readCount(result.first['total']);
    }

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM meter_records r
      INNER JOIN customers c ON c.customerCode = r.customerCode
      WHERE c.areaCode = ? AND r.syncStatus = 'pending'
      ''',
      [user.areaCode],
    );
    return _readCount(result.first['total']);
  }

  Future<int> getDownloadedCustomerCountForUser(User user) async {
    final db = await database;
    if (user.role == 'admin') {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM customers',
      );
      return _readCount(result.first['total']);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM customers WHERE areaCode = ?',
      [user.areaCode],
    );
    return _readCount(result.first['total']);
  }

  Future<DateTime?> getLastLocalSyncTimeForUser(User user) async {
    final db = await database;
    final result = user.role == 'admin'
        ? await db.rawQuery(
            'SELECT MAX(syncedAt) AS latest FROM meter_records WHERE syncedAt IS NOT NULL',
          )
        : await db.rawQuery(
            '''
            SELECT MAX(r.syncedAt) AS latest
            FROM meter_records r
            INNER JOIN customers c ON c.customerCode = r.customerCode
            WHERE c.areaCode = ? AND r.syncedAt IS NOT NULL
            ''',
            [user.areaCode],
          );

    final raw = result.first['latest'] as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<int> downloadLatestRouteForUser(User user) async {
    final db = await database;

    return db.transaction((txn) async {
      final serverCustomers = user.role == 'admin'
          ? await txn.query(
              'server_customers',
              orderBy: 'areaCode ASC, customerCode ASC',
            )
          : await txn.query(
              'server_customers',
              where: 'areaCode = ?',
              whereArgs: [user.areaCode],
              orderBy: 'customerCode ASC',
            );

      if (user.role == 'admin') {
        await txn.delete('customers');
      } else {
        await txn.delete(
          'customers',
          where: 'areaCode = ?',
          whereArgs: [user.areaCode],
        );
      }

      for (final customer in serverCustomers) {
        final localCustomer = Map<String, Object?>.from(customer)
          ..remove('id')
          ..['routeStatus'] = 'uncollected';
        await txn.insert('customers', localCustomer);
      }

      if (user.role == 'admin') {
        await txn.rawDelete('''
          DELETE FROM meter_records
          WHERE syncStatus = 'synced'
          ''');
      } else {
        await txn.rawDelete(
          '''
          DELETE FROM meter_records
          WHERE syncStatus = 'synced'
            AND customerCode IN (
              SELECT customerCode FROM customers WHERE areaCode = ?
            )
          ''',
          [user.areaCode],
        );
      }

      final serverRecords = user.role == 'admin'
          ? await txn.query(
              'server_records',
              orderBy: 'recordedAt DESC, id DESC',
            )
          : await txn.rawQuery(
              '''
              SELECT r.*
              FROM server_records r
              INNER JOIN server_customers c ON c.customerCode = r.customerCode
              WHERE c.areaCode = ?
              ORDER BY r.recordedAt DESC, r.id DESC
              ''',
              [user.areaCode],
            );

      for (final record in serverRecords) {
        final map = Map<String, Object?>.from(record);
        map.remove('id');
        await txn.insert('meter_records', map);
      }

      return serverCustomers.length;
    });
  }

  Future<void> replaceServerCustomersForUser(
    User user,
    List<Map<String, Object?>> customers,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      if (user.role == 'admin') {
        await txn.delete('server_customers');
      } else {
        await txn.delete(
          'server_customers',
          where: 'areaCode = ?',
          whereArgs: [user.areaCode],
        );
      }

      for (final customer in customers) {
        final data = Map<String, Object?>.from(customer)..remove('id');
        await txn.insert('server_customers', data);
      }
    });
  }

  Future<void> replaceServerRecordsForUser(
    User user,
    List<Map<String, Object?>> records,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      if (user.role == 'admin') {
        await txn.delete('server_records');
      } else {
        await txn.rawDelete(
          '''
          DELETE FROM server_records
          WHERE customerCode IN (
            SELECT customerCode FROM server_customers WHERE areaCode = ?
          )
          ''',
          [user.areaCode],
        );
      }

      for (final record in records) {
        final data = Map<String, Object?>.from(record)
          ..remove('id')
          ..remove('areaCode')
          ..remove('areaName');
        await txn.insert('server_records', data);
      }
    });
  }

  Future<int> syncPendingRecordsToServer(User user) async {
    final db = await database;

    return db.transaction((txn) async {
      final pendingRecords = user.role == 'admin'
          ? await txn.query(
              'meter_records',
              where: 'syncStatus = ?',
              whereArgs: ['pending'],
              orderBy: 'recordedAt ASC, id ASC',
            )
          : await txn.rawQuery(
              '''
              SELECT r.*
              FROM meter_records r
              INNER JOIN customers c ON c.customerCode = r.customerCode
              WHERE c.areaCode = ? AND r.syncStatus = 'pending'
              ORDER BY r.recordedAt ASC, r.id ASC
              ''',
              [user.areaCode],
            );

      var syncedCount = 0;

      for (final rawRecord in pendingRecords) {
        final record = MeterRecord.fromMap(rawRecord);
        final exists = await _serverRecordExists(txn, record);
        final nowIso = DateTime.now().toIso8601String();

        if (!exists) {
          await txn.insert('server_records', {
            'customerCode': record.customerCode,
            'recordType': record.recordType,
            'oldReading': record.oldReading,
            'newReading': record.newReading,
            'amountCollected': record.amountCollected,
            'syncStatus': 'synced',
            'recordedAt': record.recordedAt.toIso8601String(),
            'collectorName': record.collectorName,
            'note': record.note,
            'billingMonth': record.billingMonth,
            'paymentMethod': record.paymentMethod,
            'paymentStatus': record.paymentStatus,
            'proofImagePath': record.proofImagePath,
            'syncedAt': nowIso,
          });

          if (record.recordType == 'meter') {
            await _applyMeterEffectToServerCustomer(txn, record);
          } else {
            await _applyPaymentEffectToServerCustomer(txn, record);
          }
        }

        await txn.update(
          'meter_records',
          {'syncStatus': 'synced', 'syncedAt': nowIso},
          where: 'id = ?',
          whereArgs: [record.id],
        );
        syncedCount++;
      }

      return syncedCount;
    });
  }

  Future<List<MeterRecord>> getPendingRecordsForUser(User user) async {
    final db = await database;
    final rows = user.role == 'admin'
        ? await db.rawQuery('''
            SELECT
              r.id,
              r.customerCode,
              r.recordType,
              r.oldReading,
              r.newReading,
              r.amountCollected,
              r.syncStatus,
              r.recordedAt,
              r.collectorName,
              r.note,
              r.billingMonth,
              r.paymentMethod,
              r.paymentStatus,
              r.proofImagePath,
              r.syncedAt,
              c.customerName,
              c.address,
              c.pricePerUnit,
              c.areaCode,
              c.areaName
            FROM meter_records r
            INNER JOIN customers c ON c.customerCode = r.customerCode
            WHERE r.syncStatus = 'pending'
            ORDER BY r.recordedAt ASC, r.id ASC
            ''')
        : await db.rawQuery(
            '''
            SELECT
              r.id,
              r.customerCode,
              r.recordType,
              r.oldReading,
              r.newReading,
              r.amountCollected,
              r.syncStatus,
              r.recordedAt,
              r.collectorName,
              r.note,
              r.billingMonth,
              r.paymentMethod,
              r.paymentStatus,
              r.proofImagePath,
              r.syncedAt,
              c.customerName,
              c.address,
              c.pricePerUnit,
              c.areaCode,
              c.areaName
            FROM meter_records r
            INNER JOIN customers c ON c.customerCode = r.customerCode
            WHERE c.areaCode = ? AND r.syncStatus = 'pending'
            ORDER BY r.recordedAt ASC, r.id ASC
            ''',
            [user.areaCode],
          );

    return rows.map(MeterRecord.fromMap).toList();
  }

  Future<List<MeterRecord>> getRecordsWithLocalProofImagesForUser(
    User user,
  ) async {
    final records = <MeterRecord>[];
    final meterRows = await getRecordsForUser(user, recordType: 'meter');
    final paymentRows = await getRecordsForUser(user, recordType: 'payment');

    for (final row in [...meterRows, ...paymentRows]) {
      final record = MeterRecord.fromMap(row);
      final proofImagePath = record.proofImagePath?.trim() ?? '';
      if (proofImagePath.isEmpty ||
          proofImagePath.startsWith('http://') ||
          proofImagePath.startsWith('https://')) {
        continue;
      }
      records.add(record);
    }

    return records;
  }

  Future<void> updateRecordProofImagePath(
    MeterRecord record,
    String? proofImagePath,
  ) async {
    if (record.id == null) {
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'meter_records',
        {'proofImagePath': proofImagePath},
        where: 'id = ?',
        whereArgs: [record.id],
      );

      await txn.update(
        'server_records',
        {'proofImagePath': proofImagePath},
        where: '''
          customerCode = ?
          AND recordType = ?
          AND recordedAt = ?
          AND IFNULL(amountCollected, -1) = IFNULL(?, -1)
          AND IFNULL(newReading, -1) = IFNULL(?, -1)
        ''',
        whereArgs: [
          record.customerCode,
          record.recordType,
          record.recordedAt.toIso8601String(),
          record.amountCollected,
          record.newReading,
        ],
      );
    });
  }

  Future<void> markRecordSynced(
    MeterRecord record, {
    required DateTime syncedAt,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final nowIso = syncedAt.toIso8601String();
      final exists = await _serverRecordExists(txn, record);

      if (!exists) {
        await txn.insert('server_records', {
          'customerCode': record.customerCode,
          'recordType': record.recordType,
          'oldReading': record.oldReading,
          'newReading': record.newReading,
          'amountCollected': record.amountCollected,
          'syncStatus': 'synced',
          'recordedAt': record.recordedAt.toIso8601String(),
          'collectorName': record.collectorName,
          'note': record.note,
          'billingMonth': record.billingMonth,
          'paymentMethod': record.paymentMethod,
          'paymentStatus': record.paymentStatus,
          'proofImagePath': record.proofImagePath,
          'syncedAt': nowIso,
        });

        if (record.recordType == 'meter') {
          await _applyMeterEffectToServerCustomer(txn, record);
        } else {
          await _applyPaymentEffectToServerCustomer(txn, record);
        }
      }

      await txn.update(
        'meter_records',
        {
          'syncStatus': 'synced',
          'proofImagePath': record.proofImagePath,
          'syncedAt': nowIso,
        },
        where: 'id = ?',
        whereArgs: [record.id],
      );
    });
  }

  Future<int> insertMeterRecord(MeterRecord record) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert(
        'meter_records',
        record.toDatabaseMap()..remove('id'),
      );
      await _applyMeterEffectToLocalCustomer(txn, record);
      return id;
    });
  }

  Future<int> insertPaymentRecord(MeterRecord record) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert(
        'meter_records',
        record.toDatabaseMap()..remove('id'),
      );
      await _applyPaymentEffectToLocalCustomer(txn, record);
      return id;
    });
  }

  Future<int> estimateCacheSizeMb() async {
    final db = await database;
    final customerCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    final recordCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meter_records'),
        ) ??
        0;
    return math.max(8, ((customerCount * 2) + recordCount).clamp(8, 128));
  }

  Future<void> clearSyncedLocalCache(User user) async {
    final db = await database;
    await db.transaction((txn) async {
      if (user.role == 'admin') {
        await txn.delete(
          'meter_records',
          where: 'syncStatus = ?',
          whereArgs: ['synced'],
        );
      } else {
        await txn.rawDelete(
          '''
          DELETE FROM meter_records
          WHERE syncStatus = 'synced'
            AND customerCode IN (
              SELECT customerCode FROM customers WHERE areaCode = ?
            )
          ''',
          [user.areaCode],
        );
      }
    });
  }

  Future<void> close() async {
    if (_database == null) {
      return;
    }
    await _database!.close();
    _database = null;
  }

  Future<void> _applyMeterEffectToLocalCustomer(
    Transaction txn,
    MeterRecord record,
  ) async {
    final customer = await _getCustomer(txn, 'customers', record.customerCode);
    if (customer == null) {
      return;
    }

    final consumed = math.max(
      0,
      (record.newReading ?? customer.lastReading ?? 0) -
          (record.oldReading ?? customer.lastReading ?? 0),
    );
    final billAmount = consumed * customer.pricePerUnit;
    await txn.update(
      'customers',
      {
        'lastReading': record.newReading ?? customer.lastReading,
        'lastReadingDate': record.recordedAt.toIso8601String(),
        'totalDebt': customer.totalDebt + billAmount,
        'debtMonths': customer.debtMonths + (billAmount > 0 ? 1 : 0),
        'routeStatus': 'reading_done',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'customerCode = ?',
      whereArgs: [record.customerCode],
    );
  }

  Future<void> _applyPaymentEffectToLocalCustomer(
    Transaction txn,
    MeterRecord record,
  ) async {
    final customer = await _getCustomer(txn, 'customers', record.customerCode);
    if (customer == null) {
      return;
    }

    final remaining = math.max(
      0,
      customer.totalDebt - (record.amountCollected ?? 0),
    );
    await txn.update(
      'customers',
      {
        'totalDebt': remaining,
        'debtMonths': remaining <= 0 ? 0 : customer.debtMonths,
        'lastPaymentDate': record.recordedAt.toIso8601String(),
        'routeStatus': remaining <= 0 ? 'collected' : 'partial',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'customerCode = ?',
      whereArgs: [record.customerCode],
    );
  }

  Future<void> _applyMeterEffectToServerCustomer(
    Transaction txn,
    MeterRecord record,
  ) async {
    final customer = await _getCustomer(
      txn,
      'server_customers',
      record.customerCode,
    );
    if (customer == null) {
      return;
    }

    final consumed = math.max(
      0,
      (record.newReading ?? customer.lastReading ?? 0) -
          (record.oldReading ?? customer.lastReading ?? 0),
    );
    final billAmount = consumed * customer.pricePerUnit;
    await txn.update(
      'server_customers',
      {
        'lastReading': record.newReading ?? customer.lastReading,
        'lastReadingDate': record.recordedAt.toIso8601String(),
        'totalDebt': customer.totalDebt + billAmount,
        'debtMonths': customer.debtMonths + (billAmount > 0 ? 1 : 0),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'customerCode = ?',
      whereArgs: [record.customerCode],
    );
  }

  Future<void> _applyPaymentEffectToServerCustomer(
    Transaction txn,
    MeterRecord record,
  ) async {
    final customer = await _getCustomer(
      txn,
      'server_customers',
      record.customerCode,
    );
    if (customer == null) {
      return;
    }

    final remaining = math.max(
      0,
      customer.totalDebt - (record.amountCollected ?? 0),
    );
    await txn.update(
      'server_customers',
      {
        'totalDebt': remaining,
        'debtMonths': remaining <= 0 ? 0 : customer.debtMonths,
        'lastPaymentDate': record.recordedAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'customerCode = ?',
      whereArgs: [record.customerCode],
    );
  }

  Future<Customer?> _getCustomer(
    Transaction txn,
    String table,
    String customerCode,
  ) async {
    final result = await txn.query(
      table,
      where: 'customerCode = ?',
      whereArgs: [customerCode],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return Customer.fromMap(result.first);
  }

  Future<bool> _serverRecordExists(Transaction txn, MeterRecord record) async {
    final result = await txn.query(
      'server_records',
      where: '''
        customerCode = ?
        AND recordType = ?
        AND recordedAt = ?
        AND IFNULL(amountCollected, -1) = IFNULL(?, -1)
        AND IFNULL(newReading, -1) = IFNULL(?, -1)
      ''',
      whereArgs: [
        record.customerCode,
        record.recordType,
        record.recordedAt.toIso8601String(),
        record.amountCollected,
        record.newReading,
      ],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  int _readCount(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<String> _databaseFilePath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, 'water_meter_app.db');
  }
}
