// lib/logic/tile.dart
class Tile {
  String letter;
  int value;
  final bool isExtra;
  String state;
  int useCount;
  double multiplier;

  Tile({
    required this.letter,
    required this.value,
    required this.isExtra,
    this.state = 'unused',
    this.useCount = 0,
    this.multiplier = 1.0,
  });

  void select() {
    if (state == 'unused' || state == 'used') {
      state = 'selected';
    } else if (state == 'selected') {
      state = useCount > 0 ? 'used' : 'unused';
    }
  }

  void use() {
    if (state != 'disabled') {
      state = 'used';
      useCount++;
      if (useCount > 1 && !isExtra) multiplier += 1.0;
    }
  }
}
