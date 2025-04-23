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
import '../managers/board_manager.dart';
import 'package:window_size/window_size.dart';
import 'dialogs/welcome_dialog.dart';
import 'dialogs/loading_dialog.dart';
import 'dialogs/androidTabletDialog.dart';
import 'services/word_service.dart';
import 'utils/web_utils.dart';
import 'utils/connectivity_monitor.dart';
import 'utils/offline_mode_handler.dart';
import 'utils/device_utils.dart';
import 'providers/orientation_provider.dart';
import 'providers/game_state_provider.dart';
import 'models/game_mode.dart';

// App version information
const String MAJOR = "1";
const String MINOR = "0";
const String PATCH = "0";
const String BUILD = "48";

const String VERSION_STRING = "v$MAJOR.$MINOR.$PATCH+$BUILD";

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;
const bool debugForceIsNarrow = false;
const bool disableSpellCheck = false;
const bool debugForceExpiredBoard = false; // Force expired board
const bool debugForceValidBoard = false; // Force valid board
const bool debugClearPrefs = false; // Clear all prefs for new user
const bool debugForceIntroAnimation = false; // Force intro animation to play
const bool debugDisableSecretReset = false; // Disable the secret title reset feature

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
        ChangeNotifierProvider<GameStateProvider>(create: (context) => GameStateProvider()),
        Provider<BoardManager>.value(
          value: BoardManager(
            gameLayoutManager: layoutManager,
            debugForceExpiredBoard: debugForceExpiredBoard,
            disableSpellCheck: disableSpellCheck,
          ),
        ),
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
  // Use providers for state management
  final GameLayoutManager gameLayoutManager = GameLayoutManager();
  Map<String, dynamic>? sizes;
  int loginAttempts = 0;
  late BoardManager boardManager;
  late GameStateProvider gameStateProvider;

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

      // Initialize and load game data
      _initializeGame();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get providers
    boardManager = Provider.of<BoardManager>(context, listen: false);
    gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);

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

          // Update the orientation provider
          orientationProvider.changeOrientation(currentOrientation, currentSize);

          // Let the board manager handle orientation change
          await boardManager.handleOrientationChange(context);

          // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
          setState(() {
            LogService.logInfo("Rebuilding UI with new layout sizes from dependencies");
          });
        }
      }
    });
  }

  Future<void> _initializeGame() async {
    await boardManager.initialize(context);

    // Initialize game state provider with default values
    gameStateProvider.syncWithSpelledWordsLogic();

    // Restore saved state (including board state)
    await gameStateProvider.restoreState();

    await _loadData();
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
    boardManager.saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Save current state when app is paused
      boardManager.saveState();
      StateManager.savePauseTime();
      LogService.logInfo("App lifecycle: PAUSED - Game state saved");
    } else if (state == AppLifecycleState.resumed) {
      // Handle app resume
      LogService.logInfo("App lifecycle: RESUMED - Checking game state");
      boardManager.handleAppResume(context);
    }
  }

  @override
  void onWindowClose() async {
    LogService.logInfo("🔄 Window close event detected - Saving state...");
    try {
      // Save state before closing
      await boardManager.saveState();
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

          // Update the orientation provider
          orientationProvider.changeOrientation(currentOrientation, currentSize);

          // Let the board manager handle orientation change
          await boardManager.handleOrientationChange(context);

          // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
          setState(() {
            LogService.logInfo("Rebuilding UI with new layout sizes");
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    final api = Provider.of<ApiService>(context, listen: false);

    if (kIsWeb) {
      bool loggedIn = await _handleWebLogin(api);
      LogService.logInfo("🔄 Web loggedIn: $loggedIn");
      if (!loggedIn) return; // Exit if login failed
    }

    bool hasShownWelcome = await StateManager.hasShownWelcomeAnimation();

    // Handle welcome animation first
    if (debugForceIntroAnimation || !hasShownWelcome) {
      if (gameLayoutManager.isTablet && Platform.isAndroid) {
        await AndroidTabletDialog.show(context, gameLayoutManager);
      }
      await WelcomeDialog.show(context, gameLayoutManager);
      await StateManager.markWelcomeAnimationShown();
    }

    // Load the board data using BoardManager
    await boardManager.loadData(context);
  }

  // Handle web login separately since it's specific to the UI flow
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

  // Delegate methods to BoardManager
  void submitWord() => boardManager.submitWord();
  void clearWords() => boardManager.clearWords();
  void _handleMessage(String message) => boardManager.handleMessage(message);
  void updateScoresRefresh() => boardManager.updateScoresRefresh();
  void updateCurrentGameState() {
    // Only update game state for web
    if (kIsWeb) boardManager.saveState();
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
    gameLayoutManager.spelledWordsNotifier = boardManager.spelledWordsNotifier;

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
                            gridKey: boardManager.gridKey,
                            wildcardKey: boardManager.wildcardKey,
                            onMessage: _handleMessage,
                            messageNotifier: boardManager.messageNotifier,
                            scoreNotifier: boardManager.scoreNotifier,
                            spelledWordsNotifier: boardManager.spelledWordsNotifier,
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
                            gridKey: boardManager.gridKey,
                            wildcardKey: boardManager.wildcardKey,
                            onMessage: _handleMessage,
                            messageNotifier: boardManager.messageNotifier,
                            scoreNotifier: boardManager.scoreNotifier,
                            spelledWordsNotifier: boardManager.spelledWordsNotifier,
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
                          gridKey: boardManager.gridKey,
                          wildcardKey: boardManager.wildcardKey,
                          onMessage: _handleMessage,
                          messageNotifier: boardManager.messageNotifier,
                          scoreNotifier: boardManager.scoreNotifier,
                          spelledWordsNotifier: boardManager.spelledWordsNotifier,
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
                          gridKey: boardManager.gridKey,
                          wildcardKey: boardManager.wildcardKey,
                          onMessage: _handleMessage,
                          messageNotifier: boardManager.messageNotifier,
                          scoreNotifier: boardManager.scoreNotifier,
                          spelledWordsNotifier: boardManager.spelledWordsNotifier,
                          updateScoresRefresh: updateScoresRefresh,
                          updateCurrentGameState: updateCurrentGameState,
                        ),
              ),
    );
  }
}
