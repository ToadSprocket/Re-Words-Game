// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/grid_loader.dart';
import '../logic/spelled_words_handler.dart';
import '../models/tile.dart';
import 'letter_square_component.dart';

class GameGridComponent extends StatefulWidget {
  final bool showBorders;
  final ValueChanged<String>? onMessage;
  final VoidCallback updateScoresRefresh; // Add this
  final Map<String, dynamic> sizes;

  const GameGridComponent({
    super.key,
    this.showBorders = false,
    this.onMessage,
    required this.updateScoresRefresh, // Required to match WideScreen
    required this.sizes,
  });

  @override
  GameGridComponentState createState() => GameGridComponentState();
}

class GameGridComponentState extends State<GameGridComponent> {
  List<Tile> tiles = [];
  List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadTiles() async {
    // Use GridLoader's already-loaded data
    if (GridLoader.gridTiles.isEmpty) {
      print('No tiles available in GridLoader');
      return;
    }
    setState(() {
      tiles =
          GridLoader.gridTiles.map((tileData) {
            return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: false);
          }).toList();
      print('Loaded tiles: ${tiles.length}');
    });
  }

  Future<void> reloadTiles() async {
    setState(() {
      _loadTiles();
      selectedIndices.clear();
      print('Reloaded grid tiles');
    });
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
        tiles[index].select(); // Toggles to unselected
        selectedIndices.removeLast();
      } else if ((tiles[index].state == 'unused' || tiles[index].state == 'used') &&
          selectedIndices.length < 12 &&
          !selectedIndices.contains(index) &&
          _isAdjacent(index, lastIndex)) {
        tiles[index].select(); // Toggles to selected
        selectedIndices.add(index);
      }
      print('Tile $index state: ${tiles[index].state}, Selected: $selectedIndices');
    });
  }

  void clearSelectedTiles() {
    setState(() {
      for (var index in selectedIndices) {
        tiles[index].revert();
      }
      selectedIndices.clear();
    });
  }

  void submitWord() {
    setState(() {
      final selectedTiles = selectedIndices.map((i) => tiles[i]).toList();
      final (success, message) = SpelledWordsLogic.addWord(selectedTiles);
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
      widget.updateScoresRefresh();
    });
  }

  void _onDrop(int index, Tile tile) {
    setState(() {
      if (tiles[index].state == 'unused') {
        tiles[index].applyWildcard(tile.letter, tile.value);
        widget.onMessage?.call('Wildcard applied to ${tiles[index].letter}');
        _incrementWildcardUse();
      } else {
        widget.onMessage?.call('Can only drop on unused tiles');
      }
    });
  }

  void _incrementWildcardUse() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUses = prefs.getInt('wildcardUses') ?? 0;
    await prefs.setInt('wildcardUses', currentUses + 1);
    print('Wildcard uses incremented: ${currentUses + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.sizes['gridSize'] as double;
    final squareSize = widget.sizes['squareSize'] as double;
    final gridSpacing = widget.sizes['gridSpacing'] as double;
    print('Grid sizes - gridSize: $gridSize, squareSize: $squareSize, gridSpacing: $gridSpacing');

    return Container(
      width: gridSize,
      height: gridSize,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
      child:
          tiles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                crossAxisCount: AppStyles.gridCols,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                children: List.generate(tiles.length, (index) {
                  return DragTarget<Tile>(
                    onWillAccept: (Tile? tile) => tile != null,
                    onAccept: (Tile tile) => _onDrop(index, tile),
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => _onTileTapped(index),
                        child: LetterSquareComponent(tile: tiles[index], sizes: widget.sizes),
                      );
                    },
                  );
                }),
              ),
    );
  }
}
