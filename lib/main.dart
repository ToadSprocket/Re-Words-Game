// main.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
//import 'logic/scoring.dart';
import 'logic/layout_calculator.dart';
import 'screens/wide_screen.dart';
import 'screens/narrow_screen.dart';
import 'logic/spelled_words_handler.dart';
import 'layouts/how_to_play_dialog.dart';
import 'layouts/high_scores_dialog.dart';
import 'layouts/legal_dialog.dart';

const bool debugShowBorders = false; // Toggle borders for testing
const bool? debugForceIsWeb = false; // Set to true or false to force isWeb

void main() {
  runApp(const ReWordApp());
}

class ReWordApp extends StatelessWidget {
  const ReWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Re-Word Game', theme: AppStyles.appTheme, home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> spelledWords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await WordLoader.loadWords();
    await GridLoader.loadGrid();
    setState(() {});
  }

  void addWord() {
    if (WordLoader.words.isNotEmpty) {
      String randomWord = WordLoader.words[Random().nextInt(WordLoader.words.length)];
      SpelledWordsLogic.addWord(randomWord);
      setState(() {});
    }
  }

  void clearWords() {
    SpelledWordsLogic.spelledWords.clear();
    SpelledWordsLogic.score = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> sizes = LayoutCalculator.calculateSizes(context);
    bool isWeb = debugForceIsWeb ?? sizes['isWeb'] == true;
    double squareSize = sizes['squareSize'] ?? AppStyles.baseSquareSize;
    double letterFontSize = sizes['letterFontSize'] ?? AppStyles.baseLetterFontSize;
    double valueFontSize = sizes['valueFontSize'] ?? AppStyles.baseValueFontSize;
    double gridSize =
        sizes['gridSize'] ??
        (AppStyles.baseSquareSize * AppStyles.gridCols + AppStyles.baseGridSpacing * (AppStyles.gridCols - 1));
    double gridSpacing = sizes['gridSpacing'] ?? AppStyles.baseGridSpacing;
    double sideSpacing = sizes['sideSpacing'] ?? AppStyles.baseSideSpacing;
    double sideColumnWidth = sizes['sideColumnWidth'] ?? AppStyles.baseSideColumnWidth;
    double wordColumnWidth = sizes['wordColumnWidth'] ?? AppStyles.baseWordColumnWidth;
    double wordColumnHeight = sizes['wordColumnHeight'] ?? AppStyles.baseWordColumnHeight;
    double spelledWordsGridSpacing = sizes['spelledWordsGridSpacing'] ?? AppStyles.basedSpelledWordsGridSpacing;

    return Scaffold(
      body: Center(
        child:
            isWeb
                ? WideScreen(
                  squareSize: squareSize,
                  letterFontSize: letterFontSize,
                  valueFontSize: valueFontSize,
                  gridSize: gridSize,
                  gridSpacing: gridSpacing,
                  sideSpacing: sideSpacing,
                  sideColumnWidth: sideColumnWidth,
                  wordColumnWidth: wordColumnWidth,
                  wordColumnHeight: wordColumnHeight,
                  spelledWordsGridSpacing: spelledWordsGridSpacing,
                  showBorders: debugShowBorders,
                  onSubmit: addWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                )
                : NarrowScreen(
                  squareSize: squareSize,
                  letterFontSize: letterFontSize,
                  valueFontSize: valueFontSize,
                  gridSize: gridSize,
                  gridSpacing: gridSpacing,
                  sideSpacing: sideSpacing,
                  sideColumnWidth: sideColumnWidth,
                  wordColumnWidth: wordColumnWidth,
                  wordColumnHeight: wordColumnHeight,
                  spelledWordsGridSpacing: spelledWordsGridSpacing,
                  showBorders: debugShowBorders,
                  onSubmit: addWord,
                  onClear: clearWords,
                  onInstructions: () => HowToPlayDialog.show(context),
                  onHighScores: () => HighScoresDialog.show(context),
                  onLegal: () => LegalDialog.show(context),
                ),
      ),
    );
  }
}
