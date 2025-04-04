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
import 'managers/state_manager.dart';
import 'logic/api_service.dart';
import 'logic/spelled_words_handler.dart';
import 'package:provider/provider.dart';
import 'models/api_models.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';
import 'package:window_size/window_size.dart';
import 'dialogs/welcome_dialog.dart';
import 'dialogs/loading_dialog.dart';
import 'services/word_service.dart';
import 'utils/web_utils.dart';

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

  final wordService = WordService();
  await wordService.initialize();

  final GameLayoutManager layoutManager = GameLayoutManager();

  // Non-web platforms will initialize differently
  runApp(
    ChangeNotifierProvider<ApiService>(
      create: (context) => ApiService(),
      child: ReWordApp(layoutManager: layoutManager),
    ),
  );

  // Set minimum window size and initial window size
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
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
}

class ReWordApp extends StatelessWidget {
  final GameLayoutManager layoutManager;
  final String? userId;
  final String? authToken;

  ReWordApp({super.key, required this.layoutManager, this.userId, this.authToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Word Game',
      theme: AppStyles.appTheme,
      home: GameLayoutProvider(
        gameLayoutManager: layoutManager,
        child: HomeScreen(userId: userId, authToken: authToken),
      ),
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
      gameLayoutManager.calculateLayoutSizes(context);
      setState(() {}); // ✅ Force rebuild to apply new sizes
    });

    // Only add window manager listener for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.addListener(this);
    }
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Only remove window manager listener for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    StateManager.saveState(_gridKey, _wildcardKey);
    StateManager.updatePlayTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      StateManager.saveState(_gridKey, _wildcardKey);
    }
  }

  @override
  void onWindowClose() async {
    await StateManager.saveState(_gridKey, _wildcardKey);
    await StateManager.updatePlayTime();
    super.onWindowClose();
    // Only destroy window manager for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.destroy();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Force recalculation and rebuild when screen metrics change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          gameLayoutManager.calculateLayoutSizes(context);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force recalculation when dependencies change
    gameLayoutManager.calculateLayoutSizes(context);
    setState(() {});
  }

  Future<void> _loadData() async {
    final api = Provider.of<ApiService>(context, listen: false);

    await StateManager.setStartTime();
    await _applyDebugControls();

    if (kIsWeb) {
      bool loggedIn = await _handleWebLogin(api);
      LogService.logError("🔄 Web loggedIn: $loggedIn");
      if (!loggedIn) return; // Exit if login failed
    }

    bool isNewUser = await StateManager.isNewUser();
    bool hasShownWelcome = await StateManager.hasShownWelcomeAnimation();

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
      String locale = kIsWeb ? 'en-US' : Platform.localeName;
      final response = await api.register(locale, kIsWeb ? 'Web' : 'Windows');
      if (response.security == null) {
        LogService.logError('Error: Registration failed - null security');
        return;
      }

      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      await GridLoader.loadNewBoard(api, finalScore);

      // Update UI with new board
      setState(() {
        _gridKey.currentState?.reloadTiles();
        _wildcardKey.currentState?.reloadWildcardTiles();
      });
    } catch (e) {
      LogService.logError('Error registering new user: $e');
    }
  }

  Future<void> _loadBoardForUser(ApiService api) async {
    // First check if we need a new board
    final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();
    LogService.logError("🔄 Loading board for user... isExpired: $isExpired");

    final hasBoardData = await StateManager().hasBoardData();
    LogService.logError("🔄 Loading board for user... hasBoardData: $hasBoardData");

    if (isExpired || !hasBoardData) {
      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      var loadNewBoard = false;
      // If we have board data, ask the user if they want to load a new board
      if (hasBoardData) {
        loadNewBoard = await _shouldLoadNewBoard();
      }

      if (loadNewBoard || !hasBoardData) {
        LogService.logError("🔄 Loading new board...");
        LoadingDialog.show(context, gameLayoutManager, message: "Loading new board...");
        try {
          await StateManager.resetState(_gridKey);
          bool success = await GridLoader.loadNewBoard(api, finalScore);
          if (!success) {
            LogService.logError("❌ Failed to load new board. Falling back to stored board.");
            await GridLoader.loadStoredBoard();
          }
        } finally {
          if (mounted) LoadingDialog.dismiss(context);
        }
      } else {
        LogService.logError("🔄 Falling back to stored board...");
        await GridLoader.loadStoredBoard();
      }
    } else {
      // Board is still valid, restore previous state
      LogService.logError("🔄 Restoring state...");
      await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);
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
    messageNotifier.value = message;
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

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final isWebOverride = debugForceIsWeb ?? gameLayoutManager.isWeb;
    final isWeb = isWebOverride;

    // Get the current window width
    final windowWidth = MediaQuery.of(context).size.width;

    // Determine if we should use narrow layout
    final useNarrowLayout = debugForceIsNarrow || (!isWeb && windowWidth < NARROW_LAYOUT_THRESHOLD);

    // Update GameLayoutManager with spelledWordsNotifier
    gameLayoutManager.spelledWordsNotifier = spelledWordsNotifier;

    return Scaffold(
      body: SizedBox(
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
                        ApiService(),
                        SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                        gameLayoutManager,
                      ),
                  onLegal: () => LegalDialog.show(context, gameLayoutManager),
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
                        ApiService(),
                        SpelledWordsLogic(disableSpellCheck: disableSpellCheck),
                        gameLayoutManager,
                      ),
                  onLegal: () => LegalDialog.show(context, gameLayoutManager),
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
