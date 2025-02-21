// main.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
import 'logic/scoring.dart';
import 'logic/layout_calculator.dart';
import 'components/letter_square.dart';
import 'layouts/spelled_words_column.dart';
import 'logic/spelled_words_handler.dart';
import 'layouts/game_title.dart';
import 'layouts/game_grid.dart';
import 'layouts/wildcard_column.dart';
import 'layouts/game_buttons.dart';
import 'layouts/game_scores.dart';
import 'layouts/game_top_bar.dart';
import 'layouts/how_to_play_dialog.dart';
import 'layouts/high_scores_dialog.dart';
import 'layouts/legal_dialog.dart';

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
    const bool showBorders = false; // Turned off borders
    Map<String, double> sizes = LayoutCalculator.calculateSizes(context);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameTopBar(
              onInstructions: () => HowToPlayDialog.show(context),
              onHighScores: () => HighScoresDialog.show(context),
              onLegal: () => LegalDialog.show(context),
            ),
            const Divider(height: 1.0, thickness: .5, color: Color.fromARGB(127, 158, 158, 158)),
            SizedBox(height: 10.0),
            GameTitle(width: gridSize, showBorders: showBorders),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WildcardColumn(
                  width: sideColumnWidth,
                  height: gridSize,
                  squareSize: squareSize,
                  letterFontSize: letterFontSize,
                  valueFontSize: valueFontSize,
                  gridSpacing: gridSpacing,
                  showBorders: showBorders, // Updated to false
                ),
                SizedBox(width: sideSpacing),
                Column(
                  children: [
                    GameScores(width: gridSize),
                    SizedBox(height: gridSpacing),
                    GameGrid(
                      gridSize: gridSize,
                      squareSize: squareSize,
                      letterFontSize: letterFontSize,
                      valueFontSize: valueFontSize,
                      gridSpacing: gridSpacing,
                      showBorders: showBorders,
                    ),
                  ],
                ),
                SizedBox(width: sideSpacing),
                SpelledWordsColumn(
                  words: SpelledWordsLogic.spelledWords,
                  columnWidth: sideColumnWidth,
                  columnHeight: gridSize,
                  gridSpacing: spelledWordsGridSpacing,
                  showBorders: showBorders, // Updated to false
                  wordColumnWidth: wordColumnWidth,
                  wordColumnHeight: wordColumnHeight,
                ),
              ],
            ),
            SizedBox(height: 20.0),
            GameButtons(onSubmit: addWord, onClear: clearWords),
          ],
        ),
      ),
    );
  }
}
