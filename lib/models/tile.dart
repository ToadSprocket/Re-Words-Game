// models/tile.dart
// Copyright © 2025 Digital Relics. All Rights Reserved.
class Tile {
  String letter;
  int value;
  bool isExtra;
  bool isHybrid;
  bool isRemoved = false;
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
    required this.isRemoved,
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
      if (useCount <= 8) {
        // Cap at 3 uses
        useCount++;
        if (!isHybrid) {
          if (value == 1 && useCount == 2) {
            value = 2; // First use: 1 → 2
            multiplier = 2.0;
          } else if (useCount <= 9) {
            // Apply multiplier up to cap
            value = (value * multiplier).round();
            multiplier = 2.0; // Reset for next use
          }
        }
      }
      previousState = null;
    }
  }

  void revert() {
    if (state == 'selected') {
      state = (useCount > 0) ? 'used' : 'unused'; // Fix: respect useCount
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

  Map<String, dynamic> toJson() => {
    'letter': letter,
    'value': value,
    'isExtra': isExtra,
    'isHybrid': isHybrid,
    'originalLetter': originalLetter,
    'originalValue': originalValue,
    'state': state,
    'previousState': previousState,
    'useCount': useCount,
    'multiplier': multiplier,
    'isRemoved': isRemoved,
  };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
    letter: json['letter'] as String,
    value: json['value'] as int,
    isExtra: json['isExtra'] as bool,
    isHybrid: json['isHybrid'] as bool? ?? false,
    originalLetter: json['originalLetter'] as String?,
    originalValue: json['originalValue'] as int?,
    state: json['state'] as String? ?? 'unused',
    previousState: json['previousState'] as String?,
    useCount: json['useCount'] as int? ?? 0,
    multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
    isRemoved: json['isRemoved'] as bool? ?? false,
  );
}
