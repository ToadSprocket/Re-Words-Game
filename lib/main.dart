// main.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
import 'logic/game_layout.dart';
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'logic/spelled_words_handler.dart';
import 'dialogs/how_to_play_dialog.dart';
import 'dialogs/high_scores_dialog.dart';
import 'dialogs/legal_dialog.dart';
import 'dialogs/board_expired_dialog.dart';
import 'dialogs/failure_dialog.dart';
import 'components/game_grid_component.dart';
import 'components/wildcard_column_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'managers/state_manager.dart';

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;
const bool debugForceExpiredBoard = false;

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
  String submitMessage = '';
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
    await WordLoader.loadWords();
    final gridLoaded = await GridLoader.loadGrid();
    if (!gridLoaded) {
      await FailureDialog.show(context);
    }
    await _checkBoardExpiration();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sizes = GameLayout.of(context).sizes;
    print('HomeScreen didChangeDependencies - sizes set');
  }

  void submitWord() {
    setState(() {
      _gridKey.currentState?.submitWord();
    });
  }

  void clearWords() {
    setState(() {
      _gridKey.currentState?.clearSelectedTiles();
      _wildcardKey.currentState?.clearSelectedTiles();
      submitMessage = '';
    });
  }

  void _handleMessage(String message) {
    setState(() {
      submitMessage = message;
    });
  }

  Future<void> _checkBoardExpiration() async {
    print('Checking board expiration');
    bool loadNewBoard = false;
    bool userBoardLoad = false;
    await StateManager.restoreState(_gridKey, _wildcardKey);
    final prefs = await SharedPreferences.getInstance();
    final boardLoadedDate = prefs.getString('boardLoadedDate');
    final timePlayedSeconds = prefs.getInt('timePlayedSeconds') ?? 0;
    final expireDate = DateTime.tryParse(GridLoader.dateExpire);
    final isExpired = debugForceExpiredBoard || (expireDate != null && DateTime.now().toUtc().isAfter(expireDate));
    final minsFromBoardLoad =
        boardLoadedDate != null ? DateTime.now().difference(DateTime.parse(boardLoadedDate)).inMinutes : null;

    print('isExpired: $isExpired, timePlayedSeconds: $timePlayedSeconds, minsFromBoardLoad: $minsFromBoardLoad');

    if (isExpired) {
      if (minutesFromMidnight() > 120 && timePlayedSeconds < 900) {
        loadNewBoard = true;
      } else if (minsFromBoardLoad != null && minsFromBoardLoad > 120) {
        loadNewBoard = true;
      } else {
        userBoardLoad = await BoardExpiredDialog.show(context) ?? false;
      }
    }

    // Load a nmew board and reset game state
    if (loadNewBoard || userBoardLoad) {
      StateManager.updatePlayTime(_sessionStart);
      await GridLoader.loadGrid(forceRefresh: true);
      _gridKey.currentState?.reloadTiles(); // Reload grid
      _wildcardKey.currentState?.reloadWildcardTiles();
      print('New board loaded');
      setState(() {});
    }
  }

  int minutesFromMidnight() {
    final now = DateTime.now(); // Current local time
    final midnight = DateTime(now.year, now.month, now.day); // Midnight today
    final difference = now.difference(midnight); // Duration since midnight
    return difference.inMinutes; // Integer minutes
  }

  @override
  Widget build(BuildContext context) {
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
                  message: submitMessage,
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
                  message: submitMessage,
                  sizes: sizes!,
                ),
      ),
    );
  }
}
