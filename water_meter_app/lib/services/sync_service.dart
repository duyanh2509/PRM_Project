import '../models/user_model.dart';
import 'api_service.dart';

class SyncService {
  SyncService._internal();

  static final SyncService instance = SyncService._internal();

  final ApiService _apiService = ApiService.instance;

  Future<int> syncPendingRecords(User user) {
    return _apiService.syncPendingRecords(user);
  }
}
