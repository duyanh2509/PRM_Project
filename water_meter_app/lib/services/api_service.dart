import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'connectivity_service.dart';
import 'firebase_service.dart';

/// ============================================================================
/// API SERVICE - Orchestrator cho download & sync operations
/// ============================================================================
/// METHODS:
/// - downloadAssignedCustomers(user): Download danh sách khách hàng từ Firestore
///   + Query collection 'customers' theo areaCode
///   + Lưu vào local DB (upsertCustomer)
///   + Return số lượng đã tải
///
/// - syncPendingRecords(user): Sync records pending lên Firestore
///   + Lấy records có syncStatus = 'pending' từ local DB
///   + Loop qua từng record:
///     * Gọi FirebaseService.syncRecord() → upload ảnh + lưu Firestore
///     * Nếu thành công → markRecordAsSynced()
///   + Return số lượng đã sync
/// ============================================================================

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;

  Future<int> downloadAssignedCustomers(User user) async {
    _ensureOnline();
    final serverCustomers = user.role == 'admin'
        ? await _firebaseService.downloadAllCustomers()
        : await _firebaseService.downloadCustomers(user.areaCode);
    final serverRecords = await _firebaseService.downloadRecords(
      areaCode: user.role == 'admin' ? null : user.areaCode,
    );
    await _dbHelper.replaceServerCustomersForUser(user, serverCustomers);
    await _dbHelper.replaceServerRecordsForUser(user, serverRecords);
    return _dbHelper.downloadLatestRouteForUser(user);
  }

  Future<int> syncPendingRecords(User user) async {
    _ensureOnline();
    final pendingRecords = await _dbHelper.getPendingRecordsForUser(user);
    var syncedCount = 0;
    final errors = <String>[];

    for (final record in pendingRecords) {
      try {
        final syncedRecord = await _firebaseService.syncRecord(record);
        await _dbHelper.markRecordSynced(
          syncedRecord,
          syncedAt: DateTime.now(),
        );
        syncedCount++;
      } catch (e) {
        errors.add('${record.customerCode}: $e');
      }
    }

    if (syncedCount == 0 && errors.isNotEmpty) {
      throw ApiException('Dong bo that bai: ${errors.join('; ')}');
    }

    final upgradedImages = await _syncLocalProofImages(user);
    return syncedCount + upgradedImages;
  }

  Future<int> _syncLocalProofImages(User user) async {
    final records = await _dbHelper.getRecordsWithLocalProofImagesForUser(user);
    var uploadedCount = 0;

    for (final record in records) {
      final proofImagePath = await _firebaseService
          .uploadAndUpdateRecordProofImage(record);
      if (proofImagePath == null) {
        continue;
      }

      await _dbHelper.updateRecordProofImagePath(record, proofImagePath);
      uploadedCount++;
    }

    return uploadedCount;
  }

  void _ensureOnline() {
    if (!_connectivityService.isOnline) {
      throw const ApiException(
        'Thiết bị đang ngoại tuyến. Hãy bật kết nối trước khi tải hoặc đồng bộ.',
      );
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
