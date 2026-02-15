// File: /lib/components/wildcard_column_component.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../models/tile.dart';
import 'letter_square_component.dart';
import '../logic/logging_handler.dart';
import '../managers/gameManager.dart';
import '../config/debugConfig.dart';

class WildcardColumnComponent extends StatefulWidget {
  final double width;
  final double height;
  final bool isHorizontal;
  final double gridSpacing;
  final VoidCallback? onWildcardUsed;

  const WildcardColumnComponent({
    super.key,
    required this.width,
    required this.height,
    this.isHorizontal = false,
    required this.gridSpacing,
    this.onWildcardUsed,
  });

  @override
  WildcardColumnComponentState createState() => WildcardColumnComponentState();
}

class WildcardColumnComponentState extends State<WildcardColumnComponent> {
  List<Tile> tiles = [];

  List<Tile> getTiles() => tiles;

  /// Updates wildcard tiles externally (e.g., when a new board is loaded).
  /// Mirrors the setTiles() pattern used by GameGridComponentState.
  void setTiles(List<Tile> newTiles) {
    setState(() {
      tiles = newTiles;
    });
  }

  @override
  void initState() {
    super.initState();
    // Load wildcard tiles from GameManager's board (source of truth)
    final gm = GameManager();
    tiles = List.from(gm.board.wildcardTiles);
    LogService.logInfo('Loaded ${tiles.length} wildcard tiles: ${tiles.map((t) => t.letter).join(', ')}');
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
      // Mark tile as removed (visually disappears)
      tiles[index].isRemoved = true;
      widget.onWildcardUsed?.call();

      // Save state through GameManager
      GameManager().saveState();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access layout from GameManager singleton
    final layout = GameManager().layoutManager!;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: DebugConfig().showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 1)) : null,
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
                      width: layout.gridSquareSize,
                      height: layout.gridSquareSize,
                      child:
                          tiles[index].isRemoved
                              ? Container()
                              : Draggable<Tile>(
                                data: tiles[index],
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: layout.gridSquareSize,
                                    height: layout.gridSquareSize,
                                    child: Opacity(
                                      opacity: 0.7,
                                      child: LetterSquareComponent(tile: tiles[index], helpDialog: false),
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
                                child: LetterSquareComponent(tile: tiles[index], helpDialog: false),
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
                      width: layout.gridSquareSize,
                      height: layout.gridSquareSize,
                      child:
                          tiles[index].isRemoved
                              ? Container()
                              : Draggable<Tile>(
                                data: tiles[index],
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: layout.gridSquareSize,
                                    height: layout.gridSquareSize,
                                    child: Opacity(
                                      opacity: 0.7,
                                      child: LetterSquareComponent(tile: tiles[index], helpDialog: false),
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
                                child: LetterSquareComponent(tile: tiles[index], helpDialog: false),
                              ),
                    ),
                  );
                }),
              ),
    );
  }
}
