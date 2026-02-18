// File: /lib/models/board_state.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Represents the current state of the game board.
enum BoardState { newBoard, inProgress, finished }

enum Orientation { portrait, landScape, unknown }

/// Extension methods for BoardState
extension BoardStateExtension on BoardState {
  /// Returns a user-friendly display name for the board state
  String get displayName {
    switch (this) {
      case BoardState.newBoard:
        return 'New Board';
      case BoardState.inProgress:
        return 'In Progress';
      case BoardState.finished:
        return 'Finished';
    }
  }

  /// Returns an icon for the board state
  IconData get icon {
    switch (this) {
      case BoardState.newBoard:
        return Icons.verified;
      case BoardState.inProgress:
        return Icons.timer;
      case BoardState.finished:
        return Icons.check_circle_outline;
    }
  }

  /// Returns a color for the board state
  Color get color {
    switch (this) {
      case BoardState.newBoard:
        return AppStyles.classicGameModeColor;
      case BoardState.inProgress:
        return AppStyles.wordSmithGameModeColor;
      case BoardState.finished:
        return AppStyles.masterGameModeColor;
    }
  }
}
