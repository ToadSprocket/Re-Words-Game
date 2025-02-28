// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'components/game_grid_component.dart';
import 'components/wildcard_column_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/tile.dart';

const bool debugShowBorders = false;
const bool? debugForceIsWeb = null;

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
  Map<String, dynamic>? sizes; // Store sizes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _saveState();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await _saveState(); // Save before window closes
    super.onWindowClose();
    await windowManager.destroy(); // Allow close
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sizes = GameLayout.of(context).sizes; // Move here
    print('HomeScreen didChangeDependencies - sizes set');
  }

  Future<void> _loadData() async {
    await WordLoader.loadWords();
    await GridLoader.loadGrid(); // Ensure grid loads here too
    await _restoreState();
    setState(() {});
  }

  void submitWord() {
    setState(() {
      _gridKey.currentState?.submitWord(); // Triggers validation and scoring
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

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('spelledWords', SpelledWordsLogic.spelledWords);
    await prefs.setInt('score', SpelledWordsLogic.score);
    if (_gridKey.currentState != null) {
      final gridState = _gridKey.currentState!;
      await prefs.setString('gridTiles', jsonEncode(gridState.tiles.map((t) => t.toJson()).toList()));
      await prefs.setString('selectedIndices', jsonEncode(gridState.selectedIndices));
    }
    if (_wildcardKey.currentState != null) {
      final wildcardState = _wildcardKey.currentState!;
      await prefs.setString('wildcardTiles', jsonEncode(wildcardState.tiles.map((t) => t.toJson()).toList()));
    }
    print('Saved game state');
  }

  Future<void> _restoreState() async {
    print('Restoring game state');
    final prefs = await SharedPreferences.getInstance();
    final savedWords = prefs.getStringList('spelledWords');
    if (savedWords != null) {
      SpelledWordsLogic.spelledWords = savedWords;
      SpelledWordsLogic.score = prefs.getInt('score') ?? 0;
      print('Restored spelled words: $savedWords, score: ${SpelledWordsLogic.score}');
    }
    if (_gridKey.currentState != null) {
      final gridState = _gridKey.currentState!;
      final savedTiles = prefs.getString('gridTiles');
      final savedIndices = prefs.getString('selectedIndices');
      if (savedTiles != null) {
        gridState.tiles =
            (jsonDecode(savedTiles) as List).map((item) => Tile.fromJson(item as Map<String, dynamic>)).toList();
        print('Restored grid tiles');
      }
      if (savedIndices != null) {
        gridState.selectedIndices = (jsonDecode(savedIndices) as List).map((i) => i as int).toList();
        print('Restored selected indices');
      }
    }
    if (_wildcardKey.currentState != null) {
      final savedWildcardTiles = prefs.getString('wildcardTiles');
      if (savedWildcardTiles != null) {
        _wildcardKey.currentState!.tiles =
            (jsonDecode(savedWildcardTiles) as List)
                .map((item) => Tile.fromJson(item as Map<String, dynamic>))
                .toList();
        print('Restored wildcard tiles');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sizes == null) {
      return const SizedBox.shrink(); // Wait for sizes
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
                  sizes: sizes!, // Pass sizes
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
                  sizes: sizes!, // Pass sizes
                ),
      ),
    );
  }
}
