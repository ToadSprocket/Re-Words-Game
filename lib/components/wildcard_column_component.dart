// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../models/tile.dart';
import 'letter_square_component.dart';

class WildcardColumnComponent extends StatefulWidget {
  final double width;
  final double height;
  final bool showBorders;
  final bool isHorizontal;
  final double gridSpacing;
  final Map<String, dynamic> sizes;
  final VoidCallback? onWildcardUsed;

  const WildcardColumnComponent({
    super.key,
    required this.width,
    required this.height,
    this.showBorders = false,
    this.isHorizontal = false,
    required this.gridSpacing,
    required this.sizes,
    this.onWildcardUsed,
  });

  @override
  WildcardColumnComponentState createState() => WildcardColumnComponentState();
}

class WildcardColumnComponentState extends State<WildcardColumnComponent> {
  List<Tile> tiles = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadWildcardTiles() async {
    // Use GridLoader's already-loaded data
    if (GridLoader.wildcardTiles.isEmpty) {
      print('No wildcard tiles available in GridLoader');
      return;
    }
    setState(() {
      tiles =
          GridLoader.wildcardTiles.map((tileData) {
            return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: true);
          }).toList();
      print('Loaded wildcard tiles: ${tiles.length}');
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
      tiles.removeAt(index);
      widget.onWildcardUsed?.call();
    });
  }

  Future<void> reloadWildcardTiles() async {
    setState(() {
      _loadWildcardTiles();
      print('Reloaded wildcard tiles');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('WildcardColumn build - Starting');

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
      child:
          tiles.isEmpty
              ? Center(
                child: Text("", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ) // ❌ Remove Spinner - Show empty space instead
              : widget.isHorizontal
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tiles.length, (index) {
                  final isAvailable = tiles[index].state != 'used';
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.gridSpacing / 2),
                    child: Draggable<Tile>(
                      data: tiles[index],
                      child: Opacity(
                        opacity: isAvailable ? 1.0 : AppStyles.wildcardDisabledOpacity,
                        child: LetterSquareComponent(tile: tiles[index], sizes: widget.sizes),
                      ),
                      feedback: Opacity(
                        opacity: 0.7,
                        child: LetterSquareComponent(tile: tiles[index], sizes: widget.sizes),
                      ),
                      childWhenDragging: Container(),
                      onDragCompleted: () {
                        removeWildcard(index);
                      },
                      onDraggableCanceled: (_, __) {
                        // ✅ Wildcard will snap back if dropped outside valid areas
                        print("🔄 Wildcard dropped in an invalid area. Returning to column.");
                        setState(() {}); // Forces re-render so the wildcard stays
                      },
                    ),
                  );
                }),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(tiles.length, (index) {
                  final isAvailable = tiles[index].state != 'used';
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.gridSpacing / 2),
                    child: Draggable<Tile>(
                      data: tiles[index],
                      child: Opacity(
                        opacity: isAvailable ? 1.0 : AppStyles.wildcardDisabledOpacity,
                        child: LetterSquareComponent(tile: tiles[index], sizes: widget.sizes),
                      ),
                      feedback: Opacity(
                        opacity: 0.7,
                        child: LetterSquareComponent(tile: tiles[index], sizes: widget.sizes),
                      ),
                      childWhenDragging: Container(),
                      onDragCompleted: () {
                        removeWildcard(index);
                      },
                      onDraggableCanceled: (_, __) {
                        // ✅ Wildcard will snap back if dropped outside valid areas
                        print("🔄 Wildcard dropped in an invalid area. Returning to column.");
                        setState(() {}); // Forces re-render so the wildcard stays
                      },
                    ),
                  );
                }),
              ),
    );
  }
}
