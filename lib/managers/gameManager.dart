// lib/managers/gameManager.dart
// Copyright © 2026 Digital Relics. All Rights Reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Orientation; // For GlobalKey, BuildContext
import '../components/game_grid_component.dart';
import '../components/wildcard_column_component.dart';
import 'package:reword_game/models/gameMode.dart';
import 'dart:io';
import '../models/board.dart';
import '../models/boardState.dart';
import '../models/tile.dart';
import '../models/apiModels.dart';
import '../services/api_service.dart';
import '../services/word_service.dart';
import '../managers/userManager.dart';
import '../logic/scoring.dart';
import '../utils/wordUtilities.dart';
import '../managers/gameLayoutManager.dart';

class GameManager extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────────────
  // SINGLETON MASTER OBJECT
  // ─────────────────────────────────────────────────────────────────────

  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();

  // ─────────────────────────────────────────────────────────────────────
  // CORE COMPONENTS
  // ─────────────────────────────────────────────────────────────────────

  late final ApiService apiService;
  late final UserManager userManager;
  late final WordService wordService;
  late Board board;

  // ─────────────────────────────────────────────────────────────────────
  // STATE FLAGS
  // ─────────────────────────────────────────────────────────────────────

  bool isInitialized = false;
  bool isLoading = false;
  bool isChangingOrientation = false; // Orientation change tracking
  String message = ''; // UI feedback message

  // ─────────────────────────────────────────────────────────────────────
  // UI COMPONENT REFERENCES
  // ─────────────────────────────────────────────────────────────────────

  GlobalKey<GameGridComponentState>? gridKey;
  GlobalKey<WildcardColumnComponentState>? wildcardKey;
  GameLayoutManager? layoutManager;

  /// Set UI component keys (called from screen widgets)
  void setUIKeys({GlobalKey<GameGridComponentState>? grid, GlobalKey<WildcardColumnComponentState>? wildcard}) {
    gridKey = grid;
    wildcardKey = wildcard;
  }

  // ─────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────

  /// Initialize all components - call once from main.dart
  Future<void> initialize() async {
    if (isInitialized) return;

    // Create services
    apiService = ApiService();
    wordService = WordService();
    userManager = UserManager(apiService: apiService);

    // Initialize word service (load dictionary)
    await wordService.initialize();

    // Load user from storage
    await userManager.loadFromStorage();

    // Try to load existing board, or create empty
    final loadedBoard = await Board.loadBoardFromStorage();
    board = loadedBoard ?? _createEmptyBoard();

    // Start user session tracking
    userManager.startSession();

    isInitialized = true;
  }

  /// Initialize layout manager with BuildContext (Phase 2 of init)
  void initializeLayout(BuildContext context) {
    layoutManager = GameLayoutManager();
    layoutManager!.calculateLayoutSizes(context);
  }

  Board _createEmptyBoard() {
    // Return a minimal empty board
    return Board(
      gameId: '',
      gridLetters: '',
      wildcardLetters: '',
      gridTiles: [],
      wildcardTiles: [],
      puzzleDate: DateTime.now(),
      puzzleExpires: DateTime.now(),
      loadedAt: DateTime.now(),
      sessionStartedAt: null,
      pausedAt: null,
      wordCount: 0,
      estimatedHighScore: 0,
      boardState: BoardState.newBoard,
      gameMode: GameMode.classic,
      sessionStartDateTime: DateTime.now(),
      boardElapsedTime: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BOARD OPERATIONS
  // ─────────────────────────────────────────────────────────────────────

  /// Load a new board from the server
  Future<bool> loadNewBoard() async {
    isLoading = true;

    try {
      // Build score request for current game (if any)
      final scoreRequest = buildScoreRequest();

      // Get new board from API
      final response = await apiService.getGameToday(scoreRequest);
      if (response.gameData == null) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new board from API data
      board = await board.fromApiData(response.gameData!, Orientation.portrait);
      await board.saveBoardToStorage();

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load existing board from storage
  Future<bool> loadStoredBoard() async {
    final loadedBoard = await Board.loadBoardFromStorage();
    if (loadedBoard == null) return false;

    board = loadedBoard;

    // Restore game state (if stored with board)
    // TODO: Load GameState from storage too

    notifyListeners();
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI OPERATIONS
  // ─────────────────────────────────────────────────────────────────────

  /// Submit the current word from selected tiles
  void submitWord() {
    gridKey?.currentState?.submitWord();
  }

  /// Clear all selected tiles
  void clearWords() {
    gridKey?.currentState?.clearSelectedTiles();
    wildcardKey?.currentState?.clearSelectedTiles();
    message = '';
    notifyListeners();
  }

  /// Sync UI components with current board data
  void syncUIComponents() {
    gridKey?.currentState?.reloadTiles();
    wildcardKey?.currentState?.reloadWildcardTiles();
    notifyListeners();
  }

  /// Update UI message and notify
  void setMessage(String msg) {
    message = msg;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // ORIENTATION HANDLING
  // ─────────────────────────────────────────────────────────────────────

  Future<void> handleOrientationChange() async {
    isChangingOrientation = true;
    notifyListeners();

    // Save current state
    await saveState();

    // Small delay for UI to settle
    await Future.delayed(Duration(milliseconds: 300));

    // Restore state
    await restoreState();

    // Sync UI
    syncUIComponents();

    isChangingOrientation = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // GAME FLOW
  // ─────────────────────────────────────────────────────────────────────

  /// Mark game as finished
  void finishGame() {
    board = board.copyWith(boardState: BoardState.finished);
    notifyListeners();
  }

  /// Check if board is valid and playable
  bool get isBoardReady => board.isBoardValid();

  // ─────────────────────────────────────────────────────────────────────
  // WORD OPERATIONS
  // ─────────────────────────────────────────────────────────────────────

  /// Validate a word using the dictionary
  Future<bool> isValidWord(String word) async {
    return await wordService.isValidWord(word.toLowerCase());
  }

  /// Add a word - main gameplay action
  /// Updates gameState.message and notifies listeners automatically.
  /// Returns (success, message) for callers who need the result directly.
  Future<(bool, String)> addWord(List<Tile> selectedTiles) async {
    if (selectedTiles.isEmpty) {
      return (false, '');
    }

    // Build word from tiles
    String word = selectedTiles.map((t) => t.letter).join();
    String casedWord = word.toLowerCase();
    String displayWord = casedWord[0].toUpperCase() + casedWord.substring(1);
    // Calculate score
    int wordScore = Scoring.calculateScore(selectedTiles);

    String resultMessage = '';

    // Check length
    if (casedWord.length < 4) {
      resultMessage = "'$displayWord' too short";
      message = resultMessage;
      notifyListeners();
      return (false, resultMessage);
    }
    if (casedWord.length > 12) {
      resultMessage = "Word too long";
      message = resultMessage;
      notifyListeners();
      return (false, resultMessage);
    }

    // Check validity
    if (!await isValidWord(casedWord)) {
      resultMessage = "'$displayWord' invalid";
      message = resultMessage;
      notifyListeners();
      return (false, resultMessage);
    }

    // Check duplicate
    if (WordUtilities.isDuplicateWord(displayWord, board.spelledWords)) {
      resultMessage = "'$displayWord' already used";
      message = resultMessage;
      notifyListeners();
      board = board.copyWith(spelledWords: [...board.spelledWords, displayWord], score: board.score + wordScore);
      return (false, resultMessage);
    }

    // Check for wildcard bonus
    if (WordUtilities.doesWordContainWildcard(selectedTiles)) {
      double multiplier = WordUtilities.getWildcardMultiplier(selectedTiles);
      int bonusScore = (wordScore * multiplier).toInt();
      wordScore += bonusScore;

      board = board.copyWith(
        spelledWords: [...board.spelledWords, displayWord],
        score: board.score + wordScore,
        wildcardUses: board.wildcardUses + 1, // Increment wildcard count
      );

      resultMessage = "Word score multiplied by $multiplier!";
      message = resultMessage;
      notifyListeners();
      return (true, resultMessage);
    }

    // Add word to state (no wildcard)
    board = board.copyWith(spelledWords: [...board.spelledWords, displayWord], score: board.score + wordScore);
    notifyListeners();

    return (true, '');
  }

  // ─────────────────────────────────────────────────────────────────────
  // SCORE REQUEST (for API submission)
  // ─────────────────────────────────────────────────────────────────────

  SubmitScoreRequest buildScoreRequest() {
    int completionRate = board.wordCount > 0 ? ((board.spelledWords.length / board.wordCount) * 100).ceil() : 0;

    String longestWord = WordUtilities.getLongestWord(board.spelledWords);

    return SubmitScoreRequest(
      userId: userManager.userId ?? '',
      gameId: board.gameId,
      platform: kIsWeb ? 'Web' : Platform.operatingSystem,
      locale: kIsWeb ? 'en-US' : Platform.localeName,
      timePlayedSeconds: userManager.getTotalPlayTime(),
      wordCount: board.spelledWords.length,
      wildcardUses: board.wildcardUses,
      score: board.score,
      completionRate: completionRate,
      longestWordLength: longestWord.length,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SAVE/RESTORE (for orientation change, app lifecycle)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> saveState() async {
    await board.saveBoardToStorage();
    await userManager.saveToStorage();
    // TODO: Save gameState to storage
    notifyListeners();
  }

  Future<void> restoreState() async {
    await loadStoredBoard();
    await userManager.loadFromStorage();
    // TODO: Load gameState from storage

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // APP LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────

  Future<void> onAppPause() async {
    await saveState();
    userManager.pauseSession();
    notifyListeners();
  }

  Future<void> onAppResume() async {
    userManager.resumeSession();

    // Check if board expired
    if (await board.isBoardExpired()) {
      await loadNewBoard();
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────────────

  /// Secret reset - triggered by triple-tap on title (for testing)
  /// Resets the game state and loads a new board
  Future<void> secretReset() async {
    // Show message
    message = "Secret reset activated! Loading new board...";
    notifyListeners();

    // Small delay for user feedback
    await Future.delayed(Duration(milliseconds: 500));

    // Load new board from server
    await loadNewBoard();

    // Sync UI components with new board data
    syncUIComponents();

    // Clear message
    message = '';
    notifyListeners();
  }
}
