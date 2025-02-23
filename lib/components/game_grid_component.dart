// components/game_grid_component.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../logic/grid_loader.dart';
import '../models/tile.dart';
import '../logic/game_layout.dart';
import 'letter_square_component.dart';

class GameGridComponent extends StatefulWidget {
  final bool showBorders;

  const GameGridComponent({super.key, this.showBorders = false});

  @override
  GameGridComponentState createState() => GameGridComponentState();
}

class GameGridComponentState extends State<GameGridComponent> {
  late Future<List<Tile>> _tilesFuture;
  List<Tile> tiles = []; // Define as state variable
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
      tiles = loadedTiles; // Initialize state
    });
    return loadedTiles;
  }

  void _onTileTapped(int index) {
    // Simplify—no need for tiles param
    setState(() {
      if (tiles[index].state == 'unused') {
        tiles[index].select();
        selectedIndices.add(index);
      } else if (tiles[index].state == 'selected') {
        tiles[index].select();
        selectedIndices.remove(index);
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

          // tiles is already updated in _loadTiles, but we could sync here if needed
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
