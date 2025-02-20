import 'package:flutter/material.dart';
import 'styles/app_styles.dart';
import 'logic/word_loader.dart';
import 'logic/grid_loader.dart';
//import 'logic/scoring.dart';
import 'logic/layout_calculator.dart';
import 'components/letter_square.dart'; // Import the new widget

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
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await WordLoader.loadWords();
    await GridLoader.loadGrid();
    setState(() {}); // Trigger rebuild with loaded data
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and calculate squareSize
    Map<String, double> sizes = LayoutCalculator.calculateSizes(context);
    double squareSize = sizes['squareSize']!;
    double letterFontSize = sizes['letterFontSize']!;
    double valueFontSize = sizes['valueFontSize']!;
    double gridSize = sizes['gridSize']!;
    double gridSpacing = AppStyles.baseGridSpacing;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game title
            Text(
              'Re-Word Game',
              style: TextStyle(
                fontSize: 36.0, // Large characters
                fontWeight: FontWeight.bold,
                color: AppStyles.textColor, // White
              ),
            ),
            SizedBox(height: 20.0), // Space between title and grid
            // Grid
            SizedBox(
              width: gridSize,
              height: gridSize,
              child: GridView.count(
                crossAxisCount: AppStyles.gridCols,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                children:
                    GridLoader.gridTiles.map((tile) {
                      return LetterSquare(letter: tile['letter'], value: tile['value'], useCount: 0, squareSize: squareSize, letterFontSize: letterFontSize, valueFontSize: valueFontSize);
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
