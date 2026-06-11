import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'connectivity_service.dart';

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  Future<int> downloadAssignedCustomers(User user) async {
    _ensureOnline();
    return _dbHelper.downloadLatestRouteForUser(user);
  }

  Future<int> syncPendingRecords(User user) async {
    _ensureOnline();
    return _dbHelper.syncPendingRecordsToServer(user);
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
