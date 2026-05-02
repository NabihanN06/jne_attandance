import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum ConnectionStatus { wifi, mobile, none }

class ConnectivityService extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.none;
  ConnectionStatus get status => _status;
  
  bool get isOnline => _status != ConnectionStatus.none;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      _status = ConnectionStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _status = ConnectionStatus.mobile;
    } else {
      _status = ConnectionStatus.none;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
