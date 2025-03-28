// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../models/tile.dart';
import 'letter_square_component.dart';
import '../logic/logging_handler.dart';
import '../managers/gameLayoutManager.dart';

class WildcardColumnComponent extends StatefulWidget {
  final double width;
  final double height;
  final bool showBorders;
  final bool isHorizontal;
  final double gridSpacing;
  final VoidCallback? onWildcardUsed;
  final GameLayoutManager gameLayoutManager;

  const WildcardColumnComponent({
    super.key,
    required this.width,
    required this.height,
    this.showBorders = false,
    this.isHorizontal = false,
    required this.gridSpacing,
    required this.gameLayoutManager,
    this.onWildcardUsed,
  });

  @override
  WildcardColumnComponentState createState() => WildcardColumnComponentState();
}

class WildcardColumnComponentState extends State<WildcardColumnComponent> {
  List<Tile> tiles = [];

  List<Tile> getTiles() => tiles;

  @override
  void initState() {
    super.initState();
    // Only load from GridLoader if we don't have tiles yet
    if (tiles.isEmpty) {
      _loadWildcardTiles();
    }
  }

  Future<void> _loadWildcardTiles() async {
    if (tiles.isNotEmpty) return; // Skip if we already have tiles

    if (GridLoader.wildcardTiles.isEmpty) {
      LogService.logError('WildcardColumnComponent: No wildcard tiles available in GridLoader');
      return;
    }
    setState(() {
      tiles =
          GridLoader.wildcardTiles.map((tileData) {
            return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: true, isRemoved: false);
          }).toList();
    });
  }

  void _onWildcardTapped(int index) {
    setState(() {
      tiles[index].select();
    });
  }

  void clearSelectedTiles() {
    setState(() {
      for (var tile in tiles.where((t) => t.state == 'selected')) {
        tile.state = 'unused';
      }
    });
  }

  void removeWildcard(int index) {
    setState(() {
      tiles[index].isRemoved = true; // Mark as removed instead of removing
      //tiles[index].state = 'used'; // Optional: mark as used to match game logic
      widget.onWildcardUsed?.call();
    });
  }

  Future<void> reloadWildcardTiles() async {
    await _loadWildcardTiles();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 1)) : null,
      child:
          tiles.isEmpty
              ? Center(child: Text("", style: TextStyle(color: Colors.white70, fontSize: 16)))
              : widget.isHorizontal
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tiles.length, (index) {
                  final isAvailable = tiles[index].state != 'used' && !tiles[index].isRemoved;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.gridSpacing / 2),
                    child: SizedBox(
                      width: widget.gameLayoutManager.gridSquareSize,
                      height: widget.gameLayoutManager.gridSquareSize,
                      child:
                          tiles[index].isRemoved
                              ? Container() // Blank box for removed tiles
                              : Draggable<Tile>(
                                data: tiles[index],
                                feedback: Material(
                                  // Wrap in Material for proper rendering
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: widget.gameLayoutManager.gridSquareSize,
                                    height: widget.gameLayoutManager.gridSquareSize,
                                    child: Opacity(
                                      opacity: 0.7,
                                      child: LetterSquareComponent(
                                        tile: tiles[index],
                                        gameLayoutManager: widget.gameLayoutManager,
                                        helpDialog: false,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(),
                                onDragCompleted: () {
                                  removeWildcard(index);
                                },
                                onDraggableCanceled: (_, __) {
                                  setState(() {});
                                },
                                child: LetterSquareComponent(
                                  tile: tiles[index],
                                  gameLayoutManager: widget.gameLayoutManager,
                                  helpDialog: false,
                                ),
                              ),
                    ),
                  );
                }),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(tiles.length, (index) {
                  final isAvailable = tiles[index].state != 'used' && !tiles[index].isRemoved;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.gridSpacing / 2),
                    child: SizedBox(
                      width: widget.gameLayoutManager.gridSquareSize,
                      height: widget.gameLayoutManager.gridSquareSize,
                      child:
                          tiles[index].isRemoved
                              ? Container() // Blank box for removed tiles
                              : Draggable<Tile>(
                                data: tiles[index],
                                feedback: Material(
                                  // Wrap in Material for proper rendering
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: widget.gameLayoutManager.gridSquareSize,
                                    height: widget.gameLayoutManager.gridSquareSize,
                                    child: Opacity(
                                      opacity: 0.7,
                                      child: LetterSquareComponent(
                                        tile: tiles[index],
                                        gameLayoutManager: widget.gameLayoutManager,
                                        helpDialog: false,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(),
                                onDragCompleted: () {
                                  removeWildcard(index);
                                },
                                onDraggableCanceled: (_, __) {
                                  setState(() {});
                                },
                                child: LetterSquareComponent(
                                  tile: tiles[index],
                                  gameLayoutManager: widget.gameLayoutManager,
                                  helpDialog: false,
                                ),
                              ),
                    ),
                  );
                }),
              ),
    );
  }
}
