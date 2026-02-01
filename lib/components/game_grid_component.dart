// Copyright © 2025 Digital Relics. All Rights Reserved.
// file: lib/components/game_grid_component.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reword_game/managers/gameLayoutManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/grid_loader.dart';
import '../logic/spelled_words_handler.dart';
import '../models/tile.dart';
import '../models/boardState.dart';
import '../providers/game_state_provider.dart';
import 'letter_square_component.dart';

class GameGridComponent extends StatefulWidget {
  final bool showBorders;
  final Function(String) onMessage;
  final VoidCallback updateScoresRefresh;
  final VoidCallback updateCurrentGameState;
  final GameLayoutManager gameLayoutManager;
  final bool disableSpellCheck;

  const GameGridComponent({
    super.key,
    this.showBorders = false,
    required this.onMessage,
    required this.updateScoresRefresh,
    required this.updateCurrentGameState,
    required this.gameLayoutManager,
    this.disableSpellCheck = false,
  });

  @override
  GameGridComponentState createState() => GameGridComponentState();
}

class GameGridComponentState extends State<GameGridComponent> {
  late SpelledWordsLogic spelledWordsLogic;
  List<Tile> selectedTiles = [];
  List<Tile> gridTiles = [];
  bool isSelecting = false;
  bool isLoading = true; // Add loading state

  List<Tile> getTiles() => gridTiles;

  List<int> getSelectedIndices() {
    return selectedTiles.map((tile) => gridTiles.indexOf(tile)).where((index) => index != -1).toList();
  }

  void setSelectedIndices(List<int> indices) {
    selectedTiles = indices.map((index) => gridTiles[index]).where((tile) => tile != null).toList();
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
    spelledWordsLogic = SpelledWordsLogic(disableSpellCheck: widget.disableSpellCheck);
    // Only load from GridLoader if we don't have tiles yet
    if (gridTiles.isEmpty) {
      gridTiles = List.from(GridLoader.gridTiles);
    }
    isLoading = gridTiles.isEmpty;
  }

  Future<void> _loadTiles() async {
    setState(() {
      isLoading = true;
    });

    // Only load from GridLoader if we don't have tiles
    if (gridTiles.isEmpty) {
      if (GridLoader.gridTiles.isNotEmpty) {
        setState(() {
          gridTiles =
              GridLoader.gridTiles.map((tileData) {
                return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: false, isRemoved: false);
              }).toList();
          isLoading = false;
        });
      } else {
        // Create default grid tiles as a fallback
        print('GameGridComponent: No grid tiles available in GridLoader, using default tiles');
        setState(() {
          // Create a 4x4 grid of default tiles
          gridTiles = [
            Tile(letter: 'R', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'E', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'W', value: 4, isExtra: false, isRemoved: false),
            Tile(letter: 'O', value: 1, isExtra: false, isRemoved: false),

            Tile(letter: 'R', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'D', value: 2, isExtra: false, isRemoved: false),
            Tile(letter: 'G', value: 2, isExtra: false, isRemoved: false),
            Tile(letter: 'A', value: 1, isExtra: false, isRemoved: false),

            Tile(letter: 'M', value: 3, isExtra: false, isRemoved: false),
            Tile(letter: 'E', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'F', value: 4, isExtra: false, isRemoved: false),
            Tile(letter: 'U', value: 1, isExtra: false, isRemoved: false),

            Tile(letter: 'N', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'T', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'I', value: 1, isExtra: false, isRemoved: false),
            Tile(letter: 'L', value: 1, isExtra: false, isRemoved: false),
          ];
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> reloadTiles() async {
    setState(() {
      isLoading = true;
    });

    // Always call _loadTiles to ensure we have tiles
    await _loadTiles();

    setState(() {
      selectedTiles.clear();
      isLoading = false;
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

    // Get the GameStateProvider
    final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);

    // Check if the board is in finished state
    if (gameStateProvider.boardState == BoardState.finished) {
      // Clear selected tiles
      for (var tile in selectedTiles) {
        final index = gridTiles.indexOf(tile);
        if (index != -1) {
          gridTiles[index].revert();
        }
      }
      selectedTiles.clear();

      // Show message that board is complete
      widget.onMessage("Board complete! There will be a new board tomorrow");
      return;
    }

    final (success, message) = await spelledWordsLogic.addWord(selectedTiles);
    setState(() {
      if (success) {
        // If we're in newBoard state and have words, transition to inProgress
        if (gameStateProvider.boardState == BoardState.newBoard && SpelledWordsLogic.spelledWords.isNotEmpty) {
          gameStateProvider.updateBoardState(BoardState.inProgress);
        }

        // Mark tiles as used
        for (var tile in selectedTiles) {
          final index = gridTiles.indexOf(tile);
          if (index != -1) {
            gridTiles[index].markUsed();
          }
        }
        selectedTiles.clear();
        widget.onMessage(message);
        widget.updateScoresRefresh();
        widget.updateCurrentGameState();
        gameStateProvider.saveState();
      } else {
        // Revert tiles to previous state
        for (var tile in selectedTiles) {
          final index = gridTiles.indexOf(tile);
          if (index != -1) {
            gridTiles[index].revert();
          }
        }
        selectedTiles.clear();
        widget.onMessage(message);
      }
    });
  }

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
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Game Board...',
                      style: TextStyle(color: Colors.grey[600], fontSize: widget.gameLayoutManager.gameMessageFontSize),
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
                mainAxisSpacing: widget.gameLayoutManager.gridSpacing,
                crossAxisSpacing: widget.gameLayoutManager.gridSpacing,
                children: List.generate(gridTiles.length, (index) {
                  return DragTarget<Tile>(
                    onWillAcceptWithDetails: (details) {
                      // Get the GameStateProvider
                      final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);

                      // Check if the board is in finished state
                      if (gameStateProvider.boardState == BoardState.finished) {
                        widget.onMessage("Board complete! There will be a new board tomorrow");
                        return false;
                      }

                      // ✅ Only allow drops on UNUSED tiles
                      bool canAccept =
                          details.data != null &&
                          gridTiles[index].state == 'unused' &&
                          gridTiles[index].isHybrid == false;
                      if (!canAccept) {
                        widget.onMessage('Can only drop on unused tiles');
                      }
                      return canAccept;
                    },
                    onAcceptWithDetails: (details) {
                      // ✅ Apply wildcard only to valid tiles
                      gridTiles[index].applyWildcard(details.data.letter, details.data.value);
                      widget.onMessage('Wildcard applied to ${gridTiles[index].letter}');
                      _incrementWildcardUse();

                      // Save the state after applying a wildcard
                      final gameStateProvider = Provider.of<GameStateProvider>(context, listen: false);
                      gameStateProvider.saveState();
                    },
                    onLeave: (Tile? tile) {
                      // ✅ Optional: Reset message if user drags away
                      widget.onMessage('');
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => _onTileTapped(index),
                        child: LetterSquareComponent(
                          tile: gridTiles[index],
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
