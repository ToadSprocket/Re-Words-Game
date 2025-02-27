// models/tile.dart
class Tile {
  String letter;
  int value;
  bool isExtra;
  bool isHybrid;
  String? originalLetter;
  int? originalValue;
  String state;
  String? previousState;
  int useCount;
  double multiplier;

  Tile({
    required this.letter,
    required this.value,
    required this.isExtra,
    this.isHybrid = false,
    this.originalLetter,
    this.originalValue,
    this.state = 'unused',
    this.previousState,
    this.useCount = 0,
    this.multiplier = 1.0,
  });

  void select() {
    if (state == 'unused' || state == 'used') {
      previousState = state;
      state = 'selected';
      if (state == 'used') {
        multiplier *= 2; // Double for reuse
      }
    } else if (state == 'selected') {
      state = previousState ?? 'unused';
      if (previousState == 'used') {
        multiplier /= 2; // Undo if deselected
      }
      previousState = null;
    }
  }

  void markUsed() {
    if (state == 'selected') {
      state = 'used';
      useCount++;
      // Do not double if hybrid
      if (!this.isHybrid) {
        if (value == 1 && useCount == 1) {
          value = 2; // Double on first use for value 1
          multiplier = 2.0; // Set for next doubling
        } else {
          value = (value * multiplier).round(); // Apply multiplier for others
          multiplier = useCount > 0 ? 2.0 : 1.0; // Reset for next use
        }
      }
      previousState = null;
    }
  }

  void revert() {
    if (state == 'selected') {
      state = previousState ?? 'unused';
      if (previousState == 'used') {
        multiplier /= 2; // Undo doubling
      }
      previousState = null;
    }
  }

  void applyWildcard(String wildcardLetter, int wildcardValue) {
    if (state == 'unused') {
      originalLetter ??= letter;
      originalValue ??= value;
      letter = wildcardLetter;
      value = wildcardValue;
      isHybrid = true; // Mark as hybrid
      state = 'unused'; // Keep selectable
    }
  }
}
