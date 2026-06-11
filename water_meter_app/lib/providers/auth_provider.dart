import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Provider quản lý trạng thái đăng nhập.
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// Đăng nhập.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (username.trim().isEmpty) {
        _errorMessage = 'Vui lòng nhập tên đăng nhập';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Vui lòng nhập mật khẩu';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await _dbHelper.login(username.trim(), password);

      if (user == null) {
        _errorMessage = 'Tên đăng nhập hoặc mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

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

  /// Đăng xuất.
  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa thông báo lỗi.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
