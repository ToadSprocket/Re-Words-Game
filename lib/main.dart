// File: /lib/main.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'styles/app_styles.dart';
import 'logic/game_layout.dart';
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'dialogs/failure_dialog.dart';
import 'components/error_boundary.dart';
import 'logic/error_reporting.dart';
import 'package:provider/provider.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import 'package:window_size/window_size.dart';
import 'dialogs/welcome_dialog.dart';
import 'dialogs/board_expired_dialog.dart';
import 'dialogs/new_board_loaded_dialog.dart';
import 'config/config.dart';
import 'dialogs/androidTabletDialog.dart';
import 'utils/device_utils.dart';
import 'providers/orientation_provider.dart';
import 'managers/gameManager.dart';
import 'config/debugConfig.dart';

// App version information
const String MAJOR = "2";
const String MINOR = "0";
const String PATCH = "0";
const String BUILD = "00";
const String PHASE = "A";

const String VERSION_STRING = "v$MAJOR.$MINOR.$PATCH+$BUILD-$PHASE";

// Window size constants for the initialization routines
const double MIN_WINDOW_WIDTH = 1000.0;
const double MIN_WINDOW_HEIGHT = 800.0;
const double NARROW_LAYOUT_THRESHOLD = 900.0;
const double INITIAL_WINDOW_WIDTH = 1024.0;
const double INITIAL_WINDOW_HEIGHT = 768.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging based on build mode
  LogService.configureLogging(DebugConfig().logLevel);

  // Initialize error reporting
  await ErrorReporting.initialize();

  // Disable stack trace logging by default (can be toggled at runtime)
  ErrorReporting.logStackTraces = DebugConfig().logStackTraces;

  // Initialize GameManager (handles ApiService, WordService, UserManager, Board)
  await GameManager().initialize();

  final GameLayoutManager layoutManager = GameLayoutManager();

  // Non-web platforms will initialize differently
  runApp(
    MultiProvider(
      providers: [
        // GameManager is now the central provider (it contains ApiService internally)
        ChangeNotifierProvider<GameManager>.value(value: GameManager()),
        // Keep OrientationProvider for now - will consolidate in Phase 5
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
                orientationProvider.changeOrientation(orientation, MediaQuery.of(context).size, context);
              }
            });

            // Get the orientation provider
            // final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Ensure this runs only after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set orientation settings based on device type
      DeviceUtils.setOrientationSettings(context);

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
        if (Platform.isWindows || Platform.isMacOS) {
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
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 ENTRY: didChangeDependencies");

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

          // Update the orientation provider with raw dimensions
          orientationProvider.changeOrientation(currentOrientation, currentSize, context);

          // Let the board manager handle orientation change
          await GameManager().handleOrientationChange();

          // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
          setState(() {
            LogService.logInfo("Rebuilding UI with new layout sizes from dependencies");
          });
        }
      }
    });
  }

  Future<void> _initializeGame() async {
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 ENTRY: _initializeGame");
    final gm = GameManager();

    // Setup game layout.
    gm.initializeLayout(context);

    // Two-tier expiration logic using minutesBoardIsExpired() (local timezone):
    //   > grace period  → auto-load new board, show "New Board Loaded" info dialog
    //   ≤ grace period  → show choice dialog (load new / keep playing)
    //   0 minutes       → board is current, no action needed
    final minutesExpired = await gm.board.minutesBoardIsExpired();
    final forceExpired = DebugConfig().forceExpiredBoard;
    LogService.logEvent("LCYCL:InitExpChk:${minutesExpired}m");

    if ((forceExpired || minutesExpired > 0) && gm.isBoardReady) {
      if (minutesExpired > Config.expiredBoardGracePeriodMinutes || forceExpired) {
        // Past grace period — force-load a new board without asking
        LogService.logInfo(
          "🔄 Board expired ${minutesExpired}m (>${Config.expiredBoardGracePeriodMinutes}m grace) — auto-loading",
        );
        final success = await gm.loadNewBoard();
        if (success && mounted) {
          // Show simple confirmation dialog
          await NewBoardLoadedDialog.show(context);
        } else if (!success) {
          gm.setMessage('Server unavailable — playing with current board');
        }
      } else {
        // Within grace period — let the user choose
        LogService.logInfo(
          "🔄 Board expired ${minutesExpired}m (≤${Config.expiredBoardGracePeriodMinutes}m grace) — showing choice",
        );
        final loadNew = await BoardExpiredDialog.show(context);

        if (loadNew == true) {
          // User chose "Yes" — load a fresh board from the server
          final success = await gm.loadNewBoard();
          if (!success) {
            gm.setMessage('Server unavailable — playing with current board');
          }
        } else {
          // User chose "No" — mark as playing expired so we don't re-prompt on resume
          gm.board = gm.board.copyWith(isPlayingExpired: true);
          await gm.board.saveBoardToStorage();
          LogService.logInfo("🎮 User chose to continue playing expired board at startup");
        }
      }
    } else if ((forceExpired || minutesExpired > 0) && !gm.isBoardReady) {
      // No usable board at all — must load from server (first launch or corrupted data)
      LogService.logInfo("🔄 No valid board at startup — loading new board from server");
      final success = await gm.loadNewBoard();

      if (!success && !gm.isBoardReady) {
        if (mounted) {
          await FailureDialog.show(
            context,
            title: "Error loading new board",
            message: "Unable to connect to server. Please check your connection and try again.",
            onRetry: () => _initializeGame(),
          );
        }
      }
    }

    // Mark startup complete — enables lifecycle handlers (onAppResume, handleOrientationChange)
    gm.setBoardStartupCompleted();

    // Start the countdown timer so the top bar shows time remaining
    gm.startCountdownTimer();

    await _loadData();
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 EXIT: _initializeGame");
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
    // Stop the countdown timer to avoid leaking resources
    GameManager().stopCountdownTimer();
    GameManager().saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 ENTRY: didChangeAppLifecycleState ($state)");
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // Save state and pause session when app goes to background
      GameManager().onAppPause();
      LogService.logInfo("App lifecycle: PAUSED - Game state saved");
    } else if (state == AppLifecycleState.resumed) {
      // Resume session and check if board expired
      LogService.logInfo("App lifecycle: RESUMED - Checking game state");
      GameManager().onAppResume();

      // Check board expiration after resume — must be done here (not in GameManager)
      // because we need BuildContext to show the BoardExpiredDialog
      _checkBoardExpirationOnResume();
    }
  }

  @override
  void onWindowClose() async {
    LogService.logInfo("🔄 Window close event detected - Saving state...");
    try {
      // Save state before closing
      await GameManager().saveState();
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
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 ENTRY: didChangeMetrics");

    // Ensure we're not in the build phase by using post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Get the current orientation and size
        final currentOrientation = MediaQuery.of(context).orientation;
        final currentSize = MediaQuery.of(context).size;

        // Get the orientation provider
        final orientationProvider = Provider.of<OrientationProvider>(context, listen: false);

        final newOrientaion = orientationProvider.orientation;
        final newSize = orientationProvider.currentSize;

        // Check if orientation or size has actually changed
        bool hasChanged = newOrientaion != currentOrientation || newSize != currentSize;

        if (hasChanged) {
          LogService.logInfo(
            "Screen Metrics changed - current orientation: $currentOrientation, new orientation: $newOrientaion, current size: $currentSize, new size: $newSize",
          );

          // Update the orientation provider with raw dimensions
          orientationProvider.changeOrientation(currentOrientation, currentSize, context);

          // Let the board manager handle orientation change
          await GameManager().handleOrientationChange();

          // Force rebuild to apply new sizes - safe to call setState here since we're in a post-frame callback
          setState(() {
            LogService.logInfo("Rebuilding UI with new layout sizes");
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    if (DebugConfig().traceMethodCalls) LogService.logInfo("📍 ENTRY: _loadData");
    final gm = GameManager();

    // Check if user has seen welcome animation (tracked in UserManager)
    bool hasShownWelcome = await gm.userManager.hasShownWelcome();

    // Handle welcome animation for first-time users
    if (DebugConfig().forceIntroAnimation || !hasShownWelcome) {
      if (gameLayoutManager.isTablet && Platform.isAndroid) {
        await AndroidTabletDialog.show(context);
      }
      await WelcomeDialog.show(context, gm);
      await gm.userManager.markWelcomeShown();
    }

    // If board is empty/new, load from server
    if (!gm.isBoardReady) {
      await gm.loadNewBoard();
    }

    // Sync UI with board data
    gm.syncUIComponents();
  }

  /// Checks board expiration on app resume using the same two-tier logic as startup.
  /// This lives here instead of GameManager because it needs BuildContext for dialogs.
  Future<void> _checkBoardExpirationOnResume() async {
    final gm = GameManager();

    // Skip if board is already flagged as playing-expired (user already chose "No")
    if (gm.board.isPlayingExpired) {
      LogService.logEvent("LCYCL:ExpChk:SkipPlayingExpired");
      return;
    }

    // Calculate minutes since local midnight — 0 means board is still current
    final minutesExpired = await gm.board.minutesBoardIsExpired();
    LogService.logEvent("LCYCL:ExpChk:${minutesExpired}m");
    if (minutesExpired == 0 || !mounted) return;

    if (minutesExpired > Config.expiredBoardGracePeriodMinutes) {
      // Past grace period — force-load a new board without asking
      LogService.logInfo(
        "⏰ Resume: Board expired ${minutesExpired}m (>${Config.expiredBoardGracePeriodMinutes}m) — auto-loading",
      );
      final success = await gm.loadNewBoard();
      if (success) {
        gm.startCountdownTimer();
        if (mounted) {
          await NewBoardLoadedDialog.show(context);
        }
        // Sync UI after dialog is dismissed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          gm.syncUIComponents();
        });
      } else {
        gm.setMessage('Server unavailable — playing with current board');
      }
    } else {
      // Within grace period — let the user choose
      LogService.logInfo(
        "⏰ Resume: Board expired ${minutesExpired}m (≤${Config.expiredBoardGracePeriodMinutes}m) — showing choice",
      );
      final loadNew = await BoardExpiredDialog.show(context);

      if (loadNew == true) {
        // User chose "Yes" — load a fresh board from the server
        final success = await gm.loadNewBoard();
        if (success) {
          gm.startCountdownTimer();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gm.syncUIComponents();
          });
        } else {
          gm.setMessage('Server unavailable — playing with current board');
        }
      } else {
        // User chose "No" (or dismissed) — mark board as playing-expired
        // so we don't re-prompt, and persist the flag
        gm.board = gm.board.copyWith(isPlayingExpired: true);
        await gm.board.saveBoardToStorage();
        gm.notifyListeners();
        LogService.logInfo("🎮 User chose to continue playing expired board on resume");
      }
    }
  }

  // Delegate methods to GameManager
  void submitWord() => GameManager().submitWord();
  void clearWords() => GameManager().clearWords();
  void _handleMessage(String message) => GameManager().setMessage(message);
  void updateScoresRefresh() => GameManager().notifyListeners();
  void updateCurrentGameState() => GameManager().saveState();

  /// Toggle stack trace logging on/off
  /// This can be called from anywhere in the app to enable/disable stack traces
  static void toggleStackTraces(bool enable) {
    ErrorReporting.toggleStackTraceLogging(enable);
    // Show a message to confirm the change
    LogService.logInfo('Stack trace logging ${enable ? 'enabled' : 'disabled'}');
  }

  @override
  Widget build(BuildContext context) {
    // Set debug override if needed
    if (DebugConfig().forceIsNarrow) {
      DeviceUtils.forceNarrowLayout = true;
    }

    // Determine if we should use narrow layout
    final useNarrowLayout = DeviceUtils.shouldUseNarrowLayout(context, NARROW_LAYOUT_THRESHOLD);

    // Determine if we need SafeArea (mobile only)
    bool isMobilePlatform = false;
    if (!kIsWeb) {
      try {
        isMobilePlatform = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        LogService.logError("Error checking platform: $e");
      }
    }

    // Build the appropriate screen layout
    Widget screen = useNarrowLayout ? NarrowScreen() : WideScreen();

    return Scaffold(
      body:
          isMobilePlatform
              ? SafeArea(child: SizedBox(width: double.infinity, height: double.infinity, child: screen))
              : SizedBox(width: double.infinity, height: double.infinity, child: screen),
    );
  }
}
