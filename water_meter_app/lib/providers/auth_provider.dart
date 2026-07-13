import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

/// ============================================================================
/// AUTH PROVIDER - Quản lý đăng nhập
/// ============================================================================
/// STATE: _currentUser, _isLoading, _errorMessage
/// METHODS:
/// - login(username, password): Đăng nhập (check local DB → Firebase → save local)
/// - logout(): Đăng xuất
/// - clearError(): Xóa lỗi
/// ============================================================================

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedUsername = username.trim();
      final normalizedPassword = password.trim();

      if (normalizedUsername.isEmpty) {
        _errorMessage = 'Vui long nhap ten dang nhap';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (normalizedPassword.isEmpty) {
        _errorMessage = 'Vui long nhap mat khau';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final localUser = await _dbHelper.login(
        normalizedUsername,
        normalizedPassword,
      );
      if (localUser != null) {
        _currentUser = localUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final firebaseUser = await _firebaseService.authenticateStaff(
        normalizedUsername,
        normalizedPassword,
      );
      if (firebaseUser == null) {
        _errorMessage = 'Ten dang nhap hoac mat khau khong dung';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _dbHelper.upsertUser(firebaseUser);
      _currentUser = firebaseUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Loi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
