import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/meter_record_model.dart';
import '../models/user_model.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<MeterRecord> _meterRecords = const [];
  List<MeterRecord> _paymentRecords = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentAreaCode;

  List<MeterRecord> get meterRecords => List.unmodifiable(_meterRecords);
  List<MeterRecord> get paymentRecords => List.unmodifiable(_paymentRecords);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadForUser(User user, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _currentAreaCode == user.areaCode &&
        (_meterRecords.isNotEmpty || _paymentRecords.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentAreaCode = user.areaCode;
    notifyListeners();

    try {
      final meterData = await _dbHelper.getRecordsForUser(
        user,
        recordType: 'meter',
      );
      final paymentData = await _dbHelper.getRecordsForUser(
        user,
        recordType: 'payment',
      );
      _meterRecords = meterData.map(MeterRecord.fromMap).toList();
      _paymentRecords = paymentData.map(MeterRecord.fromMap).toList();
    } catch (e) {
      _errorMessage = 'Không thể tải lịch sử: $e';
      _meterRecords = const [];
      _paymentRecords = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPaymentRecord({
    required User user,
    required MeterRecord record,
  }) async {
    await _dbHelper.insertPaymentRecord(record);

    await loadForUser(user, forceRefresh: true);
  }

  Future<void> addMeterRecord({
    required User user,
    required MeterRecord record,
  }) async {
    await _dbHelper.insertMeterRecord(record);
    await loadForUser(user, forceRefresh: true);
  }
}
