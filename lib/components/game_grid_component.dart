// File: /lib/components/game_grid_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
import '../models/tile.dart';
import '../models/boardState.dart';
import 'letter_square_component.dart';
import '../managers/gameManager.dart';
import '../config/debugConfig.dart';

class GameGridComponent extends StatefulWidget {
  const GameGridComponent({super.key});

  @override
  GameGridComponentState createState() => GameGridComponentState();
}

class GameGridComponentState extends State<GameGridComponent> {
  List<Tile> selectedTiles = [];
  List<Tile> gridTiles = [];
  bool isSelecting = false;
  bool isLoading = true;

  List<Tile> getTiles() => gridTiles;

  List<int> getSelectedIndices() {
    return selectedTiles.map((tile) => gridTiles.indexOf(tile)).where((index) => index != -1).toList();
  }

  void setSelectedIndices(List<int> indices) {
    selectedTiles = indices.map((index) => gridTiles[index]).toList();
  }

  void setTiles(List<Tile> newTiles) {
    setState(() {
      gridTiles = newTiles;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    final gm = GameManager();
    gridTiles = List.from(gm.board.gridTiles);
    isLoading = gridTiles.isEmpty;
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
      final lastSelectedTile = selectedTiles.isEmpty ? null : selectedTiles.last;
      final lastIndex = selectedTiles.isEmpty ? -1 : gridTiles.indexOf(lastSelectedTile!);

      if (gridTiles[index].state == 'selected' && gridTiles[index] == selectedTiles.last) {
        gridTiles[index].select(); // Toggles to unselected
        selectedTiles.removeLast();
      } else if ((gridTiles[index].state == 'unused' || gridTiles[index].state == 'used') &&
          selectedTiles.length < 12 &&
          !selectedTiles.contains(gridTiles[index]) &&
          _isAdjacent(index, lastIndex)) {
        gridTiles[index].select(); // Toggles to selected
        selectedTiles.add(gridTiles[index]);
      }
    });

    // Push the word being built to GameManager so it displays in the message area
    final word = selectedTiles.map((t) => t.letter).join().toUpperCase();
    GameManager().setCurrentWord(word);
  }

  void clearSelectedTiles() {
    setState(() {
      for (var tile in selectedTiles) {
        final index = gridTiles.indexOf(tile);
        if (index != -1) {
          gridTiles[index].revert();
        }
      }
      selectedTiles.clear();
    });
  }

  void submitWord() async {
    if (selectedTiles.isEmpty) return;
    final gm = GameManager();

    // Check if board is finished
    if (gm.board.boardState == BoardState.finished) {
      clearSelectedTiles();
      gm.setMessage("Board complete! There will be a new board tomorrow");
      return;
    }

    // Delegate word validation to GameManager
    final (success, message) = await gm.addWord(selectedTiles);
    setState(() {
      if (success) {
        // Mark tiles as used
        for (var tile in selectedTiles) {
          final index = gridTiles.indexOf(tile);
          if (index != -1) {
            gridTiles[index].markUsed();
          }
        }
        selectedTiles.clear();
      } else {
        // Revert tiles
        for (var tile in selectedTiles) {
          final index = gridTiles.indexOf(tile);
          if (index != -1) {
            gridTiles[index].revert();
          }
        }
        selectedTiles.clear();
      }
    });

    // Clear the word being built immediately
    gm.currentWord = '';

    // Schedule clearing gm.message for the next frame. This ensures the
    // message component captures the feedback in didUpdateWidget during
    // this frame's rebuild, while preventing stale messages from
    // re-triggering when listeners fire on the next tile tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the GameManager public API so ChangeNotifier notification stays
      // encapsulated inside the ChangeNotifier subclass.
      gm.setMessage('');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    return Container(
      width: layout.gridWidthSize,
      height: layout.gridHeightSize,
      decoration: DebugConfig().showBorders ? BoxDecoration(border: Border.all(color: Colors.red, width: 1)) : null,
      child:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Game Board...',
                      style: TextStyle(color: Colors.grey[600], fontSize: layout.gameMessageFontSize),
                    ),
                  ],
                ),
              )
              : gridTiles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                crossAxisCount: GameLayoutManager.gridCols,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                mainAxisSpacing: layout.gridSpacing,
                crossAxisSpacing: layout.gridSpacing,
                children: List.generate(gridTiles.length, (index) {
                  return DragTarget<Tile>(
                    onWillAcceptWithDetails: (details) {
                      final gm = GameManager();

                      if (gm.board.boardState == BoardState.finished) {
                        gm.setMessage("Board complete! There will be a new board tomorrow");
                        return false;
                      }

                      // Only allow drops on UNUSED tiles
                      bool canAccept = gridTiles[index].state == 'unused' && gridTiles[index].isHybrid == false;

                      if (!canAccept) {
                        gm.setMessage('Can only drop on unused tiles');
                      }
                      return canAccept;
                    },
                    onAcceptWithDetails: (details) {
                      gridTiles[index].applyWildcard(details.data.letter, details.data.value);
                      final gm = GameManager();
                      gm.setMessage('Wildcard applied to ${gridTiles[index].letter}');
                      gm.board = gm.board.copyWith(wildcardUses: gm.board.wildcardUses + 1);
                      gm.saveState();
                    },
                    onLeave: (Tile? tile) {
                      GameManager().setMessage('');
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => _onTileTapped(index),
                        child: LetterSquareComponent(tile: gridTiles[index], helpDialog: false),
                      );
                    },
                  );
                }),
              ),
    );
  }
}
