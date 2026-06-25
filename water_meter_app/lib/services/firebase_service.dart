import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/meter_record_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();

  factory FirebaseService() => instance;

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> getStaffByUsername(String username) async {
    try {
      final snapshot = await _firestore
          .collection('staff')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };
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

    final storedPassword = _stringValue(staff['password']);
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
      final snapshot = await _firestore.collection('staff').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting all staff: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> downloadCustomers(String areaCode) async {
    try {
      final normalizedAreaCode = _normalizeText(areaCode);

      final directSnapshot = await _firestore
          .collection('customers')
          .where('areaCode', isEqualTo: areaCode)
          .get();

      final directMatches = directSnapshot.docs
          .map((doc) => _mapCustomerDocument(doc.data()))
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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> downloadAllCustomers() async {
    try {
      final snapshot = await _firestore.collection('customers').get();
      return snapshot.docs
          .map((doc) => _mapCustomerDocument(doc.data()))
          .toList();
    } catch (e) {
      print('Error downloading all customers: $e');
      return [];
    }
  }

  Future<List<Map<String, Object?>>> downloadRecords({String? areaCode}) async {
    try {
      final meterSnapshot = await _firestore.collection('meter_readings').get();
      final paymentSnapshot = await _firestore.collection('payments').get();

      final records = <Map<String, Object?>>[
        ...meterSnapshot.docs.map((doc) => _mapRecordDocument(doc.data())),
        ...paymentSnapshot.docs.map((doc) => _mapRecordDocument(doc.data())),
      ];

      if (areaCode == null || areaCode == 'ALL') {
        records.sort(_compareRecordMaps);
        return records;
      }

      final filtered = records.where((record) {
        return _stringValue(record['areaCode']) == areaCode;
      }).toList()
        ..sort(_compareRecordMaps);
      return filtered;
    } catch (e) {
      print('Error downloading records: $e');
      return [];
    }
  }

  Future<String?> uploadCustomer(Map<String, dynamic> customer) async {
    try {
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
      final snapshot = await _firestore
          .collection('meter_readings')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error downloading readings: $e');
      return [];
    }
  }

  Future<String?> uploadPayment(Map<String, dynamic> payment) async {
    try {
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
      final snapshot = await _firestore
          .collection('payments')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error downloading payments: $e');
      return [];
    }
  }

  Future<String?> uploadMeterImage(File imageFile, String customerCode) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${customerCode}_$timestamp.jpg';
      final ref = _storage.ref().child('meter_images/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted: $imageUrl');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
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
    final proofImagePath = await _resolveProofImagePath(record);
    final syncedRecord = record.copyWith(proofImagePath: proofImagePath);

    if (record.recordType == 'payment') {
      await _upsertPayment(syncedRecord);
      await _applyPaymentToCustomer(syncedRecord);
    } else {
      await _upsertMeterReading(syncedRecord);
      await _applyMeterReadingToCustomer(syncedRecord);
    }

    return syncedRecord;
  }

  Future<String?> _resolveProofImagePath(MeterRecord record) async {
    final rawPath = record.proofImagePath;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    final file = File(rawPath);
    if (!await file.exists()) {
      return rawPath;
    }

    return uploadMeterImage(file, record.customerCode);
  }

  Future<void> _upsertMeterReading(MeterRecord record) async {
    await _firestore
        .collection('meter_readings')
        .doc(_buildRecordId(record))
        .set(_recordPayload(record), SetOptions(merge: true));
  }

  Future<void> _upsertPayment(MeterRecord record) async {
    await _firestore
        .collection('payments')
        .doc(_buildRecordId(record))
        .set(_recordPayload(record), SetOptions(merge: true));
  }

  Future<void> _applyMeterReadingToCustomer(MeterRecord record) async {
    final docRef = await _findCustomerDoc(record.customerCode);
    if (docRef == null) {
      throw Exception('Không tìm thấy khách hàng ${record.customerCode} trên Firebase.');
    }

    final snapshot = await docRef.get();
    final currentData = snapshot.data() ?? const <String, dynamic>{};
    final pricePerUnit = _toDouble(currentData['pricePerUnit']) ?? record.pricePerUnit;
    final oldReading = record.oldReading ?? _toDouble(currentData['lastReading']) ?? 0;
    final newReading = record.newReading ?? oldReading;
    final consumed = math.max(0, newReading - oldReading);
    final billAmount = consumed * pricePerUnit;
    final currentDebt = _toDouble(currentData['totalDebt']) ?? 0;
    final currentDebtMonths = _toInt(currentData['debtMonths']) ?? 0;

    await docRef.set({
      'lastReading': newReading,
      'lastReadingDate': Timestamp.fromDate(record.recordedAt),
      'totalDebt': currentDebt + billAmount,
      'debtMonths': currentDebtMonths + (billAmount > 0 ? 1 : 0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _applyPaymentToCustomer(MeterRecord record) async {
    final docRef = await _findCustomerDoc(record.customerCode);
    if (docRef == null) {
      throw Exception('Không tìm thấy khách hàng ${record.customerCode} trên Firebase.');
    }

    final snapshot = await docRef.get();
    final currentData = snapshot.data() ?? const <String, dynamic>{};
    final currentDebt = _toDouble(currentData['totalDebt']) ?? 0;
    final currentDebtMonths = _toInt(currentData['debtMonths']) ?? 0;
    final remaining = math.max(0, currentDebt - (record.amountCollected ?? 0));

    await docRef.set({
      'totalDebt': remaining,
      'debtMonths': remaining <= 0 ? 0 : currentDebtMonths,
      'lastPaymentDate': Timestamp.fromDate(record.recordedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      'collectorName': record.collectorName,
      'note': record.note,
      'billingMonth': record.billingMonth,
      'paymentMethod': record.paymentMethod,
      'paymentStatus': record.paymentStatus,
      'proofImagePath': record.proofImagePath,
      'recordedAt': Timestamp.fromDate(record.recordedAt),
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _mapRecordDocument(Map<String, dynamic> data) {
    return {
      'customerCode': _stringValue(data['customerCode']),
      'recordType': _stringValue(data['recordType'], fallback: 'meter'),
      'oldReading': _toDouble(data['oldReading']),
      'newReading': _toDouble(data['newReading']),
      'amountCollected': _toDouble(data['amountCollected']),
      'syncStatus': 'synced',
      'recordedAt':
          (_parseDateTime(data['recordedAt']) ?? DateTime.now()).toIso8601String(),
      'collectorName': _nullableStringValue(data['collectorName']),
      'note': _nullableStringValue(data['note']),
      'billingMonth': _nullableStringValue(data['billingMonth']),
      'paymentMethod': _nullableStringValue(data['paymentMethod']),
      'paymentStatus': _nullableStringValue(data['paymentStatus']),
      'proofImagePath': _nullableStringValue(data['proofImagePath']),
      'syncedAt': _parseDateTime(data['uploadedAt'])?.toIso8601String(),
      'areaCode': _stringValue(data['areaCode']),
      'areaName': _stringValue(data['areaName']),
    };
  }

  int _compareRecordMaps(Map<String, Object?> a, Map<String, Object?> b) {
    final aDate = DateTime.tryParse(_stringValue(a['recordedAt'])) ?? DateTime.now();
    final bDate = DateTime.tryParse(_stringValue(b['recordedAt'])) ?? DateTime.now();
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) {
      return byDate;
    }
    return _stringValue(a['customerCode']).compareTo(_stringValue(b['customerCode']));
  }

  Map<String, Object?> _mapCustomerDocument(Map<String, dynamic> data) {
    final createdAt = _parseDateTime(data['createdAt']) ?? DateTime.now();

    return {
      'customerCode': _stringValue(data['customerCode']),
      'customerName': _stringValue(
        data['customerName'],
        fallback: _stringValue(data['name']),
      ),
      'address': _stringValue(data['address']),
      'phoneNumber': _nullableStringValue(data['phoneNumber']),
      'areaCode': _stringValue(data['areaCode'], fallback: 'ALL'),
      'areaName': _stringValue(data['areaName'], fallback: 'Tat ca khu vuc'),
      'lastReading': _toDouble(data['lastReading']),
      'lastReadingDate':
          _parseDateTime(data['lastReadingDate'])?.toIso8601String(),
      'pricePerUnit': _toDouble(data['pricePerUnit']) ?? 15000,
      'totalDebt': _toDouble(data['totalDebt']) ?? 0,
      'debtMonths': _toInt(data['debtMonths']) ?? 0,
      'lastPaymentDate':
          _parseDateTime(data['lastPaymentDate'])?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': _parseDateTime(data['updatedAt'])?.toIso8601String(),
    };
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
