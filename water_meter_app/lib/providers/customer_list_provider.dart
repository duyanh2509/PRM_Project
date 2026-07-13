import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';

/// ============================================================================
/// CUSTOMER LIST PROVIDER - Quản lý danh sách khách hàng
/// ============================================================================
/// STATE: _customers (list), _searchQuery (search text), _isLoading, _errorMessage
/// GETTERS:
/// - customers: Danh sách gốc
/// - filteredCustomers: Danh sách sau khi search (tự động filter theo searchQuery)
/// METHODS:
/// - loadCustomersForUser(user): Load danh sách từ DB theo khu vực
/// - updateSearchQuery(value): Cập nhật từ khóa search → tự động filter
/// - clearSearch(): Xóa search query
/// ============================================================================

class CustomerListProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Customer> _customers = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentAreaCode;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<Customer> get filteredCustomers {
    if (_searchQuery.trim().isEmpty) {
      return customers;
    }

    final keyword = _searchQuery.trim().toLowerCase();
    return _customers.where((customer) {
      return customer.customerName.toLowerCase().contains(keyword) ||
          customer.customerCode.toLowerCase().contains(keyword) ||
          customer.address.toLowerCase().contains(keyword);
    }).toList();
  }

  Future<void> loadCustomersForUser(
    User user, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _currentAreaCode == user.areaCode &&
        _customers.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentAreaCode = user.areaCode;
    notifyListeners();

    try {
      final data = await _dbHelper.getCustomersForUser(user);
      _customers = data.map(Customer.fromMap).toList();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách hộ gia đình: $e';
      _customers = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    if (value == _searchQuery) {
      return;
    }
    _searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    updateSearchQuery('');
  }
}
