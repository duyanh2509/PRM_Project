import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Provider quản lý trạng thái đăng nhập
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate input
      if (username.trim().isEmpty) {
        _errorMessage = 'Vui lòng nhập username';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Vui lòng nhập password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Kiểm tra database
      final user = await _dbHelper.login(username.trim(), password);

      if (user == null) {
        _errorMessage = 'Username hoặc password không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Đăng nhập thành công
      _currentUser = user;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
