// components/game_grid_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../logic/scoring.dart';
import '../logic/spelled_words_handler.dart';
import '../models/tile.dart';
import '../logic/game_layout.dart';
import 'letter_square_component.dart';

class GameGridComponent extends StatefulWidget {
  final bool showBorders;
  final ValueChanged<String>? onMessage; // Add callback

  const GameGridComponent({super.key, this.showBorders = false, this.onMessage});

  @override
  GameGridComponentState createState() => GameGridComponentState();
}

class GameGridComponentState extends State<GameGridComponent> {
  late Future<List<Tile>> _tilesFuture;
  List<Tile> tiles = [];
  final List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _tilesFuture = _loadTiles();
  }

  Future<List<Tile>> _loadTiles() async {
    await GridLoader.loadGrid();
    final loadedTiles =
        GridLoader.gridTiles.map((tileData) {
          return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: false);
        }).toList();
    print('Loaded tiles: ${loadedTiles.length}');
    setState(() {
      tiles = loadedTiles;
    });
    return loadedTiles;
  }

  bool _isAdjacent(int newIndex, int lastIndex) {
    if (lastIndex == -1) return true;
    final newRow = newIndex ~/ AppStyles.gridCols;
    final newCol = newIndex % AppStyles.gridCols;
    final lastRow = lastIndex ~/ AppStyles.gridCols;
    final lastCol = lastIndex % AppStyles.gridCols;
    final rowDiff = (newRow - lastRow).abs();
    final colDiff = (newCol - lastCol).abs();
    return (rowDiff <= 1 && colDiff <= 1) && !(rowDiff == 0 && colDiff == 0);
  }

  void _onTileTapped(int index) {
    setState(() {
      final lastIndex = selectedIndices.isEmpty ? -1 : selectedIndices.last;
      if (tiles[index].state == 'selected' && index == selectedIndices.last) {
        tiles[index].select();
        selectedIndices.removeLast();
      } else if ((tiles[index].state == 'unused' || tiles[index].state == 'used') &&
          selectedIndices.length < 12 &&
          !selectedIndices.contains(index) &&
          _isAdjacent(index, lastIndex)) {
        tiles[index].select();
        selectedIndices.add(index);
      }
      print('Tile $index state: ${tiles[index].state}, Selected: $selectedIndices');
    });
  }

  void clearSelectedTiles() {
    setState(() {
      for (var tile in tiles.where((t) => t.state == 'selected')) {
        tile.state = 'unused';
      }
      selectedIndices.clear();
      print('Cleared selected tiles');
    });
  }

  void submitWord() {
    setState(() {
      final selectedTiles = selectedIndices.map((i) => tiles[i]).toList();
      final (success, message) = SpelledWordsLogic.addWord(selectedTiles); // Unpack record
      if (success) {
        for (var index in selectedIndices) {
          tiles[index].markUsed();
        }
        selectedIndices.clear();
        print('Valid word submitted');
      } else {
        for (var index in selectedIndices) {
          tiles[index].revert();
        }
        selectedIndices.clear();
        print('Invalid word submitted');
      }
      widget.onMessage?.call(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSize = sizes['gridSize']!;
    final squareSize = sizes['squareSize']!;
    final gridSpacing = sizes['gridSpacing']!;
    print('Grid sizes - gridSize: $gridSize, squareSize: $squareSize, gridSpacing: $gridSpacing');

    return Container(
      width: gridSize,
      height: gridSize,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
      child: FutureBuilder<List<Tile>>(
        future: _tilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error loading tiles: ${snapshot.error}');
            return const Center(child: Text('Error loading grid'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('No tiles loaded');
            return const Center(child: Text('No grid data'));
          }

          return GridView.count(
            crossAxisCount: AppStyles.gridCols,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            mainAxisSpacing: gridSpacing,
            crossAxisSpacing: gridSpacing,
            children: List.generate(tiles.length, (index) {
              print('Rendering tile $index: ${tiles[index].letter}');
              return GestureDetector(
                onTap: () => _onTileTapped(index),
                child: LetterSquareComponent(tile: tiles[index]),
              );
            }),
          );
        },
      ),
    );
  }
}
