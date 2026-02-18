// File: /lib/models/game_mode.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Supported gameplay modes used for timer, theming, and mode labeling.
enum GameMode { classic, scribe, wordsmith, master }

/// Centralized mode metadata mapping to keep UI + gameplay rules in sync.
extension GameModeExtension on GameMode {
  /// Returns the time limit in minutes for this game mode.
  /// A value of 0 indicates no time limit.
  int get timeLimit {
    switch (this) {
      case GameMode.classic:
        return 0; // No time limit
      case GameMode.scribe:
        return 30; // 30 minutes
      case GameMode.wordsmith:
        return 15; // 15 minutes
      case GameMode.master:
        return 10; // 10 minutes
    }
  }

  /// Friendly mode label used in dialogs and score/summary UI.
  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Classic Mode';
      case GameMode.scribe:
        return 'Scribe';
      case GameMode.wordsmith:
        return 'Wordsmith';
      case GameMode.master:
        return 'Master';
    }
  }

  /// Marketing/UX description used in mode explanation surfaces.
  String get description {
    switch (this) {
      case GameMode.classic:
        return 'Unleash your creativity with no clock to constrain you.\n Weave words at your leisure and conquer the board as a timeless word artisan!';
      case GameMode.scribe:
        return 'Craft brilliant words in 30 minutes.\n Rise to the challenge and etch your skill into the annals of wordcraft as a dedicated Scribe!';
      case GameMode.wordsmith:
        return 'Forge victory in a swift 15 minutes.\n Race the clock to shape a legacy as a bold Wordsmith, mastering every letter!';
      case GameMode.master:
        return 'Command the board in a blazing 10-minute sprint.\n Only true Word Masters will seize glory and dominate the leaderboard!';
    }
  }

  /// Mode accent color used by tiles, labels, and mode tags.
  Color get color {
    switch (this) {
      case GameMode.classic:
        return AppStyles.classicGameModeColor;
      case GameMode.scribe:
        return AppStyles.scribeGameModeColor;
      case GameMode.wordsmith:
        return AppStyles.wordSmithGameModeColor;
      case GameMode.master:
        return AppStyles.masterGameModeColor;
    }
  }

  /// Icon paired with mode labels to reinforce time-pressure tier.
  IconData get icon {
    switch (this) {
      case GameMode.classic:
        return Icons.hourglass_disabled;
      case GameMode.scribe:
        return Icons.hourglass_full;
      case GameMode.wordsmith:
        return Icons.hourglass_top;
      case GameMode.master:
        return Icons.hourglass_bottom;
    }
  }
}
