// Copyright © 2025 Digital Relics. All Rights Reserved.
// file: lib/components/game_grid_component.dart
import 'package:flutter/material.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
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
  final GameLayoutManager gameLayoutManager;

  const GameGridComponent({
    super.key,
    this.showBorders = false,
    this.onMessage,
    required this.updateScoresRefresh, // Required to match WideScreen
    required this.gameLayoutManager,
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
      return;
    }
    setState(() {
      tiles =
          GridLoader.gridTiles.map((tileData) {
            return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: false, isRemoved: false);
          }).toList();
    });
  }

  Future<void> reloadTiles() async {
    setState(() {
      _loadTiles();
      selectedIndices.clear();
    });
  }

  bool _isAdjacent(int newIndex, int lastIndex) {
    if (lastIndex == -1) return true;
    final newRow = newIndex ~/ GameLayoutManager.gridCols;
    final newCol = newIndex % GameLayoutManager.gridCols;
    final lastRow = lastIndex ~/ GameLayoutManager.gridCols;
    final lastCol = lastIndex % GameLayoutManager.gridCols;
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
      } else {
        for (var index in selectedIndices) {
          tiles[index].revert();
        }
        selectedIndices.clear();
      }
      widget.onMessage?.call(message);
      widget.updateScoresRefresh();
    });
  }

  // void _onDrop(int index, Tile tile) {
  //   setState(() {
  //     if (tiles[index].state == 'unused') {
  //       tiles[index].applyWildcard(tile.letter, tile.value);
  //       widget.onMessage?.call('Wildcard applied to ${tiles[index].letter}');
  //       _incrementWildcardUse();
  //     } else {
  //       widget.onMessage?.call('Can only drop on unused tiles');
  //     }
  //   });
  // }

  void _incrementWildcardUse() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUses = prefs.getInt('wildcardUses') ?? 0;
    await prefs.setInt('wildcardUses', currentUses + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.gameLayoutManager.gridWidthSize,
      height: widget.gameLayoutManager.gridHeightSize,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1)) : null,
      child:
          tiles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                crossAxisCount: GameLayoutManager.gridCols,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                mainAxisSpacing: widget.gameLayoutManager.gridSpacing,
                crossAxisSpacing: widget.gameLayoutManager.gridSpacing,
                children: List.generate(tiles.length, (index) {
                  return DragTarget<Tile>(
                    onWillAcceptWithDetails: (details) {
                      // ✅ Only allow drops on UNUSED tiles
                      bool canAccept = details.data != null && tiles[index].state == 'unused';
                      if (!canAccept) {
                        widget.onMessage?.call('Can only drop on unused tiles');
                      }
                      return canAccept;
                    },
                    onAcceptWithDetails: (details) {
                      // ✅ Apply wildcard only to valid tiles
                      tiles[index].applyWildcard(details.data.letter, details.data.value);
                      widget.onMessage?.call('Wildcard applied to ${tiles[index].letter}');
                      _incrementWildcardUse();
                    },
                    onLeave: (Tile? tile) {
                      // ✅ Optional: Reset message if user drags away
                      widget.onMessage?.call('');
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => _onTileTapped(index),
                        child: LetterSquareComponent(
                          tile: tiles[index],
                          gameLayoutManager: widget.gameLayoutManager,
                          helpDialog: false,
                        ),
                      );
                    },
                  );
                }),
              ),
    );
  }
}
