// File: /lib/utils/connectivity_monitor.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logic/logging_handler.dart';

/// A utility class to monitor network connectivity changes.
///
/// This class provides methods to check the current connectivity status
/// and listen for connectivity changes. It uses the connectivity_plus package
/// to detect network changes across different platforms.
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._internal();
  factory ConnectivityMonitor() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isConnected = true;

  // Stream controller to broadcast connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream that emits true when connected, false when disconnected
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  ConnectivityMonitor._internal();

  /// Initialize connectivity monitoring
  void initialize() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    LogService.logInfo('🌐 Connectivity monitoring initialized');
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      LogService.logError('🚨 Failed to check connectivity: $e');
    }
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    // Only notify if status changed
    if (wasConnected != _isConnected) {
      LogService.logInfo('🌐 Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');
      _connectivityController.add(_isConnected);
    }
  }

  /// Get current connection status
  bool get isConnected => _isConnected;

  /// Check if currently connected
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      LogService.logError('🚨 Error checking connection: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
