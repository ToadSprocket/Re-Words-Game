// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'styles/app_styles.dart';
import 'logic/grid_loader.dart';
import 'logic/game_layout.dart';
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'dialogs/how_to_play_dialog.dart';
import 'dialogs/high_scores_dialog.dart';
import 'dialogs/legal_dialog.dart';
import 'dialogs/board_expired_dialog.dart';
import 'dialogs/failure_dialog.dart';
import 'dialogs/login_dialog.dart';
import 'components/game_grid_component.dart';
import 'components/wildcard_column_component.dart';
import 'components/error_boundary.dart';
import 'managers/state_manager.dart';
import 'services/api_service.dart';
import 'logic/spelled_words_handler.dart';
import 'logic/error_handler.dart';
import 'logic/error_reporting.dart';
import 'package:provider/provider.dart';
import 'models/api_models.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import 'package:window_size/window_size.dart';
import 'dialogs/welcome_dialog.dart';
import 'dialogs/loading_dialog.dart';
import 'services/word_service.dart';
import 'utils/web_utils.dart';
import 'utils/connectivity_monitor.dart';
import 'utils/offline_mode_handler.dart';
import 'utils/device_utils.dart';
import 'providers/orientation_provider.dart';

// App version information
const String MAJOR = "1";
const String MINOR = "0";
const String PATCH = "0";
const String BUILD = "44";

const String VERSION_STRING = "v$MAJOR.$MINOR.$PATCH+$BUILD";

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;
const bool debugForceIsNarrow = false;
const bool disableSpellCheck = false;
const bool debugForceExpiredBoard = false; // Force expired board
const bool debugForceValidBoard = false; // Force valid board
const bool debugClearPrefs = false; // Clear all prefs for new user
const bool debugForceIntroAnimation = false; // Force intro animation to play

// Window size constants
const double MIN_WINDOW_WIDTH = 1000.0;
const double MIN_WINDOW_HEIGHT = 800.0;
const double NARROW_LAYOUT_THRESHOLD = 900.0;
const double INITIAL_WINDOW_WIDTH = 1024.0;
const double INITIAL_WINDOW_HEIGHT = 768.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging based on build mode
  LogService.configureLogging();

  // Initialize error reporting
  await ErrorReporting.initialize();

  // Disable stack trace logging by default (can be toggled at runtime)
  ErrorReporting.logStackTraces = false;

  // Initialize connectivity monitoring
  ConnectivityMonitor().initialize();

  // Initialize offline mode handler
  OfflineModeHandler.initialize();

  final wordService = WordService();
  await wordService.initialize();

  // Initialize ApiService with stored user data
  final apiService = ApiService();
  await apiService.initializeFromStorage(); // Load user data from storage

  // Check if user is logged in based on tokens
  if (apiService.accessToken != null && apiService.userId != null) {
    apiService.loggedIn = true;
    LogService.logInfo("👤 User already logged in: ${apiService.userId}");
  }

  final GameLayoutManager layoutManager = GameLayoutManager();

  // Non-web platforms will initialize differently
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiService>(
          create: (context) => apiService, // Use the initialized instance
        ),
        ChangeNotifierProvider<OrientationProvider>(create: (context) => OrientationProvider()),
      ],
      child: ReWordApp(layoutManager: layoutManager),
    ),
  );

  // Set minimum window size and initial window size for desktop platforms
  if (!kIsWeb) {
    try {
      // Only run this code on desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        setWindowTitle('Re-Word Game');

        // Set minimum size
        setWindowMinSize(const Size(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT));

        // Set initial window size
        setWindowFrame(Rect.fromLTWH(0, 0, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT));

        // Center the window
        getCurrentScreen().then((screen) {
          if (screen != null) {
            final screenFrame = screen.visibleFrame;
            final windowFrame = Rect.fromLTWH(
              screenFrame.left + (screenFrame.width - INITIAL_WINDOW_WIDTH) / 2,
              screenFrame.top + (screenFrame.height - INITIAL_WINDOW_HEIGHT) / 2,
              INITIAL_WINDOW_WIDTH,
              INITIAL_WINDOW_HEIGHT,
            );
            setWindowFrame(windowFrame);
          }
        });
      }
    } catch (e) {
      // Ignore platform errors on web
      LogService.logError("Error setting window size: $e");
    }
  }

  // Initialize window manager for desktop platforms
  if (!kIsWeb) {
    try {
      // Only run this code on desktop platforms
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.ensureInitialized();
        WindowOptions windowOptions = const WindowOptions(
          size: Size(INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT),
          minimumSize: Size(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }
    } catch (e) {
      // Ignore platform errors on web
      LogService.logError("Error initializing window manager: $e");
    }
  }
}

class ReWordApp extends StatefulWidget {
  final GameLayoutManager layoutManager;
  final String? userId;
  final String? authToken;

  const ReWordApp({super.key, required this.layoutManager, this.userId, this.authToken});

  @override
  State<ReWordApp> createState() => _ReWordAppState();
}

class _ReWordAppState extends State<ReWordApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Word Game',
      theme: AppStyles.appTheme,
      home: ErrorBoundary(
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Initialize the provider outside of build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);
                orientationProvider.initialize(context);
                orientationProvider.changeOrientation(orientation, MediaQuery.of(context).size);
              }
            });

            // Get the orientation provider
            final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);

            // We'll only update orientation in the post-frame callback during initialization
            // This avoids creating an infinite loop of orientation changes

            return GameLayoutProvider(
              gameLayoutManager: widget.layoutManager,
              child: HomeScreen(userId: widget.userId, authToken: widget.authToken),
            );
          },
        ),
      ),
      builder: (context, child) {
        // Add error handling at the app level
        return ErrorBoundary(child: child ?? const SizedBox());
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? authToken;

  const HomeScreen({super.key, this.userId, this.authToken});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, WindowListener {
  final _gridKey = GlobalKey<GameGridComponentState>();
  final _wildcardKey = GlobalKey<WildcardColumnComponentState>();
  final ValueNotifier<String> messageNotifier = ValueNotifier<String>(''); // Notifier for message
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<String>> spelledWordsNotifier = ValueNotifier<List<String>>([]); // Notifier for words
  final GameLayoutManager gameLayoutManager = GameLayoutManager();
  Map<String, dynamic>? sizes;
  int loginAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Ensure this runs only after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set orientation settings based on device type
      DeviceUtils.setOrientationSettings(context);

      // Calculate layout sizes
      gameLayoutManager.calculateLayoutSizes(context);

      // Force rebuild to apply new sizes
      if (mounted) {
        setState(() {});
      }
    });

    // Only add window manager listener for desktop platforms
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          windowManager.addListener(this);
        }
      } catch (e) {
        // Ignore platform errors on web
        LogService.logError("Error adding window manager listener: $e");
      }
    }
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Only remove window manager listener for desktop platforms
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          windowManager.removeListener(this);
        }
      } catch (e) {
        // Ignore platform errors on web
        LogService.logError("Error removing window manager listener: $e");
      }
    }
    StateManager.saveState(_gridKey, _wildcardKey);
    StateManager.updatePlayTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Save current state when app is paused
      StateManager.saveState(_gridKey, _wildcardKey);
      StateManager.savePauseTime();
      LogService.logInfo("App lifecycle: PAUSED - Game state saved");
    } else if (state == AppLifecycleState.resumed) {
      // Handle app resume
      LogService.logInfo("App lifecycle: RESUMED - Checking game state");
      _handleAppResume();
    }
  }

  // Flag to prevent loading a new board during orientation changes
  bool _isHandlingOrientationChange = false;

  Future<void> _handleAppResume() async {
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
          await _loadBoardForUser(api);

          // Explicitly force UI refresh after loading new board
          LogService.logInfo("Forcing UI refresh after loading new board");
          if (mounted) {
            // Ensure grid and wildcard components are properly reloaded
            _gridKey.currentState?.reloadTiles();
            _wildcardKey.currentState?.reloadWildcardTiles();
            updateScoresRefresh();

            // Force rebuild to apply new board
            setState(() {});
          }
        } else {
          // Board still valid, just sync UI
          LogService.logInfo("Board still valid - Syncing UI");
          _gridKey.currentState?.reloadTiles();
          _wildcardKey.currentState?.reloadWildcardTiles();
          updateScoresRefresh();
        }
      } else {
        // Game not loaded, load board as usual
        LogService.logInfo("Game not loaded - Loading board");
        await _loadBoardForUser(api);

        // Ensure UI is refreshed after loading board
        if (mounted) {
          LogService.logInfo("Refreshing UI after loading board");
          _gridKey.currentState?.reloadTiles();
          _wildcardKey.currentState?.reloadWildcardTiles();
          updateScoresRefresh();
          setState(() {});
        }
      }
    } catch (e) {
      LogService.logError("Error handling app resume: $e");
    }
  }

  @override
  void onWindowClose() async {
    LogService.logInfo("🔄 Window close event detected - Saving state...");
    try {
      // Save state before closing
      await StateManager.saveState(_gridKey, _wildcardKey);
      await StateManager.updatePlayTime();
      LogService.logInfo("✅ State saved successfully before window close");
    } catch (e) {
      LogService.logError("❌ Error saving state on window close: $e");
    }

    super.onWindowClose();

    // Only destroy window manager for desktop platforms
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          LogService.logInfo("🔄 Destroying window manager...");
          await windowManager.destroy();
        }
      } catch (e) {
        // Ignore platform errors on web
        LogService.logError("Error destroying window manager: $e");
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Ensure we're not in the build phase by using post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Get the current orientation and size
        final currentOrientation = MediaQuery.of(context).orientation;
        final currentSize = MediaQuery.of(context).size;

        // Get the orientation provider
        final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);

        // Check if orientation or size has actually changed
        bool hasChanged =
            orientationProvider.orientation != currentOrientation || orientationProvider.currentSize != currentSize;

        if (hasChanged) {
          LogService.logInfo("Metrics changed - orientation: $currentOrientation, size: $currentSize");

          try {
            // Set flag to prevent loading a new board during orientation change
            _isHandlingOrientationChange = true;
            LogService.logInfo("Setting orientation change flag to prevent board reload");

            // CRITICAL: Save the game state BEFORE any layout changes
            LogService.logInfo("Saving game state before orientation change");
            await StateManager.saveState(_gridKey, _wildcardKey);

            // Update the orientation provider
            orientationProvider.changeOrientation(currentOrientation, currentSize);

            // Calculate layout sizes
            gameLayoutManager.calculateLayoutSizes(context);

            // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
            setState(() {
              // This will trigger a rebuild with the new layout sizes
              LogService.logInfo("Rebuilding UI with new layout sizes");
            });

            // Wait a moment for the UI to stabilize
            await Future.delayed(Duration(milliseconds: 300));

            // CRITICAL: Restore the game state AFTER layout changes and UI rebuild
            LogService.logInfo("Restoring game state after orientation change");
            await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

            // Wait another moment for the state to be fully restored
            await Future.delayed(Duration(milliseconds: 100));

            // Make sure the grid and wildcard components are properly updated
            if (_gridKey.currentState != null) {
              LogService.logInfo("Reloading grid tiles");
              _gridKey.currentState!.reloadTiles();
            }

            if (_wildcardKey.currentState != null) {
              LogService.logInfo("Reloading wildcard tiles");
              _wildcardKey.currentState!.reloadWildcardTiles();
            }

            updateScoresRefresh();
            LogService.logInfo("Game state fully restored after orientation change");
          } catch (e) {
            LogService.logError("Error during orientation change: $e");
          } finally {
            // Reset flag after orientation change is complete
            _isHandlingOrientationChange = false;
            LogService.logInfo("Resetting orientation change flag");
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Use post-frame callback to handle orientation changes
    // This avoids calling setState or markNeedsBuild during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Get the current orientation and size
        final currentOrientation = MediaQuery.of(context).orientation;
        final currentSize = MediaQuery.of(context).size;

        // Get the orientation provider
        final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);

        // Check if orientation or size has actually changed
        bool hasChanged =
            orientationProvider.orientation != currentOrientation || orientationProvider.currentSize != currentSize;

        if (hasChanged) {
          LogService.logInfo("Dependencies changed - orientation: $currentOrientation, size: $currentSize");

          try {
            // Set flag to prevent loading a new board during orientation change
            _isHandlingOrientationChange = true;
            LogService.logInfo("Setting orientation change flag to prevent board reload");

            // CRITICAL: Save the game state BEFORE any layout changes
            LogService.logInfo("Saving game state before dependencies change");
            await StateManager.saveState(_gridKey, _wildcardKey);

            // Update the orientation provider
            orientationProvider.changeOrientation(currentOrientation, currentSize);

            // Calculate layout sizes
            gameLayoutManager.calculateLayoutSizes(context);

            // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
            setState(() {
              // This will trigger a rebuild with the new layout sizes
              LogService.logInfo("Rebuilding UI with new layout sizes from dependencies");
            });

            // Wait a moment for the UI to stabilize
            await Future.delayed(Duration(milliseconds: 300));

            // CRITICAL: Restore the game state AFTER layout changes and UI rebuild
            LogService.logInfo("Restoring game state after dependencies change");
            await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

            // Wait another moment for the state to be fully restored
            await Future.delayed(Duration(milliseconds: 100));

            // Make sure the grid and wildcard components are properly updated
            if (_gridKey.currentState != null) {
              LogService.logInfo("Reloading grid tiles after dependencies change");
              _gridKey.currentState!.reloadTiles();
            }

            if (_wildcardKey.currentState != null) {
              LogService.logInfo("Reloading wildcard tiles after dependencies change");
              _wildcardKey.currentState!.reloadWildcardTiles();
            }

            updateScoresRefresh();
            LogService.logInfo("Game state fully restored after dependencies change");
          } catch (e) {
            LogService.logError("Error during dependencies change: $e");
          } finally {
            // Reset flag after orientation change is complete
            _isHandlingOrientationChange = false;
            LogService.logInfo("Resetting orientation change flag");
          }
        }
      }
    });
  }

  Future<void> _loadData() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    // Check if this is a reload due to orientation change or app restart
    // We use a shared preference to track this across app restarts
    final bool hasLoadedBefore = prefs.getBool('hasLoadedBefore') ?? false;

    if (hasLoadedBefore) {
      LogService.logInfo("🔄 Detected app reload");

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
          // Load a new board since the current one is expired
          LoadingDialog.show(context, gameLayoutManager, message: "Loading new board...");

          try {
            // Get the current score before resetting state
            final SubmitScoreRequest currentScore = await SpelledWordsLogic.getCurrentScore();

            // Check connectivity before loading new board
            if (!await ConnectivityMonitor().checkConnection()) {
              LogService.logError("🚨 Cannot load new board: No network connection");
              OfflineModeHandler.enterOfflineMode();

              // Show error dialog
              if (mounted) {
                ErrorHandler.handleError(
                  context,
                  ErrorHandler.NETWORK_ERROR,
                  "Cannot load new board: No network connection",
                  onRetry: () => _loadBoardForUser(api),
                );
              }

              // Fall back to stored board
              await GridLoader.loadStoredBoard();
            } else {
              // Load the new board with the current score
              bool success = await GridLoader.loadNewBoard(api, currentScore);

              // Only reset state after successfully loading the new board
              if (success) {
                await StateManager.resetState(_gridKey);

                // Ensure UI components are updated
                if (_gridKey.currentState != null) {
                  LogService.logInfo("Reloading grid tiles after new board load");
                  _gridKey.currentState!.reloadTiles();
                }

                if (_wildcardKey.currentState != null) {
                  LogService.logInfo("Reloading wildcard tiles after new board load");
                  _wildcardKey.currentState!.reloadWildcardTiles();
                }

                // Update score and spelled words
                scoreNotifier.value = SpelledWordsLogic.score;
                spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);

                LogService.logInfo("✅ New board loaded and UI updated");
              } else {
                LogService.logError("❌ Failed to load new board. Falling back to stored board.");
                await GridLoader.loadStoredBoard();
              }
            }
          } catch (e) {
            LogService.logError("🚨 Error loading new board: $e");
            ErrorReporting.reportException(e, StackTrace.current, context: 'Load new board');

            // Fall back to stored board
            await GridLoader.loadStoredBoard();
          } finally {
            if (mounted) LoadingDialog.dismiss(context);
          }
        } finally {
          // Restore the orientation change flag
          if (wasHandlingOrientationChange) {
            _isHandlingOrientationChange = true;
            LogService.logInfo("🔄 Restoring orientation change flag");
          }
        }

        return;
      }

      // Try to restore from stored board data instead of registering as new user
      bool success = await GridLoader.loadStoredBoard();
      if (success) {
        LogService.logInfo("🔄 Successfully restored board from storage");

        // Restore state from preferences
        await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

        // Just reload the UI components
        _gridKey.currentState?.reloadTiles();
        _wildcardKey.currentState?.reloadWildcardTiles();

        // Sync UI state
        scoreNotifier.value = SpelledWordsLogic.score;
        spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
        return;
      }
    }

    // Mark that we've loaded the app at least once
    await prefs.setBool('hasLoadedBefore', true);

    await StateManager.setStartTime();
    await _applyDebugControls();

    if (kIsWeb) {
      bool loggedIn = await _handleWebLogin(api);
      LogService.logInfo("🔄 Web loggedIn: $loggedIn");
      if (!loggedIn) return; // Exit if login failed
    }

    bool isNewUser = await StateManager.isNewUser();
    bool hasShownWelcome = await StateManager.hasShownWelcomeAnimation();

    // Set this here so that we use the API for existing users.
    if (!isNewUser) {
      var userData = await StateManager.getUserData();
      api.setUserInformation(userData);
    }

    // Handle welcome animation first
    if (debugForceIntroAnimation || !hasShownWelcome) {
      await WelcomeDialog.show(context, gameLayoutManager);
      await StateManager.markWelcomeAnimationShown();
    }

    if (isNewUser) {
      // New User Flow
      LogService.logInfo("👤 New User Detected - Registering...");
      await _handleNewUser(api);
    } else {
      // Returning User Flow
      LogService.logInfo("👤 Existing User Detected - Loading board...");
      await _loadBoardForUser(api);
    }

    _gridKey.currentState?.reloadTiles();
    _wildcardKey.currentState?.reloadWildcardTiles();

    // Final UI sync (only if we have tiles)
    if (GridLoader.gridTiles.isEmpty) {
      LogService.logError("❌ No tiles loaded! Showing failure dialog...");
      await FailureDialog.show(context, gameLayoutManager);
    } else {
      LogService.logInfo("✅ Board successfully loaded! Syncing UI...");
      scoreNotifier.value = SpelledWordsLogic.score;
      spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
    }
  }

  Future<void> _applyDebugControls() async {
    final prefs = await SharedPreferences.getInstance();

    if (debugClearPrefs) {
      await prefs.clear();
    }

    if (debugForceValidBoard) {
      final nowUtc = DateTime.now().toUtc();

      // Move to the next midnight UTC
      final nextMidnightUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1, 5, 5, 0, 0, 0);

      await prefs.setString('boardExpireDate', nextMidnightUtc.toIso8601String());
    }
  }

  Future<bool> _handleWebLogin(ApiService api) async {
    try {
      // Show login dialog and wait for result
      bool isLoggedIn = await LoginDialog.show(context, api, gameLayoutManager);

      // Log the attempt
      LogService.logError("🔄 Login attempt $loginAttempts: isLoggedIn: $isLoggedIn");

      if (!isLoggedIn) {
        // For web users, redirect to the main website on any failed login
        if (kIsWeb) {
          // Show failure dialog if this is the second or later attempt
          if (loginAttempts >= 1) {
            await FailureDialog.show(context, gameLayoutManager);
          }

          // Use a small delay to ensure the dialog is shown before redirecting
          await Future.delayed(const Duration(milliseconds: 500));

          // Redirect to the main website (without /api)
          LogService.logError("🔄 Redirecting web user to www.rewordgame.net");
          WebUtils.redirectToUrl('https://www.rewordgame.net');

          // Force exit the app after redirect
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }

          return false;
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // For web, we can't force exit, so just show a message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login required to play on web. Please try again later.')));
        }
        return false;
      }

      loginAttempts++;
      return isLoggedIn;
    } catch (e) {
      LogService.logError('Error during web login: $e');

      // For web users, redirect to the main website on error
      if (kIsWeb) {
        LogService.logError("🔄 Redirecting web user to www.rewordgame.net after error");
        WebUtils.redirectToUrl('https://www.rewordgame.net');

        // Force exit the app after redirect
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

      return false;
    }
  }

  Future<void> _handleNewUser(ApiService api) async {
    try {
      // Get locale based on platform
      String locale = 'en-US'; // Default for web
      String platform = 'Web'; // Default for web

      if (!kIsWeb) {
        try {
          locale = Platform.localeName;
          platform = 'Windows'; // Default for desktop

          // Set platform name based on actual platform
          if (Platform.isAndroid)
            platform = 'Android';
          else if (Platform.isIOS)
            platform = 'iOS';
          else if (Platform.isMacOS)
            platform = 'macOS';
          else if (Platform.isLinux)
            platform = 'Linux';
        } catch (e) {
          LogService.logError("Error getting platform info: $e");
        }
      }

      final response = await api.register(locale, platform);
      if (response.security == null) {
        LogService.logError('Error: Registration failed - null security');
        return;
      }

      // Important: New users are NOT logged in by default
      // They need to explicitly log in through the login dialog
      api.loggedIn = false;

      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      await GridLoader.loadNewBoard(api, finalScore);

      // Update UI with new board - use post-frame callback to ensure we're not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _gridKey.currentState?.reloadTiles();
          _wildcardKey.currentState?.reloadWildcardTiles();

          // Force rebuild to apply new board
          setState(() {});
        }
      });
    } catch (e) {
      LogService.logError('Error registering new user: $e');
    }
  }

  Future<void> _loadBoardForUser(ApiService api) async {
    try {
      // Skip loading a new board if we're handling an orientation change
      if (_isHandlingOrientationChange) {
        LogService.logInfo("🔄 Skipping board load during orientation change");
        return;
      }

      // First check if we need a new board
      final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();
      LogService.logInfo("🔄 Loading board for user... isExpired: $isExpired");

      final hasBoardData = await StateManager().hasBoardData();
      LogService.logInfo("🔄 Loading board for user... hasBoardData: $hasBoardData");

      // Force load a new board if we don't have board data or if it's expired
      if (!hasBoardData || isExpired) {
        LogService.logInfo("🔄 Loading new board...");
        LoadingDialog.show(context, gameLayoutManager, message: "Loading new board...");
        try {
          // Get the current score before resetting state
          final SubmitScoreRequest currentScore = await SpelledWordsLogic.getCurrentScore();

          // Check connectivity before loading new board
          if (!await ConnectivityMonitor().checkConnection()) {
            LogService.logError("🚨 Cannot load new board: No network connection");
            OfflineModeHandler.enterOfflineMode();

            // Show error dialog
            if (mounted) {
              ErrorHandler.handleError(
                context,
                ErrorHandler.NETWORK_ERROR,
                "Cannot load new board: No network connection",
                onRetry: () => _loadBoardForUser(api),
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
            await StateManager.resetState(_gridKey);

            // Ensure UI components are updated
            if (_gridKey.currentState != null) {
              LogService.logInfo("Reloading grid tiles after new board load");
              _gridKey.currentState!.reloadTiles();
            }

            if (_wildcardKey.currentState != null) {
              LogService.logInfo("Reloading wildcard tiles after new board load");
              _wildcardKey.currentState!.reloadWildcardTiles();
            }

            // Update score and spelled words
            scoreNotifier.value = SpelledWordsLogic.score;
            spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);

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
          if (mounted) LoadingDialog.dismiss(context);
        }
      } else {
        // Board is still valid, restore previous state
        LogService.logInfo("🔄 Restoring state...");
        await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

        // Ensure UI components are updated
        if (_gridKey.currentState != null) {
          LogService.logInfo("Reloading grid tiles after state restore");
          _gridKey.currentState!.reloadTiles();
        }

        if (_wildcardKey.currentState != null) {
          LogService.logInfo("Reloading wildcard tiles after state restore");
          _wildcardKey.currentState!.reloadWildcardTiles();
        }

        // Update score and spelled words
        scoreNotifier.value = SpelledWordsLogic.score;
        spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);

        LogService.logInfo("✅ State restored and UI updated");
      }
    } catch (e) {
      LogService.logError("🚨 Error in _loadBoardForUser: $e");
      ErrorReporting.reportException(e, StackTrace.current, context: 'Load board for user');

      // Show error dialog
      if (mounted) {
        ErrorHandler.handleError(
          context,
          ErrorHandler.DATA_ERROR,
          "Failed to load game board",
          onRetry: () => _loadBoardForUser(api),
        );
      }
    }
  }

  Future<bool> _shouldLoadNewBoard() async {
    final expiredTime = await StateManager.boardExpiredDuration();
    if (expiredTime == null || expiredTime > 120) {
      return true; // Auto-refresh if expired > 2 hours
    }
    return await BoardExpiredDialog.show(context, gameLayoutManager) ?? false; // Ask user if < 2 hours
  }

  void submitWord() {
    _gridKey.currentState?.submitWord();
  }

  void clearWords() {
    _gridKey.currentState?.clearSelectedTiles();
    _wildcardKey.currentState?.clearSelectedTiles();
    messageNotifier.value = '';
  }

  void _handleMessage(String message) {
    // Force the message notifier to update even if the message is the same
    // by temporarily setting it to empty and then to the actual message
    messageNotifier.value = '';
    // Use a small delay to ensure the empty message is processed
    Future.microtask(() {
      if (mounted) {
        messageNotifier.value = message;
      }
    });

    scoreNotifier.value = SpelledWordsLogic.score; // Sync on submit
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
  }

  void updateScoresRefresh() {
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
  }

  void updateCurrentGameState() {
    // Only update game state for web
    if (kIsWeb) {
      StateManager.saveState(_gridKey, _wildcardKey);
      StateManager.updatePlayTime();
    }
  }

  /// Toggle stack trace logging on/off
  /// This can be called from anywhere in the app to enable/disable stack traces
  static void toggleStackTraces(bool enable) {
    ErrorReporting.toggleStackTraceLogging(enable);
    // Show a message to confirm the change
    LogService.logInfo('Stack trace logging ${enable ? 'enabled' : 'disabled'}');
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    final isWebOverride = debugForceIsWeb ?? gameLayoutManager.isWeb;
    final isWeb = isWebOverride;

    // Set debug override if needed
    if (debugForceIsNarrow) {
      DeviceUtils.forceNarrowLayout = true;
    }

    // Determine if we should use narrow layout based on device type and orientation
    final useNarrowLayout = DeviceUtils.shouldUseNarrowLayout(context, NARROW_LAYOUT_THRESHOLD);

    // Update GameLayoutManager with spelledWordsNotifier
    gameLayoutManager.spelledWordsNotifier = spelledWordsNotifier;

    // Determine if we need to use SafeArea based on platform
    bool isMobilePlatform = false;
    if (!kIsWeb) {
      try {
        isMobilePlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        // Ignore platform errors on web
        LogService.logError("Error checking platform: $e");
      }
    }

    return Scaffold(
      body:
          isMobilePlatform
              ? SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child:
                      useNarrowLayout
                          ? NarrowScreen(
                            showBorders: debugShowBorders,
                            onSubmit: submitWord,
                            onClear: clearWords,
                            onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                            onHighScores:
                                () => HighScoresDialog.show(
                                  context,
                                  api, // Use the existing api instance from Provider
                                  SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                                  gameLayoutManager,
                                ),
                            onLegal: () => LegalDialog.show(context, api, gameLayoutManager),
                            onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                            api: api,
                            gameLayoutManager: gameLayoutManager,
                            spelledWordsLogic: SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                            gridKey: _gridKey,
                            wildcardKey: _wildcardKey,
                            onMessage: _handleMessage,
                            messageNotifier: messageNotifier,
                            scoreNotifier: scoreNotifier,
                            spelledWordsNotifier: spelledWordsNotifier,
                            updateScoresRefresh: updateScoresRefresh,
                            updateCurrentGameState: updateCurrentGameState,
                          )
                          : WideScreen(
                            showBorders: debugShowBorders,
                            onSubmit: submitWord,
                            onClear: clearWords,
                            onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                            onHighScores:
                                () => HighScoresDialog.show(
                                  context,
                                  api, // Use the existing api instance from Provider
                                  SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                                  gameLayoutManager,
                                ),
                            onLegal: () => LegalDialog.show(context, api, gameLayoutManager),
                            onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                            api: api,
                            gameLayoutManager: gameLayoutManager,
                            spelledWordsLogic: SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                            gridKey: _gridKey,
                            wildcardKey: _wildcardKey,
                            onMessage: _handleMessage,
                            messageNotifier: messageNotifier,
                            scoreNotifier: scoreNotifier,
                            spelledWordsNotifier: spelledWordsNotifier,
                            updateScoresRefresh: updateScoresRefresh,
                            updateCurrentGameState: updateCurrentGameState,
                          ),
                ),
              )
              : SizedBox(
                // For non-mobile platforms, we don't need SafeArea
                width: double.infinity,
                height: double.infinity,
                child:
                    useNarrowLayout
                        ? NarrowScreen(
                          showBorders: debugShowBorders,
                          onSubmit: submitWord,
                          onClear: clearWords,
                          onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                          onHighScores:
                              () => HighScoresDialog.show(
                                context,
                                api, // Use the existing api instance from Provider
                                SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                                gameLayoutManager,
                              ),
                          onLegal: () => LegalDialog.show(context, api, gameLayoutManager),
                          onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                          api: api,
                          gameLayoutManager: gameLayoutManager,
                          spelledWordsLogic: SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                          gridKey: _gridKey,
                          wildcardKey: _wildcardKey,
                          onMessage: _handleMessage,
                          messageNotifier: messageNotifier,
                          scoreNotifier: scoreNotifier,
                          spelledWordsNotifier: spelledWordsNotifier,
                          updateScoresRefresh: updateScoresRefresh,
                          updateCurrentGameState: updateCurrentGameState,
                        )
                        : WideScreen(
                          showBorders: debugShowBorders,
                          onSubmit: submitWord,
                          onClear: clearWords,
                          onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                          onHighScores:
                              () => HighScoresDialog.show(
                                context,
                                api, // Use the existing api instance from Provider
                                SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                                gameLayoutManager,
                              ),
                          onLegal: () => LegalDialog.show(context, api, gameLayoutManager),
                          onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                          api: api,
                          gameLayoutManager: gameLayoutManager,
                          spelledWordsLogic: SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                          gridKey: _gridKey,
                          wildcardKey: _wildcardKey,
                          onMessage: _handleMessage,
                          messageNotifier: messageNotifier,
                          scoreNotifier: scoreNotifier,
                          spelledWordsNotifier: spelledWordsNotifier,
                          updateScoresRefresh: updateScoresRefresh,
                          updateCurrentGameState: updateCurrentGameState,
                        ),
              ),
    );
  }
}
