import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service để tương tác với Firebase Backend
/// - Firestore: Lưu trữ dữ liệu (staff, customers, meter_readings, payments)
/// - Storage: Lưu trữ ảnh đồng hồ nước
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== STAFF ====================

  /// Lấy thông tin staff theo username từ Firestore
  Future<Map<String, dynamic>?> getStaffByUsername(String username) async {
    try {
      final snapshot = await _firestore
          .collection('staff')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };
    } catch (e) {
      print('❌ Error getting staff: $e');
      return null;
    }
  }

  /// Lấy tất cả staff (admin only)
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final snapshot = await _firestore.collection('staff').get();
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting all staff: $e');
      return [];
    }
  }

  // ==================== CUSTOMERS ====================

  /// Download danh sách customers theo areaCode
  Future<List<Map<String, dynamic>>> downloadCustomers(String areaCode) async {
    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('areaCode', isEqualTo: areaCode)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error downloading customers: $e');
      return [];
    }
  }

  /// Download tất cả customers (admin only)
  Future<List<Map<String, dynamic>>> downloadAllCustomers() async {
    try {
      final snapshot = await _firestore.collection('customers').get();
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error downloading all customers: $e');
      return [];
    }
  }

  /// Upload customer lên Firestore (admin only)
  Future<String?> uploadCustomer(Map<String, dynamic> customer) async {
    try {
      final docRef = await _firestore.collection('customers').add({
        ...customer,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Customer uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error uploading customer: $e');
      return null;
    }
  }

  /// Update customer trong Firestore
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

      if (snapshot.docs.isEmpty) return false;

      await snapshot.docs.first.reference.update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Customer updated: $customerCode');
      return true;
    } catch (e) {
      print('❌ Error updating customer: $e');
      return false;
    }
  }

  // ==================== METER READINGS ====================

  /// Upload meter reading lên Firestore
  Future<String?> uploadMeterReading(Map<String, dynamic> reading) async {
    try {
      final docRef = await _firestore.collection('meter_readings').add({
        ...reading,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Meter reading uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error uploading reading: $e');
      return null;
    }
  }

  /// Download meter readings theo customerCode
  Future<List<Map<String, dynamic>>> downloadMeterReadings(
    String customerCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('meter_readings')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error downloading readings: $e');
      return [];
    }
  }

  // ==================== PAYMENTS ====================

  /// Upload payment lên Firestore
  Future<String?> uploadPayment(Map<String, dynamic> payment) async {
    try {
      final docRef = await _firestore.collection('payments').add({
        ...payment,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Payment uploaded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error uploading payment: $e');
      return null;
    }
  }

  /// Download payments theo customerCode
  Future<List<Map<String, dynamic>>> downloadPayments(
    String customerCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('customerCode', isEqualTo: customerCode)
          .orderBy('recordedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error downloading payments: $e');
      return [];
    }
  }

  // ==================== STORAGE (Images) ====================

  /// Upload ảnh đồng hồ nước lên Firebase Storage
  Future<String?> uploadMeterImage(File imageFile, String customerCode) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${customerCode}_$timestamp.jpg';
      final ref = _storage.ref().child('meter_images/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Xóa ảnh từ Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      print('✅ Image deleted: $imageUrl');
      return true;
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  // ==================== SYNC HELPERS ====================

  /// Kiểm tra kết nối Firebase
  Future<bool> testConnection() async {
    try {
      final snapshot = await _firestore
          .collection('staff')
          .limit(1)
          .get(const GetOptions(source: Source.server));

      print('✅ Firebase connected!');
      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }

  /// Get server timestamp
  Future<DateTime?> getServerTime() async {
    try {
      final docRef = _firestore.collection('_system').doc('timestamp');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      final snapshot = await docRef.get();
      final timestamp = snapshot.data()?['timestamp'] as Timestamp?;

      await docRef.delete();

      return timestamp?.toDate();
    } catch (e) {
      print('❌ Error getting server time: $e');
      return null;
    }
  }
}
