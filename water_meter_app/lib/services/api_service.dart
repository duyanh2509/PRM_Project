import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'connectivity_service.dart';
import 'firebase_service.dart';

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

    for (final record in pendingRecords) {
      final syncedRecord = await _firebaseService.syncRecord(record);
      await _dbHelper.markRecordSynced(
        syncedRecord,
        syncedAt: DateTime.now(),
      );
      syncedCount++;
    }

    return syncedCount;
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
