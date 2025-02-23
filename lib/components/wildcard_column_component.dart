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

  const WildcardColumnComponent({
    super.key,
    required this.width,
    required this.height,
    this.showBorders = false,
    this.isHorizontal = false,
  });

  @override
  WildcardColumnComponentState createState() => WildcardColumnComponentState();
}

class WildcardColumnComponentState extends State<WildcardColumnComponent> {
  late Future<List<Tile>> _wildcardTilesFuture;
  List<Tile> tiles = []; // Define as state variable

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
      tiles = loadedTiles; // Initialize state
    });
    return loadedTiles;
  }

  void _onWildcardTapped(int index) {
    // Simplify—no need for tiles param
    setState(() {
      tiles[index].select();
      print('Wildcard $index state: ${tiles[index].state}');
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

  @override
  Widget build(BuildContext context) {
    final sizes = GameLayout.of(context).sizes;
    final gridSpacing = sizes['gridSpacing']!;

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

          // tiles is already updated in _loadWildcardTiles
          return widget.isHorizontal
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tiles.length, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: gridSpacing / 2),
                    child: GestureDetector(
                      onTap: () => _onWildcardTapped(index),
                      child: LetterSquareComponent(tile: tiles[index]),
                    ),
                  );
                }),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(tiles.length, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: gridSpacing / 2),
                    child: GestureDetector(
                      onTap: () => _onWildcardTapped(index),
                      child: LetterSquareComponent(tile: tiles[index]),
                    ),
                  );
                }),
              );
        },
      ),
    );
  }
}
