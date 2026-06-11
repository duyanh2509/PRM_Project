import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._internal();

  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<ConnectivityResult>? _subscription;
  bool _manualOnline = true;
  bool _networkAvailable = true;
  bool _initialized = false;

  bool get isOnline => _manualOnline && _networkAvailable;
  Stream<bool> get statusStream => _controller.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final initialResult = await _connectivity.checkConnectivity();
    _networkAvailable = _hasInternet(initialResult);
    _emit();

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _networkAvailable = _hasInternet(result);
      _emit();
    });
  }

  void setManualOnline(bool isOnline) {
    _manualOnline = isOnline;
    _emit();
  }

  void toggleManualOnline() {
    setManualOnline(!_manualOnline);
  }

  bool get manualOnline => _manualOnline;

  bool _hasInternet(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(isOnline);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
