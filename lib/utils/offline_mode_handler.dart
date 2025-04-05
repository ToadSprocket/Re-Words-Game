// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:async';
import '../logic/logging_handler.dart';
import '../utils/connectivity_monitor.dart';

/// A utility class that handles offline mode functionality.
///
/// This class provides methods to check if the app is in offline mode,
/// enter or exit offline mode, and register callbacks for offline mode changes.
class OfflineModeHandler {
  static bool _isOfflineMode = false;
  static final List<Function(bool)> _listeners = [];
  static StreamSubscription<bool>? _connectivitySubscription;

  /// Check if we're in offline mode
  static bool get isOfflineMode => _isOfflineMode;

  /// Enter offline mode
  static void enterOfflineMode() {
    if (!_isOfflineMode) {
      _isOfflineMode = true;
      LogService.logInfo('🌐 Entering offline mode');
      _notifyListeners();
    }
  }

  /// Exit offline mode
  static void exitOfflineMode() {
    if (_isOfflineMode) {
      _isOfflineMode = false;
      LogService.logInfo('🌐 Exiting offline mode');
      _notifyListeners();
    }
  }

  /// Initialize offline mode handler
  static void initialize() {
    // Check initial connectivity
    ConnectivityMonitor().checkConnection().then((isConnected) {
      if (!isConnected) {
        enterOfflineMode();
      }
    });

    // Listen for connectivity changes
    _connectivitySubscription = ConnectivityMonitor().onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        exitOfflineMode();
      } else {
        enterOfflineMode();
      }
    });

    LogService.logInfo('🌐 Offline mode handler initialized');
  }

  /// Add a listener for offline mode changes
  static void addListener(Function(bool isOffline) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener for offline mode changes
  static void removeListener(Function(bool isOffline) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of offline mode changes
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_isOfflineMode);
    }
  }

  /// Dispose resources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _listeners.clear();
  }

  /// Check if a feature is available in offline mode
  static bool isFeatureAvailable(String featureKey) {
    if (!_isOfflineMode) {
      return true; // All features available when online
    }

    // Define which features are available in offline mode
    const availableOfflineFeatures = {
      'view_game_board': true,
      'play_game': true,
      'view_local_scores': true,
      'submit_score': false,
      'login': false,
      'register': false,
      'view_high_scores': false,
      'update_profile': false,
    };

    return availableOfflineFeatures[featureKey] ?? false;
  }

  /// Get a message explaining why a feature is unavailable
  static String getFeatureUnavailableMessage(String featureKey) {
    switch (featureKey) {
      case 'submit_score':
        return 'Score submission is unavailable while offline. Your score will be submitted automatically when you reconnect.';
      case 'login':
      case 'register':
        return 'Authentication requires an internet connection. Please try again when you\'re back online.';
      case 'view_high_scores':
        return 'High scores cannot be retrieved while offline. Please check your connection and try again.';
      case 'update_profile':
        return 'Profile updates require an internet connection. Please try again when you\'re back online.';
      default:
        return 'This feature is unavailable while offline. Please check your connection and try again.';
    }
  }
}
