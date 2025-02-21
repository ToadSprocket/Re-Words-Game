import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
//import 'logic/scoring.dart';
import 'logic/layout_calculator.dart';
import 'components/letter_square.dart';
import 'components/spelled_words_column.dart';
import 'logic/spelled_words_handler.dart';

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
  // --- State for Spelled Words ---
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

  // --- Method to Add Words ---
  void addWord(String word) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // --- Debugging Toggle ---
    const bool showBorders = false;

    // --- Size Calculations ---
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

    // --- Grid Widget ---
    Widget gridWidget = Container(
      width: gridSize,
      height: gridSize,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
      child: GridView.count(
        crossAxisCount: AppStyles.gridCols,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        children:
            GridLoader.gridTiles.map((tile) {
              return LetterSquare(
                letter: tile['letter'],
                value: tile['value'],
                useCount: 0,
                squareSize: squareSize,
                letterFontSize: letterFontSize,
                valueFontSize: valueFontSize,
              );
            }).toList(),
      ),
    );

    // --- Wildcard Column ---
    Widget wildcardColumn = Container(
      width: sideColumnWidth,
      height: gridSize,
      decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            GridLoader.wildcardTiles.map((tile) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: gridSpacing / 2),
                child: LetterSquare(
                  letter: tile['letter'],
                  value: tile['value'],
                  isWildcard: true,
                  useCount: 0,
                  squareSize: squareSize,
                  letterFontSize: letterFontSize,
                  valueFontSize: valueFontSize,
                ),
              );
            }).toList(),
      ),
    );

    // --- Main Layout ---
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Title Row ---
            Container(
              width: gridSize,
              decoration: showBorders ? BoxDecoration(border: Border.all(color: Colors.purple, width: 2)) : null,
              child: Center(
                child: Text(
                  'Re-Word Game',
                  style: TextStyle(
                    fontSize: AppStyles.headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.headerTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20.0),

            // --- Game Area Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                wildcardColumn,
                SizedBox(width: sideSpacing),
                gridWidget,
                SizedBox(width: sideSpacing),
                SpelledWordsColumn(
                  words: SpelledWordsLogic.spelledWords,
                  columnWidth: sideColumnWidth,
                  columnHeight: gridSize,
                  gridSpacing: spelledWordsGridSpacing,
                  score: SpelledWordsLogic.score, // Pass constant score
                  showBorders: showBorders,
                  wordColumnWidth: wordColumnWidth,
                  wordColumnHeight: wordColumnHeight,
                ),
              ],
            ),
            // --- Debug Button ---
            ElevatedButton(
              onPressed: () {
                setState(() {
                  SpelledWordsLogic.addWord("cat"); // Call static method
                });
              },
              child: Text("Add Word"),
            ),
          ],
        ),
      ),
    );
  }
}
