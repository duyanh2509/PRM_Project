import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/connectivity_service.dart';
import '../services/download_service.dart';
import '../services/sync_service.dart';

class SettingsProvider with ChangeNotifier {
  SettingsProvider() {
    _initialize();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final DownloadService _downloadService = DownloadService.instance;
  final SyncService _syncService = SyncService.instance;

  StreamSubscription<bool>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isDownloading = false;
  int _pendingSyncCount = 0;
  int _cacheSizeMb = 8;
  int _downloadedCustomerCount = 0;
  String? _currentAreaCode;
  String? _statusMessage;
  DateTime? _lastSyncAt;
  User? _currentUser;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get isDownloading => _isDownloading;
  int get pendingSyncCount => _pendingSyncCount;
  int get cacheSizeMb => _cacheSizeMb;
  int get downloadedCustomerCount => _downloadedCustomerCount;
  String? get statusMessage => _statusMessage;
  DateTime? get lastSyncAt => _lastSyncAt;

  Future<void> _initialize() async {
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;
    _connectivitySubscription = _connectivityService.statusStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });
  }

  Future<void> loadForUser(User user, {bool forceRefresh = false}) async {
    if (!forceRefresh && _currentAreaCode == user.areaCode && _currentUser?.id == user.id) {
      return;
    }

    _currentUser = user;
    _currentAreaCode = user.areaCode;
    _pendingSyncCount = await _dbHelper.countPendingRecordsForUser(user);
    _cacheSizeMb = await _dbHelper.estimateCacheSizeMb();
    _downloadedCustomerCount = await _dbHelper.getDownloadedCustomerCountForUser(user);
    _lastSyncAt = await _dbHelper.getLastLocalSyncTimeForUser(user);
    notifyListeners();
  }

  Future<void> toggleOnline() async {
    _connectivityService.toggleManualOnline();
    _isOnline = _connectivityService.isOnline;
    notifyListeners();
  }

  Future<int> downloadLatestRoute(User user) async {
    _isDownloading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final downloaded = await _downloadService.downloadLatestRoute(user);
      await loadForUser(user, forceRefresh: true);
      _statusMessage = 'Đã tải $downloaded khách hàng từ máy chủ.';
      return downloaded;
    } catch (e) {
      _statusMessage = e.toString();
      rethrow;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<int> syncNow(User user) async {
    _isSyncing = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final syncedCount = await _syncService.syncPendingRecords(user);
      await loadForUser(user, forceRefresh: true);
      _statusMessage = syncedCount == 0
          ? 'Không có bản ghi nào cần đồng bộ.'
          : 'Đã đồng bộ $syncedCount bản ghi lên máy chủ.';
      return syncedCount;
    } catch (e) {
      _statusMessage = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    await _dbHelper.clearSyncedLocalCache(user);
    await loadForUser(user, forceRefresh: true);
    _statusMessage = 'Đã xóa bộ nhớ đệm cục bộ đã đồng bộ.';
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
