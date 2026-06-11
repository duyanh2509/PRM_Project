import '../models/user_model.dart';
import 'api_service.dart';

class DownloadService {
  DownloadService._internal();

  static final DownloadService instance = DownloadService._internal();

  final ApiService _apiService = ApiService.instance;

  Future<int> downloadLatestRoute(User user) {
    return _apiService.downloadAssignedCustomers(user);
  }
}
