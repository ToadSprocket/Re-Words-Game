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
import 'logic/word_loader.dart';
import 'logic/spelled_words_handler.dart';
import 'package:provider/provider.dart';
import 'models/api_models.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';

const bool debugShowBorders = true;
const bool? debugForceIsWeb = null;
const bool debugForceExpiredBoard = false; // Force expired board
const bool debugForceValidBoard = false; // Force valid board
const bool debugClearPrefs = false; // Clear all prefs for new user

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GameLayoutManager layoutManager = GameLayoutManager();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1440, 700),
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

  runApp(
    ChangeNotifierProvider<ApiService>(
      create: (context) => ApiService(),
      child: ReWordApp(layoutManager: layoutManager), // ✅ Pass it in
    ),
  );
}

class ReWordApp extends StatelessWidget {
  GameLayoutManager layoutManager = GameLayoutManager();

  ReWordApp({super.key, required this.layoutManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Word Game',
      theme: AppStyles.appTheme,
      home: GameLayoutProvider(gameLayoutManager: layoutManager, child: HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.addListener(this);
    }
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    await windowManager.destroy();
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

    await WordLoader.loadWords();
    await StateManager.setStartTime(); // Set start time for new session
    await _applyDebugControls();
    final userData = await StateManager.getUserData();
    bool isNewUser = await StateManager.isNewUser();

    // ✅ Restore previous game state BEFORE making any decisions
    await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

    if (isNewUser) {
      LogService.logInfo("👤 New User Detected - Registering...");
      await _handleNewUser(api);
    } else {
      LogService.logInfo("👤 Existing User Detected - Loading board...");
      await _handleExistingUser(api, userData);
    }

    // 🚨 **Ensure we have a valid board loaded before continuing**
    if (GridLoader.gridTiles.isEmpty) {
      LogService.logError("❌ No tiles loaded! Showing failure dialog...");
      await FailureDialog.show(context, gameLayoutManager);
    } else {
      LogService.logInfo("✅ Board successfully loaded! Syncing UI...");

      // ✅ Ensure UI updates after loading board
      scoreNotifier.value = SpelledWordsLogic.score;
      spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);

      if (isNewUser) {
        // Only reload tiles for new users
        _gridKey.currentState?.reloadTiles();
        _wildcardKey.currentState?.reloadWildcardTiles();
      }
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

  Future<void> _handleNewUser(ApiService api) async {
    try {
      final response = await api.register(Platform.localeName, 'Windows');
      if (response.security == null) {
        LogService.logError('Error: Registration failed - null security');
        return;
      }
      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      await GridLoader.loadNewBoard(api, finalScore); // This fetches and saves gameData
    } catch (e) {
      LogService.logError('Error registering new user: $e');
    }
  }

  Future<void> _handleExistingUser(ApiService api, Map<String, String?> userData) async {
    final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();

    // ✅ Restore previous game state BEFORE making a decision
    //await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);

    if (isExpired) {
      // ✅ Ensure we calculate the score BEFORE switching boards
      final SubmitScoreRequest finalScore = await SpelledWordsLogic.getCurrentScore();
      final loadNewBoard = await _shouldLoadNewBoard();
      if (loadNewBoard) {
        // ✅ Reset game state before loading a new board
        await StateManager.resetState(_gridKey);

        bool success = await GridLoader.loadNewBoard(api, finalScore);
        if (success) {
          await _gridKey.currentState?.reloadTiles();
          await _wildcardKey.currentState?.reloadWildcardTiles();
        } else {
          LogService.logError("❌ Failed to load new board. Falling back to stored board.");
          await GridLoader.loadStoredBoard();
        }
      } else {
        await GridLoader.loadStoredBoard();
      }
    } else {
      await GridLoader.loadStoredBoard();
    }

    // ✅ Make sure UI is updated
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
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

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final isWebOverride = debugForceIsWeb ?? gameLayoutManager.isWeb;
    final isWeb = isWebOverride;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child:
            isWeb
                ? WideScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                  onHighScores:
                      () => HighScoresDialog.show(context, ApiService(), SpelledWordsLogic(), gameLayoutManager),
                  onLegal: () => LegalDialog.show(context, gameLayoutManager),
                  onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                  api: api,
                  gameLayoutManager: gameLayoutManager,
                  spelledWordsLogic: SpelledWordsLogic(),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage,
                  messageNotifier: messageNotifier, // Pass notifier
                  scoreNotifier: scoreNotifier, // Pass notifier
                  spelledWordsNotifier: spelledWordsNotifier, // Pass notifier
                  updateScoresRefresh: updateScoresRefresh,
                )
                : NarrowScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context, gameLayoutManager),
                  onHighScores:
                      () => HighScoresDialog.show(context, ApiService(), SpelledWordsLogic(), gameLayoutManager),
                  onLegal: () => LegalDialog.show(context, gameLayoutManager),
                  onLogin: () => LoginDialog.show(context, api, gameLayoutManager),
                  api: api,
                  gameLayoutManager: gameLayoutManager,
                  spelledWordsLogic: SpelledWordsLogic(),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage,
                  messageNotifier: messageNotifier, // Pass notifier
                  scoreNotifier: scoreNotifier, // Pass notifier
                  spelledWordsNotifier: spelledWordsNotifier, // Pass notifier
                  updateScoresRefresh: updateScoresRefresh,
                ),
      ),
    );
  }
}
