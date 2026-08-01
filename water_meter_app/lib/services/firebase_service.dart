// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/meter_record_model.dart';
import '../models/user_model.dart';

/// ============================================================================
/// FIREBASE SERVICE - Tương tác với Firestore & Cloudinary
/// ============================================================================
/// FIRESTORE COLLECTIONS:
/// - staff: Thông tin nhân viên (login)
/// - customers: Danh sách khách hàng
/// - reading_meter: Bản ghi ghi chỉ số
/// - payments: Bản ghi thu tiền
///
/// METHODS:
/// - authenticateStaff(username, password): Query staff collection để verify login
///   + Return User object nếu tìm thấy
///
/// - downloadCustomers(areaCode): Query customers theo khu vực
///   + Return List<Map> customers
///
/// - syncRecord(record): Upload record lên Firestore
///   + Nếu có proofImagePath → upload lên Cloudinary → lấy public URL
///   + Lưu vào collection 'reading_meter' hoặc 'payments'
///   + _applyMeterReadingToCustomer() / _applyPaymentToCustomer(): Update customer trên Firestore
///
/// HELPER:
/// - _uploadToCloudinary(file): Upload ảnh lên Cloudinary → return public URL
/// - _resolveProofImagePath(path): Xử lý inline image / local file / remote URL
/// ============================================================================

import 'cloudinary_service.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();

  factory FirebaseService() => instance;

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  String? _lastImageUploadError;

  Future<void> ensureFirebaseSignedIn() async {
    if (_auth.currentUser != null) {
      return;
    }

    await _auth.signInAnonymously();
  }

  Future<Map<String, dynamic>?> getStaffByUsername(String username) async {
    try {
      await ensureFirebaseSignedIn();
      final normalizedUsername = _normalizeText(username);
      final snapshot = await _firestore
          .collection('staff')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
      }

      final allSnapshot = await _firestore.collection('staff').get();
      for (final doc in allSnapshot.docs) {
        if (_normalizeText(doc.data()['username']) == normalizedUsername) {
          return {'id': doc.id, ...doc.data()};
        }
      }

      return null;
    } catch (e) {
      print('Error getting staff: $e');
      return null;
    }
  }

  Future<User?> authenticateStaff(String username, String password) async {
    final staff = await getStaffByUsername(username);
    if (staff == null) {
      return null;
    }

    final storedPassword = _stringValue(
      staff['password'],
      fallback: _stringValue(staff['passwordHash']),
    );
    if (storedPassword.isEmpty || storedPassword != password) {
      return null;
    }

    return User(
      username: _stringValue(staff['username'], fallback: username),
      password: storedPassword,
      fullName: _stringValue(
        staff['fullName'],
        fallback: _stringValue(staff['name'], fallback: username),
      ),
      role: _stringValue(staff['role'], fallback: 'staff'),
      areaCode: _stringValue(staff['areaCode'], fallback: 'ALL'),
      areaName: _stringValue(staff['areaName'], fallback: 'Tat ca khu vuc'),
      createdAt: _parseDateTime(staff['createdAt']),
    );
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      await ensureFirebaseSignedIn();
      final snapshot = await _firestore.collection('staff').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting all staff: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> downloadCustomers(String areaCode) async {
    try {
      await ensureFirebaseSignedIn();
      final normalizedAreaCode = _normalizeText(areaCode);

      final directSnapshot = await _firestore
          .collection('customers')
          .where('areaCode', isEqualTo: areaCode)
          .get();

      final directMatches = directSnapshot.docs
          .map((doc) => _mapCustomerDocument(doc.data(), documentId: doc.id))
          .toList();
      if (directMatches.isNotEmpty) {
        return directMatches;
      }

      final allCustomers = await downloadAllCustomers();
      return allCustomers.where((customer) {
        final customerAreaCode = _normalizeText(customer['areaCode']);
        final customerCode = _normalizeText(customer['customerCode']);
        return customerAreaCode == normalizedAreaCode ||
            customerCode.startsWith(normalizedAreaCode);
      }).toList();
    } catch (e) {
      print('Error downloading customers: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> downloadAllCustomers() async {
    try {
      await ensureFirebaseSignedIn();
      final snapshot = await _firestore.collection('customers').get();
      return snapshot.docs
          .map((doc) => _mapCustomerDocument(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      print('Error downloading all customers: $e');
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> downloadRecords({String? areaCode}) async {
    try {
      await ensureFirebaseSignedIn();
      final meterSnapshot = await _firestore.collection('meter_readings').get();
      final legacyMeterSnapshot = await _firestore
          .collection('reading_meter')
          .get();
      final paymentSnapshot = await _firestore.collection('payments').get();

      final recordsByKey = <String, Map<String, Object?>>{};
      void addRecord(String collection, QueryDocumentSnapshot doc) {
        final mapped = _mapRecordDocument(
          doc.data() as Map<String, dynamic>,
          documentId: doc.id,
          collection: collection,
        );
        final key = _recordDedupKey(mapped);
        recordsByKey.putIfAbsent(key, () => mapped);
      }

      for (final doc in meterSnapshot.docs) {
        addRecord('meter_readings', doc);
      }
      for (final doc in legacyMeterSnapshot.docs) {
        addRecord('reading_meter', doc);
      }
      for (final doc in paymentSnapshot.docs) {
        addRecord('payments', doc);
      }

      final records = recordsByKey.values.toList();

      if (areaCode == null || areaCode == 'ALL') {
        records.sort(_compareRecordMaps);
        return records;
      }

      final filtered = records.where((record) {
        final recordAreaCode = _normalizeText(record['areaCode']);
        return recordAreaCode.isEmpty ||
            recordAreaCode == _normalizeText(areaCode);
      }).toList()..sort(_compareRecordMaps);
      return filtered;
    } catch (e) {
      print('Error downloading records: $e');
      rethrow;
    }
  }

  Future<String?> uploadCustomer(Map<String, dynamic> customer) async {
    try {
      await ensureFirebaseSignedIn();
      final docRef = await _firestore.collection('customers').add({
        ...customer,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Customer uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error uploading customer: $e');
      return null;
    }
  }

  Future<bool> updateCustomer(
    String customerCode,
    Map<String, dynamic> updates,
  ) async {
    try {
      await ensureFirebaseSignedIn();
      final snapshot = await _firestore
          .collection('customers')
          .where('customerCode', isEqualTo: customerCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      await snapshot.docs.first.reference.update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Customer updated: $customerCode');
      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  Future<String?> uploadMeterReading(Map<String, dynamic> reading) async {
    try {
      await ensureFirebaseSignedIn();
      final docRef = await _firestore.collection('meter_readings').add({
        ...reading,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      print('Meter reading uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error uploading reading: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> downloadMeterReadings(
    String customerCode,
  ) async {
    try {
      await ensureFirebaseSignedIn();
      final snapshot = await _firestore
          .collection('meter_readings')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error downloading readings: $e');
      return [];
    }
  }

  Future<String?> uploadPayment(Map<String, dynamic> payment) async {
    try {
      await ensureFirebaseSignedIn();
      final docRef = await _firestore.collection('payments').add({
        ...payment,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      print('Payment uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error uploading payment: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> downloadPayments(
    String customerCode,
  ) async {
    try {
      await ensureFirebaseSignedIn();
      final snapshot = await _firestore
          .collection('payments')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error downloading payments: $e');
      return [];
    }
  }

  Future<String?> uploadMeterImage(File imageFile, String customerCode) async {
    try {
      _lastImageUploadError = null;

      // Check file size before uploading to Cloudinary.
      final fileSize = await imageFile.length();
      const maxSize = 15 * 1024 * 1024; // 15MB
      if (fileSize > maxSize) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        _lastImageUploadError =
            'Kich thuoc anh qua lon: ${sizeMB}MB. '
            'Vui long chon anh nho hon 15MB.';
        print(_lastImageUploadError);
        return null;
      }

      // Upload to Cloudinary and keep the returned public URL.
      final url = await CloudinaryService.instance.uploadMeterImage(
        imageFile,
        customerCode,
      );

      if (url == null) {
        _lastImageUploadError = 'Khong the upload anh len Cloudinary';
        print(_lastImageUploadError);
        return null;
      }

      return url;
    } catch (e) {
      _lastImageUploadError = 'Error uploading image: $e';
      print(_lastImageUploadError);
      return null;
    }
  }

  Future<String?> uploadMeterImageBytes(
    Uint8List bytes,
    String customerCode, {
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    try {
      _lastImageUploadError = null;

      // Upload inline image bytes to Cloudinary and keep the returned public URL.
      final url = await CloudinaryService.instance.uploadMeterImageBytes(
        bytes,
        customerCode,
      );

      if (url == null) {
        _lastImageUploadError = 'Khong the upload anh bytes len Cloudinary';
        print(_lastImageUploadError);
        return null;
      }

      return url;
    } catch (e) {
      _lastImageUploadError = 'Error uploading inline image: $e';
      print(_lastImageUploadError);
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      return CloudinaryService.instance.deleteImage(imageUrl);
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      await ensureFirebaseSignedIn();
      await _firestore
          .collection('staff')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      print('Firebase connected');
      return true;
    } catch (e) {
      print('Firebase connection failed: $e');
      return false;
    }
  }

  Future<DateTime?> getServerTime() async {
    try {
      await ensureFirebaseSignedIn();
      final docRef = _firestore.collection('_system').doc('timestamp');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      final snapshot = await docRef.get();
      final timestamp = snapshot.data()?['timestamp'] as Timestamp?;

      await docRef.delete();
      return timestamp?.toDate();
    } catch (e) {
      print('Error getting server time: $e');
      return null;
    }
  }

  Future<MeterRecord> syncRecord(MeterRecord record) async {
    await ensureFirebaseSignedIn();
    final imageResult = await _resolveProofImagePath(record);
    final syncedRecord = record.copyWith(
      proofImagePath: imageResult.proofImagePath,
    );

    if (record.recordType == 'payment') {
      final upsertResult = await _upsertPayment(syncedRecord);
      if (upsertResult.shouldApplyToCustomer) {
        await _applyPaymentToCustomer(syncedRecord);
        await upsertResult.reference.set({
          'customerApplied': true,
        }, SetOptions(merge: true));
      }
    } else {
      final upsertResult = await _upsertMeterReading(syncedRecord);
      if (upsertResult.shouldApplyToCustomer) {
        await _applyMeterReadingToCustomer(
          syncedRecord,
          startsNewDebtMonth: upsertResult.startsNewDebtMonth,
        );
        await upsertResult.reference.set({
          'customerApplied': true,
        }, SetOptions(merge: true));
      }
    }

    return syncedRecord;
  }

  Future<String?> uploadAndUpdateRecordProofImage(MeterRecord record) async {
    await ensureFirebaseSignedIn();
    final imageResult = await _resolveProofImagePath(record);
    if (imageResult.proofImagePath == null ||
        !_isRemoteImagePath(imageResult.proofImagePath!)) {
      return null;
    }

    final collection = record.recordType == 'payment'
        ? 'payments'
        : 'meter_readings';
    await _firestore.collection(collection).doc(_buildRecordId(record)).set({
      'proofImagePath': imageResult.proofImagePath,
      'proofImageUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return imageResult.proofImagePath;
  }

  Future<_ProofImageSyncResult> _resolveProofImagePath(
    MeterRecord record,
  ) async {
    final rawPath = record.proofImagePath;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return const _ProofImageSyncResult();
    }

    // Nếu đã là URL công khai, giữ nguyên
    if (_isRemoteImagePath(rawPath)) {
      return _ProofImageSyncResult(proofImagePath: rawPath);
    }

    // Neu la inline base64, upload len Cloudinary de lay URL cong khai.
    if (rawPath.toLowerCase().startsWith('data:image/')) {
      final downloadUrl = await _uploadInlineProofImage(
        rawPath,
        record.customerCode,
      );
      if (downloadUrl == null || downloadUrl.trim().isEmpty) {
        // Không throw exception, chỉ log warning và bỏ qua ảnh
        print(
          'WARNING: Khong the chuyen anh base64 thanh URL cho ${record.customerCode}',
        );
        return _ProofImageSyncResult(proofImagePath: rawPath);
      }
      return _ProofImageSyncResult(proofImagePath: downloadUrl);
    }

    // Neu la local file path, upload len Cloudinary de lay URL cong khai.
    final file = File(rawPath);
    if (!await file.exists()) {
      print('WARNING: File khong ton tai: $rawPath');
      return _ProofImageSyncResult(proofImagePath: rawPath);
    }

    // Upload len Cloudinary.
    final downloadUrl = await uploadMeterImage(file, record.customerCode);
    if (downloadUrl == null || downloadUrl.trim().isEmpty) {
      // Không throw exception, chỉ log warning
      print(
        'WARNING: Khong the upload anh len Cloudinary cho ${record.customerCode}. '
        'Tiep tuc sync cac record khac.',
      );
      return _ProofImageSyncResult(proofImagePath: rawPath);
    }
    return _ProofImageSyncResult(proofImagePath: downloadUrl);
  }

  Future<String?> _uploadInlineProofImage(
    String dataUrl,
    String customerCode,
  ) async {
    try {
      final match = RegExp(
        r'^data:([^;]+);base64,(.+)$',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(dataUrl.trim());
      if (match == null) {
        return null;
      }

      final contentType = match.group(1) ?? 'image/jpeg';
      final encoded = match.group(2)?.replaceAll(RegExp(r'\s'), '') ?? '';
      final extension = switch (contentType.toLowerCase()) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };

      return uploadMeterImageBytes(
        base64Decode(encoded),
        customerCode,
        contentType: contentType,
        extension: extension,
      );
    } catch (e) {
      print('Error converting inline image to upload: $e');
      return null;
    }
  }

  Future<_RecordUpsertResult> _upsertMeterReading(MeterRecord record) async {
    final docRef = _firestore
        .collection('meter_readings')
        .doc(_buildRecordId(record));
    final snapshot = await docRef.get();
    final startsNewDebtMonth = !await _hasRemoteMeterRecordForBillingMonth(
      record,
      excludingDocId: docRef.id,
    );
    await docRef.set(_recordPayload(record), SetOptions(merge: true));
    final customerApplied = snapshot.data()?['customerApplied'] == true;
    return _RecordUpsertResult(
      reference: docRef,
      shouldApplyToCustomer: !customerApplied,
      startsNewDebtMonth: startsNewDebtMonth,
    );
  }

  Future<_RecordUpsertResult> _upsertPayment(MeterRecord record) async {
    final docRef = _firestore
        .collection('payments')
        .doc(_buildRecordId(record));
    final snapshot = await docRef.get();
    await docRef.set(_recordPayload(record), SetOptions(merge: true));
    final customerApplied = snapshot.data()?['customerApplied'] == true;
    return _RecordUpsertResult(
      reference: docRef,
      shouldApplyToCustomer: !customerApplied,
      startsNewDebtMonth: false,
    );
  }

  Future<void> _applyMeterReadingToCustomer(
    MeterRecord record, {
    required bool startsNewDebtMonth,
  }) async {
    final docRef = await _findOrCreateCustomerDoc(record);

    final snapshot = await docRef.get();
    final currentData = snapshot.data() ?? const <String, dynamic>{};
    final pricePerUnit =
        _toDouble(currentData['pricePerUnit']) ?? record.pricePerUnit;
    final oldReading =
        record.oldReading ?? _toDouble(currentData['lastReading']) ?? 0;
    final newReading = record.newReading ?? oldReading;
    final consumed = math.max(0, newReading - oldReading);
    final billAmount = consumed * pricePerUnit;
    final currentDebt = _toDouble(currentData['totalDebt']) ?? 0;
    final currentDebtMonths = _toInt(currentData['debtMonths']) ?? 0;

    await docRef.set({
      'lastReading': newReading,
      'lastReadingDate': Timestamp.fromDate(record.recordedAt),
      'totalDebt': currentDebt + billAmount,
      'debtMonths':
          currentDebtMonths + (billAmount > 0 && startsNewDebtMonth ? 1 : 0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _applyPaymentToCustomer(MeterRecord record) async {
    final docRef = await _findOrCreateCustomerDoc(record);

    final snapshot = await docRef.get();
    final currentData = snapshot.data() ?? const <String, dynamic>{};
    final currentDebt = _toDouble(currentData['totalDebt']) ?? 0;
    final currentDebtMonths = _toInt(currentData['debtMonths']) ?? 0;
    final appliedAmount = math.min(record.amountCollected ?? 0, currentDebt);
    final remaining = math.max(0, currentDebt - appliedAmount);

    await docRef.set({
      'totalDebt': remaining,
      'debtMonths': remaining <= 0 ? 0 : currentDebtMonths,
      'lastPaymentDate': Timestamp.fromDate(record.recordedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentReference<Map<String, dynamic>>> _findOrCreateCustomerDoc(
    MeterRecord record,
  ) async {
    final existing = await _findCustomerDoc(record.customerCode);
    if (existing != null) {
      return existing;
    }

    final docRef = _firestore.collection('customers').doc(record.customerCode);
    await docRef.set({
      'customerCode': record.customerCode,
      'customerName': record.customerName,
      'address': record.address,
      'areaCode': record.areaCode,
      'areaName': record.areaName,
      'lastReading': record.oldReading ?? record.newReading ?? 0,
      'lastReadingDate': Timestamp.fromDate(record.recordedAt),
      'pricePerUnit': record.pricePerUnit <= 0 ? 15000 : record.pricePerUnit,
      'totalDebt': record.recordType == 'payment'
          ? (record.amountCollected ?? 0)
          : 0,
      'debtMonths': record.recordType == 'payment' ? 1 : 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return docRef;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findCustomerDoc(
    String customerCode,
  ) async {
    final snapshot = await _firestore
        .collection('customers')
        .where('customerCode', isEqualTo: customerCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.reference;
  }

  String _buildRecordId(MeterRecord record) {
    final timestamp = record.recordedAt.toUtc().millisecondsSinceEpoch;
    return '${record.recordType}_${record.customerCode}_$timestamp';
  }

  Map<String, Object?> _recordPayload(MeterRecord record) {
    return {
      'customerCode': record.customerCode,
      'customerName': record.customerName,
      'address': record.address,
      'areaCode': record.areaCode,
      'areaName': record.areaName,
      'recordType': record.recordType,
      'oldReading': record.oldReading,
      'newReading': record.newReading,
      'amountCollected': record.amountCollected,
      'pricePerUnit': record.pricePerUnit,
      'collectorName': record.collectorName,
      'note': record.note,
      'billingMonth': _billingMonthFor(record),
      'paymentMethod': record.paymentMethod,
      'paymentStatus': record.paymentStatus,
      'proofImagePath': _remoteProofImagePath(record.proofImagePath),
      'recordedAt': Timestamp.fromDate(record.recordedAt),
      'uploadedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String? _remoteProofImagePath(String? proofImagePath) {
    final value = proofImagePath?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (_isRemoteImagePath(value)) {
      return value;
    }

    return null;
  }

  String _billingMonthFor(MeterRecord record) {
    final value = record.billingMonth?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return '${record.recordedAt.year}-${record.recordedAt.month.toString().padLeft(2, '0')}';
  }

  Future<bool> _hasRemoteMeterRecordForBillingMonth(
    MeterRecord record, {
    required String excludingDocId,
  }) async {
    final snapshot = await _firestore
        .collection('meter_readings')
        .where('customerCode', isEqualTo: record.customerCode)
        .where('recordType', isEqualTo: 'meter')
        .where('billingMonth', isEqualTo: _billingMonthFor(record))
        .limit(5)
        .get();

    return snapshot.docs.any((doc) => doc.id != excludingDocId);
  }

  bool _isRemoteImagePath(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Map<String, Object?> _mapRecordDocument(
    Map<String, dynamic> data, {
    required String documentId,
    required String collection,
  }) {
    final recordedAt =
        _parseDateTime(
          _readField(data, const [
            'recordedAt',
            'recorded_at',
            'createdAt',
            'created_at',
          ]),
        ) ??
        DateTime.now();
    final uploadedAt = _parseDateTime(
      _readField(data, const [
        'uploadedAt',
        'uploaded_at',
        'syncedAt',
        'synced_at',
      ]),
    );

    return {
      'customerCode': _stringValue(
        _readField(data, const ['customerCode', 'customer_code', 'code']),
      ),
      'recordType': _normalizeRecordType(
        _readField(data, const ['recordType', 'record_type', 'type']),
        collection,
      ),
      'oldReading': _toDouble(
        _readField(data, const [
          'oldReading',
          'old_reading',
          'previousReading',
        ]),
      ),
      'newReading': _toDouble(
        _readField(data, const ['newReading', 'new_reading', 'currentReading']),
      ),
      'amountCollected': _toDouble(
        _readField(data, const [
          'amountCollected',
          'amount_collected',
          'amount',
          'paidAmount',
        ]),
      ),
      'syncStatus': 'synced',
      'recordedAt': recordedAt.toIso8601String(),
      'collectorName': _nullableStringValue(
        _readField(data, const [
          'collectorName',
          'collector_name',
          'staffName',
        ]),
      ),
      'note': _nullableStringValue(_readField(data, const ['note', 'notes'])),
      'billingMonth': _nullableStringValue(
        _readField(data, const ['billingMonth', 'billing_month']),
      ),
      'paymentMethod': _nullableStringValue(
        _readField(data, const ['paymentMethod', 'payment_method']),
      ),
      'paymentStatus': _nullableStringValue(
        _readField(data, const ['paymentStatus', 'payment_status']),
      ),
      'proofImagePath': _nullableStringValue(
        _readField(data, const [
          'proofImagePath',
          'proof_image_path',
          'imageUrl',
          'image_url',
        ]),
      ),
      'syncedAt': uploadedAt?.toIso8601String(),
      'areaCode': _stringValue(
        _readField(data, const ['areaCode', 'area_code']),
      ),
      'areaName': _stringValue(
        _readField(data, const ['areaName', 'area_name']),
      ),
      'remoteDocumentId': documentId,
      'remoteCollection': collection,
    };
  }

  String _recordDedupKey(Map<String, Object?> record) {
    return [
      _stringValue(record['recordType']),
      _normalizeText(record['customerCode']),
      _stringValue(record['recordedAt']),
      _stringValue(record['newReading']),
      _stringValue(record['amountCollected']),
    ].join('|');
  }

  int _compareRecordMaps(Map<String, Object?> a, Map<String, Object?> b) {
    final aDate =
        DateTime.tryParse(_stringValue(a['recordedAt'])) ?? DateTime.now();
    final bDate =
        DateTime.tryParse(_stringValue(b['recordedAt'])) ?? DateTime.now();
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) {
      return byDate;
    }
    return _stringValue(
      a['customerCode'],
    ).compareTo(_stringValue(b['customerCode']));
  }

  Map<String, Object?> _mapCustomerDocument(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final createdAt =
        _parseDateTime(_readField(data, const ['createdAt', 'created_at'])) ??
        DateTime.now();
    final billing = data['billing'];

    return {
      'customerCode': _stringValue(
        _readField(data, const ['customerCode', 'customer_code', 'code']),
        fallback: documentId,
      ),
      'customerName': _stringValue(
        _readField(data, const ['customerName', 'customer_name', 'name']),
      ),
      'address': _stringValue(_readField(data, const ['address', 'diaChi'])),
      'phoneNumber': _nullableStringValue(
        _readField(data, const ['phoneNumber', 'phone_number', 'phone']),
      ),
      'areaCode': _stringValue(
        _readField(data, const ['areaCode', 'area_code']),
        fallback: 'ALL',
      ),
      'areaName': _stringValue(
        _readField(data, const ['areaName', 'area_name']),
        fallback: 'Tat ca khu vuc',
      ),
      'lastReading': _toDouble(
        _readField(data, const ['lastReading', 'last_reading']),
      ),
      'lastReadingDate': _parseDateTime(
        _readField(data, const ['lastReadingDate', 'last_reading_date']),
      )?.toIso8601String(),
      'pricePerUnit':
          _toDouble(
            _readField(data, const ['pricePerUnit', 'price_per_unit']),
          ) ??
          15000,
      'totalDebt':
          _toDouble(_readField(data, const ['totalDebt', 'total_debt'])) ??
          _toDouble(_readNestedMapField(billing, 'totalDebt')) ??
          0,
      'debtMonths':
          _toInt(_readField(data, const ['debtMonths', 'debt_months'])) ??
          _toInt(_readNestedMapField(billing, 'debtMonths')) ??
          0,
      'lastPaymentDate': _parseDateTime(
        _readField(data, const ['lastPaymentDate', 'last_payment_date']),
      )?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': _parseDateTime(
        _readField(data, const ['updatedAt', 'updated_at']),
      )?.toIso8601String(),
    };
  }

  dynamic _readField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }
    return null;
  }

  dynamic _readNestedMapField(dynamic value, String key) {
    if (value is Map<String, dynamic>) {
      return value[key];
    }
    if (value is Map) {
      return value[key];
    }
    return null;
  }

  String _normalizeRecordType(dynamic value, String collection) {
    final raw = _normalizeText(value);
    if (raw == 'payment' || raw == 'payments' || collection == 'payments') {
      return 'payment';
    }
    return 'meter';
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _nullableStringValue(dynamic value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }

  String _normalizeText(dynamic value) {
    return _stringValue(value).toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}

class _ProofImageSyncResult {
  const _ProofImageSyncResult({this.proofImagePath});

  final String? proofImagePath;
}

class _RecordUpsertResult {
  const _RecordUpsertResult({
    required this.reference,
    required this.shouldApplyToCustomer,
    required this.startsNewDebtMonth,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final bool shouldApplyToCustomer;
  final bool startsNewDebtMonth;
}
