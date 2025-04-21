// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/game_grid_component.dart';
import '../components/wildcard_column_component.dart';
import '../dialogs/board_expired_dialog.dart';
import '../dialogs/failure_dialog.dart';
import '../dialogs/loading_dialog.dart';
import '../logic/error_handler.dart';
import '../logic/error_reporting.dart';
import '../logic/grid_loader.dart';
import '../logic/logging_handler.dart';
import '../logic/spelled_words_handler.dart';
import '../managers/state_manager.dart';
import '../models/api_models.dart';
import '../providers/game_state_provider.dart';
import '../services/api_service.dart';
import '../utils/connectivity_monitor.dart';
import '../utils/offline_mode_handler.dart';
import 'gameLayoutManager.dart';

/// BoardManager centralizes all board-related functionality including loading,
/// resetting, and managing the game board state.
class BoardManager {
  // Board state notifiers
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> messageNotifier = ValueNotifier<String>('');
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<String>> spelledWordsNotifier = ValueNotifier<List<String>>([]);

  // References to components
  final GlobalKey<GameGridComponentState> gridKey = GlobalKey<GameGridComponentState>();
  final GlobalKey<WildcardColumnComponentState> wildcardKey = GlobalKey<WildcardColumnComponentState>();

  // Flag to prevent loading a new board during orientation changes
  bool _isHandlingOrientationChange = false;

  // Debug flags (these should be passed in from main.dart)
  bool debugForceExpiredBoard = false;
  bool disableSpellCheck = false;

  // Game layout manager reference
  late GameLayoutManager gameLayoutManager;

  // Constructor
  BoardManager({required this.gameLayoutManager, this.debugForceExpiredBoard = false, this.disableSpellCheck = false});

  /// Initialize the board manager
  Future<void> initialize(BuildContext context) async {
    LogService.logInfo("Initializing BoardManager");
    await StateManager.setStartTime();
    await _applyDebugControls();

    // Initialize score and spelled words notifiers
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
  }

  /// Apply debug controls
  Future<void> _applyDebugControls() async {
    final prefs = await SharedPreferences.getInstance();

    if (debugForceExpiredBoard) {
      final nowUtc = DateTime.now().toUtc();
      // Set expiration to yesterday to force expired board
      final yesterdayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day - 1, 0, 0, 0, 0, 0);
      await prefs.setString('boardExpireDate', yesterdayUtc.toIso8601String());
    }
  }

  /// Load data for a new user or returning user
  Future<void> loadData(BuildContext context) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    // Check if this is a reload due to orientation change or app restart
    final bool hasLoadedBefore = prefs.getBool('hasLoadedBefore') ?? false;

    if (hasLoadedBefore) {
      LogService.logInfo("🔄 Detected app reload");
      await _handleAppReload(context, api);
    } else {
      // Mark that we've loaded the app at least once
      await prefs.setBool('hasLoadedBefore', true);

      // Set start time for tracking play duration
      await StateManager.setStartTime();

      // Check if this is a new user
      bool isNewUser = await StateManager.isNewUser();

      // Set user information for existing users
      if (!isNewUser) {
        var userData = await StateManager.getUserData();
        api.setUserInformation(userData);
      }

      if (isNewUser) {
        // New User Flow
        LogService.logInfo("👤 New User Detected - Registering...");
        await _handleNewUser(context, api);
      } else {
        // Returning User Flow
        LogService.logInfo("👤 Existing User Detected - Loading board...");
        await loadBoardForUser(context, api);
      }
    }

    // Final UI sync
    _syncUIComponents();

    // Check if we have tiles loaded
    if (GridLoader.gridTiles.isEmpty) {
      LogService.logError("❌ No grid tiles loaded in GridLoader");

      // Check if we have UI components with tiles before showing failure dialog
      bool hasGridTiles = gridKey.currentState?.getTiles().isNotEmpty ?? false;
      bool hasWildcardTiles = wildcardKey.currentState?.getTiles().isNotEmpty ?? false;

      if (!hasGridTiles && !hasWildcardTiles) {
        LogService.logError("❌ No tiles available in UI components! Showing failure dialog...");
        await FailureDialog.show(context, gameLayoutManager);
      } else {
        LogService.logInfo("✅ Using default tiles in UI components");
      }
    } else {
      LogService.logInfo("✅ Board successfully loaded! Syncing UI...");
    }
  }

  /// Handle app reload (after orientation change or app restart)
  Future<void> _handleAppReload(BuildContext context, ApiService api) async {
    // First check if the board is expired
    final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();
    LogService.logInfo("🔄 Board expired check on app reload: $isExpired");

    if (isExpired) {
      LogService.logInfo("🔄 Board is expired on app reload - loading new board");

      // Temporarily reset the orientation change flag to allow loading a new board
      bool wasHandlingOrientationChange = _isHandlingOrientationChange;
      if (wasHandlingOrientationChange) {
        _isHandlingOrientationChange = false;
        LogService.logInfo("🔄 Temporarily disabling orientation change flag to load new board");
      }

      try {
        await _loadNewBoard(context, api);
      } finally {
        // Restore the orientation change flag
        if (wasHandlingOrientationChange) {
          _isHandlingOrientationChange = true;
          LogService.logInfo("🔄 Restoring orientation change flag");
        }
      }

      return;
    }

    // Try to restore from stored board data
    bool success = await GridLoader.loadStoredBoard();
    if (success) {
      LogService.logInfo("🔄 Successfully restored board from storage");

      // Restore state from preferences
      await StateManager.restoreState(gridKey, wildcardKey, scoreNotifier, spelledWordsNotifier);

      // Reload the UI components
      _syncUIComponents();
    }
  }

  /// Handle new user registration
  Future<void> _handleNewUser(BuildContext context, ApiService api) async {
    try {
      isLoadingNotifier.value = true;

      // Get locale and platform information
      String locale = 'en-US'; // Default
      String platform = 'Windows'; // Default

      // Register the new user
      final response = await api.register(locale, platform);
      if (response.security == null) {
        LogService.logError('Error: Registration failed - null security');
        return;
      }

      // New users are NOT logged in by default
      api.loggedIn = false;

      // Load a new board for the user
      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      await GridLoader.loadNewBoard(api, finalScore);

      // Update UI components
      _syncUIComponents();
    } catch (e) {
      LogService.logError('Error registering new user: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Load a board for an existing user
  Future<void> loadBoardForUser(BuildContext context, ApiService api) async {
    try {
      // Skip loading a new board if we're handling an orientation change
      if (_isHandlingOrientationChange) {
        LogService.logInfo("🔄 Skipping board load during orientation change");
        return;
      }

      // First check if we need a new board
      final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();
      final hasBoardData = await StateManager().hasBoardData();

      LogService.logInfo("🔄 Loading board for user... isExpired: $isExpired, hasBoardData: $hasBoardData");

      // Force load a new board if we don't have board data or if it's expired
      if (!hasBoardData || isExpired) {
        await _loadNewBoard(context, api);
      } else {
        // Board is still valid, restore previous state
        LogService.logInfo("🔄 Restoring state...");
        await StateManager.restoreState(gridKey, wildcardKey, scoreNotifier, spelledWordsNotifier);

        // Ensure UI components are updated
        _syncUIComponents();

        LogService.logInfo("✅ State restored and UI updated");
      }
    } catch (e) {
      LogService.logError("🚨 Error in loadBoardForUser: $e");
      ErrorReporting.reportException(e, StackTrace.current, context: 'Load board for user');

      // Show error dialog
      if (context.mounted) {
        ErrorHandler.handleError(
          context,
          ErrorHandler.DATA_ERROR,
          "Failed to load game board",
          onRetry: () => loadBoardForUser(context, api),
        );
      }
    }
  }

  /// Load a new board
  Future<void> _loadNewBoard(BuildContext context, ApiService api) async {
    LogService.logInfo("🔄 Loading new board...");

    if (context.mounted) {
      LoadingDialog.show(context, gameLayoutManager, message: "Loading new board...");
    }

    try {
      // Get the current score before resetting state
      final SubmitScoreRequest currentScore = await SpelledWordsLogic.getCurrentScore();

      // Check connectivity before loading new board
      if (!await ConnectivityMonitor().checkConnection()) {
        LogService.logError("🚨 Cannot load new board: No network connection");
        OfflineModeHandler.enterOfflineMode();

        // Show error dialog
        if (context.mounted) {
          ErrorHandler.handleError(
            context,
            ErrorHandler.NETWORK_ERROR,
            "Cannot load new board: No network connection",
            onRetry: () => loadBoardForUser(context, api),
          );
        }

        // Fall back to stored board
        await GridLoader.loadStoredBoard();
        return;
      }

      // Double-check we're not in orientation change before making API call
      if (_isHandlingOrientationChange) {
        LogService.logInfo("🔄 Cancelling new board load - orientation change in progress");
        return;
      }

      // Load the new board with the current score
      bool success = await GridLoader.loadNewBoard(api, currentScore);

      // Only reset state after successfully loading the new board
      if (success) {
        await StateManager.resetState(gridKey);

        // Update UI components
        _syncUIComponents();

        LogService.logInfo("✅ New board loaded and UI updated");
      } else {
        LogService.logError("❌ Failed to load new board. Falling back to stored board.");
        await GridLoader.loadStoredBoard();
      }
    } catch (e) {
      LogService.logError("🚨 Error loading new board: $e");
      ErrorReporting.reportException(e, StackTrace.current, context: 'Load new board');

      // Fall back to stored board
      await GridLoader.loadStoredBoard();
    } finally {
      if (context.mounted) {
        LoadingDialog.dismiss(context);
      }
    }
  }

  /// Reset the board during gameplay
  Future<void> resetBoard(BuildContext context) async {
    isLoadingNotifier.value = true;
    messageNotifier.value = "Resetting board...";

    try {
      // Save current score for submission
      final currentScore = await SpelledWordsLogic.getCurrentScore();

      // Reset state
      await StateManager.resetState(gridKey);

      // Load new board
      final api = Provider.of<ApiService>(context, listen: false);
      bool success = await GridLoader.loadNewBoard(api, currentScore);

      if (success) {
        // Update UI components
        _syncUIComponents();

        messageNotifier.value = "Board reset successfully";
        LogService.logInfo("✅ Board reset successfully");
      } else {
        messageNotifier.value = "Failed to reset board";
        LogService.logError("❌ Failed to reset board");
      }
    } catch (e) {
      LogService.logError("Error resetting board: $e");
      messageNotifier.value = "Failed to reset board";
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Handle app resume after being paused
  Future<void> handleAppResume(BuildContext context) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      // Reset activity time to exclude pause duration
      await StateManager.resetActivityTimeAfterPause();

      // Check if game is loaded
      bool isGameLoaded = GridLoader.gridTiles.isNotEmpty;
      LogService.logInfo("App resume check: Game loaded? $isGameLoaded");

      if (isGameLoaded) {
        // Game is loaded, check if board has expired
        bool isBoardExpired = await StateManager.isBoardExpired();
        LogService.logInfo("App resume check: Board expired? $isBoardExpired");

        if (isBoardExpired) {
          // Board expired while app was paused, load new board
          LogService.logInfo("Board expired during pause - Loading new board");
          await loadBoardForUser(context, api);
        } else {
          // Board still valid, just sync UI
          LogService.logInfo("Board still valid - Syncing UI");
          _syncUIComponents();
        }
      } else {
        // Game not loaded, load board as usual
        LogService.logInfo("Game not loaded - Loading board");
        await loadBoardForUser(context, api);
      }
    } catch (e) {
      LogService.logError("Error handling app resume: $e");
    }
  }

  /// Handle orientation change
  Future<void> handleOrientationChange(BuildContext context) async {
    try {
      // Get the game state provider
      final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);

      // Set flags to prevent loading a new board during orientation change
      _isHandlingOrientationChange = true;
      gameStateProvider.setOrientationChanging(true);
      LogService.logInfo("Setting orientation change flags to prevent board reload");

      // CRITICAL: Save the game state BEFORE any layout changes
      LogService.logInfo("Saving game state before orientation change");
      await gameStateProvider.saveState();

      // Calculate layout sizes
      gameLayoutManager.calculateLayoutSizes(context);

      // Wait longer for the UI to stabilize
      await Future.delayed(Duration(milliseconds: 500));

      // Check if context is still valid
      if (!context.mounted) {
        LogService.logError("Context is no longer mounted during orientation change");
        return;
      }

      // CRITICAL: Restore the game state AFTER layout changes and UI rebuild
      LogService.logInfo("Restoring game state after orientation change");
      await gameStateProvider.restoreState();

      // Wait longer for the state to be fully restored
      await Future.delayed(Duration(milliseconds: 300));

      // Make sure the grid and wildcard components are properly updated
      if (context.mounted) {
        _syncUIComponents();
        LogService.logInfo("Game state fully restored after orientation change");
      }
    } catch (e) {
      LogService.logError("Error during orientation change: $e");
    } finally {
      // Reset flags after orientation change is complete
      _isHandlingOrientationChange = false;

      // Reset the game state provider flag if context is still valid
      if (context.mounted) {
        final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);
        gameStateProvider.setOrientationChanging(false);
      }

      LogService.logInfo("Resetting orientation change flags");
    }
  }

  /// Save the current game state
  Future<void> saveState() async {
    await StateManager.saveState(gridKey, wildcardKey);
    await StateManager.updatePlayTime();
    LogService.logInfo("Game state saved");
  }

  /// Check if the board is expired and ask user if they want to load a new one
  Future<bool> checkAndHandleExpiredBoard(BuildContext context) async {
    final expiredTime = await StateManager.boardExpiredDuration();
    if (expiredTime == null || expiredTime > 120) {
      return true; // Auto-refresh if expired > 2 hours
    }
    return await BoardExpiredDialog.show(context, gameLayoutManager) ?? false; // Ask user if < 2 hours
  }

  /// Submit a word from the game grid
  void submitWord() {
    gridKey.currentState?.submitWord();
  }

  /// Clear selected words from the game grid
  void clearWords() {
    gridKey.currentState?.clearSelectedTiles();
    wildcardKey.currentState?.clearSelectedTiles();
    messageNotifier.value = '';
  }

  /// Handle message from game components
  void handleMessage(String message) {
    // Force the message notifier to update even if the message is the same
    // by temporarily setting it to empty and then to the actual message
    messageNotifier.value = '';

    // Use a small delay to ensure the empty message is processed
    Future.microtask(() {
      messageNotifier.value = message;
    });

    // Sync score and spelled words
    updateScoresRefresh();
  }

  /// Update scores and spelled words in the UI
  void updateScoresRefresh() {
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
  }

  /// Sync UI components with current state
  void _syncUIComponents() {
    if (gridKey.currentState != null) {
      LogService.logInfo("Reloading grid tiles");
      gridKey.currentState!.reloadTiles();
    }

    if (wildcardKey.currentState != null) {
      LogService.logInfo("Reloading wildcard tiles");
      wildcardKey.currentState!.reloadWildcardTiles();
    }

    // Update score and spelled words
    updateScoresRefresh();
  }
}
