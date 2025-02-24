// components/wildcard_column_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../models/tile.dart';
import '../logic/game_layout.dart';
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
  late Future<List<Tile>> _wildcardTilesFuture;
  List<Tile> tiles = [];

  @override
  void initState() {
    super.initState();
    _wildcardTilesFuture = _loadWildcardTiles();
  }

  Future<List<Tile>> _loadWildcardTiles() async {
    await GridLoader.loadGrid();
    final loadedTiles =
        GridLoader.wildcardTiles.map((tileData) {
          return Tile(letter: tileData['letter'], value: tileData['value'], isExtra: true);
        }).toList();
    print('Wildcard tiles initialized: ${loadedTiles.length}');
    setState(() {
      tiles = loadedTiles;
    });
    return loadedTiles;
  }

  void _onWildcardTapped(int index) {
    setState(() {
      print('WildcardColumn - Tapping $index, state before: ${tiles[index].state}');
      tiles[index].select();
      print('WildcardColumn - Tapped $index, state after: ${tiles[index].state}');
    });
  }

  void clearSelectedTiles() {
    setState(() {
      for (var tile in tiles.where((t) => t.state == 'selected')) {
        tile.state = 'unused';
      }
      print('Cleared selected wildcards');
    });
  }

  void removeWildcard(int index) {
    setState(() {
      tiles.removeAt(index);
      print('Wildcard removed, remaining: ${tiles.length}');
      widget.onWildcardUsed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('WildcardColumn build - Starting');
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: widget.showBorders ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2)) : null,
      child: FutureBuilder<List<Tile>>(
        future: _wildcardTilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error loading wildcards: ${snapshot.error}');
            return const Center(child: Text('Error loading wildcards'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('No wildcard tiles loaded');
            return const Center(child: Text('No wildcards'));
          }

          return widget.isHorizontal
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
                        removeWildcard(index); // Fixed syntax
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
                        removeWildcard(index); // Fixed syntax
                      },
                    ),
                  );
                }),
              );
        },
      ),
    );
  }
}
