// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
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
import 'components/game_grid_component.dart';
import 'components/wildcard_column_component.dart';
import 'managers/state_manager.dart';
import 'logic/api_service.dart';
import 'models/api_models.dart';
import 'logic/word_loader.dart';
import 'logic/spelled_words_handler.dart';

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;
const bool debugForceExpiredBoard = false; // Force expired board
const bool debugForceValidBoard = false; // Force valid board
const bool debugClearPrefs = false; // Clear all prefs for new user

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1440, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const ReWordApp());
}

class ReWordApp extends StatelessWidget {
  const ReWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Word Game',
      theme: AppStyles.appTheme,
      home: const GameLayoutProvider(child: HomeScreen()),
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
  Map<String, dynamic>? sizes;
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.addListener(this);
    }
    _sessionStart = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    StateManager.updatePlayTime(_sessionStart);
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    StateManager.saveState(_gridKey, _wildcardKey);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      StateManager.updatePlayTime(_sessionStart);
      StateManager.saveState(_gridKey, _wildcardKey);
    }
  }

  @override
  void onWindowClose() async {
    StateManager.updatePlayTime(_sessionStart);
    await StateManager.saveState(_gridKey, _wildcardKey);
    super.onWindowClose();
    await windowManager.destroy();
  }

  Future<void> _loadData() async {
    final api = ApiService();
    await WordLoader.loadWords();
    await _applyDebugControls();
    final userData = await StateManager.getUserData();
    bool isNewUser = await StateManager.isNewUser();
    if (isNewUser) {
      await _handleNewUser(api);
    } else {
      await _handleExistingUser(api, userData);
      await StateManager.restoreState(_gridKey, _wildcardKey, scoreNotifier, spelledWordsNotifier);
    }
    if (GridLoader.gridTiles.isEmpty) {
      await FailureDialog.show(context);
      print('Load failed: No tiles');
    } else {
      print('Load succeeded: ${GridLoader.gridTiles.length} tiles');
      if (isNewUser) {
        // Only reload for new users
        _gridKey.currentState?.reloadTiles();
        _wildcardKey.currentState?.reloadWildcardTiles();
      }
      // Sync notifiers (safe fallback)
      scoreNotifier.value = SpelledWordsLogic.score;
      spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
    }
  }

  Future<void> _applyDebugControls() async {
    final prefs = await SharedPreferences.getInstance();
    if (debugClearPrefs) {
      await prefs.clear();
      print('Debug: Cleared all preferences');
    }
    if (debugForceValidBoard) {
      await prefs.setString('boardExpireDate', DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String());
      print('Debug: Forced valid board with future expiry');
    }
  }

  Future<void> _handleNewUser(ApiService api) async {
    try {
      final response = await api.register(Platform.localeName, 'Windows');
      if (response.security == null) {
        print('Error: Registration failed - null security');
        return;
      }
      if (response.security != null) {
        await StateManager.saveUserData(response.security!);
      } else {
        print('Error: Registration failed - null security');
      }
      await GridLoader.loadNewBoard(api); // This fetches and saves gameData
      print('New user loaded: ${GridLoader.gridTiles}');
    } catch (e) {
      print('Error registering new user: $e');
    }
  }

  Future<void> _handleExistingUser(ApiService api, Map<String, String?> userData) async {
    api.userId = userData['userId'];
    api.accessToken = userData['accessToken'];
    api.refreshToken = userData['refreshToken'];

    final isExpired = debugForceExpiredBoard || await StateManager.isBoardExpired();
    if (isExpired) {
      final loadNewBoard = await _shouldLoadNewBoard();
      if (loadNewBoard) {
        await StateManager.updatePlayTime(_sessionStart);
        await GridLoader.loadNewBoard(api);
        await _gridKey.currentState?.reloadTiles();
        await _wildcardKey.currentState?.reloadWildcardTiles();
        print('New board loaded: ${GridLoader.gridTiles}');
      } else {
        await GridLoader.loadStoredBoard();
        print('Stored board loaded: ${GridLoader.gridTiles}');
      }
    } else {
      await GridLoader.loadStoredBoard();
      print('Stored board loaded: ${GridLoader.gridTiles}');
    }
  }

  Future<bool> _shouldLoadNewBoard() async {
    final expiredTime = await StateManager.boardExpiredDuration();
    if (expiredTime != null && expiredTime <= 120) {
      return true; // Auto-refresh if expired <= 2 hours
    }
    return await BoardExpiredDialog.show(context) ?? false; // Ask user if > 2 hours
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sizes = GameLayout.of(context).sizes;
    print('HomeScreen didChangeDependencies - sizes set');
  }

  void submitWord() {
    _gridKey.currentState?.submitWord();
  }

  void clearWords() {
    _gridKey.currentState?.clearSelectedTiles();
    _wildcardKey.currentState?.clearSelectedTiles();
    messageNotifier.value = '';
    print('Clear clicked');
  }

  void _handleMessage(String message) {
    messageNotifier.value = message;
    scoreNotifier.value = SpelledWordsLogic.score; // Sync on submit
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
    print('Updated: Message: $message, Score: ${scoreNotifier.value}, Words: ${spelledWordsNotifier.value}');
  }

  void updateScoresRefresh() {
    scoreNotifier.value = SpelledWordsLogic.score;
    spelledWordsNotifier.value = List.from(SpelledWordsLogic.spelledWords);
    print('Scores refreshed: Score: ${scoreNotifier.value}, Words: ${spelledWordsNotifier.value}');
  }

  @override
  Widget build(BuildContext context) {
    print('GameTitleComponent build');
    if (sizes == null) {
      return const SizedBox.shrink();
    }
    final isWebOverride = debugForceIsWeb ?? sizes!['isWeb'] as bool;
    print(
      'screenWidth: ${MediaQuery.of(context).size.width}, debugForceIsWeb: $debugForceIsWeb, isWeb: $isWebOverride',
    );
    final isWeb = isWebOverride;

    return Scaffold(
      body: Center(
        child:
            isWeb
                ? WideScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage,
                  messageNotifier: messageNotifier, // Pass notifier
                  scoreNotifier: scoreNotifier, // Pass notifier
                  spelledWordsNotifier: spelledWordsNotifier, // Pass notifier
                  updateScoresRefresh: updateScoresRefresh,
                  sizes: sizes!,
                )
                : NarrowScreen(
                  showBorders: debugShowBorders,
                  onSubmit: submitWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                  gridKey: _gridKey,
                  wildcardKey: _wildcardKey,
                  onMessage: _handleMessage,
                  messageNotifier: messageNotifier, // Pass notifier
                  scoreNotifier: scoreNotifier, // Pass notifier
                  spelledWordsNotifier: spelledWordsNotifier, // Pass notifier
                  updateScoresRefresh: updateScoresRefresh,
                  sizes: sizes!,
                ),
      ),
    );
  }
}
