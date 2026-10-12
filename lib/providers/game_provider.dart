import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../engine/math/models.dart';
import '../engine/math/evaluator.dart';
import '../engine/math/hint_engine.dart';
import '../data/math_level_repository.dart';
import '../services/sound_service.dart';

class MathMove {
  final int row;
  final int col;
  final int? prevValue;
  final int? newValue;
  final Set<int>? prevNotes;
  final Set<int>? newNotes;

  const MathMove({
    required this.row,
    required this.col,
    this.prevValue,
    this.newValue,
    this.prevNotes,
    this.newNotes,
  });
}

class GameProvider extends ChangeNotifier {
  MathPuzzle? currentPuzzle;
  int currentLevel = 1;
  int score = 0;
  bool isLevelComplete = false;
  bool isLoading = false;
  bool levelProgressSaved = false;
  bool isDailyChallenge = false;
  bool isCustomPuzzle = false;
  Map<String, int>? lastRewards;

  int hintsUsedInLevel = 0;
  int mistakesInLevel = 0;
  int comboCount = 0;

  // Crossword Grid State
  List<List<int?>> currentValues = [];
  Point<int>? selectedCell;
  List<int> availableTray = [];

  // Notes Mode & Map ("r,c" -> Set<int>)
  bool isNotesMode = false;
  final Map<String, Set<int>> cellNotes = {};

  // Move Stack for Undo
  final List<MathMove> moveHistory = [];

  // Equations status
  final Set<int> satisfiedEquationIds = {};
  final Set<int> violatedEquationIds = {};

  // Smart Hint
  SmartHint? activeHint;

  // Floating feedback message
  String? feedbackMessage;
  int _feedbackToken = 0;

  // Level completion callback
  VoidCallback? onLevelCompleteCallback;

  GameProvider() {
    _init();
  }

  Future<void> _init() async {
    isLoading = true;
    notifyListeners();
    await MathLevelRepository.preloadCampaign();
    await _startCurrentLevel();
  }

  int calculateStars() {
    if (hintsUsedInLevel == 0 && mistakesInLevel == 0) return 3;
    if (hintsUsedInLevel <= 2 && mistakesInLevel <= 2) return 2;
    return 1;
  }

  void showFeedback(String message, {int durationMs = 1200}) {
    feedbackMessage = message;
    final token = ++_feedbackToken;
    notifyListeners();
    Future.delayed(Duration(milliseconds: durationMs), () {
      if (token == _feedbackToken) {
        feedbackMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> _startCurrentLevel() async {
    isLoading = true;
    notifyListeners();

    try {
      if (isDailyChallenge) {
        currentPuzzle = MathLevelRepository.getDailyChallenge(DateTime.now());
      } else if (isCustomPuzzle) {
        currentPuzzle ??= MathLevelRepository.getCampaignLevelSync(1);
      } else {
        currentPuzzle = await MathLevelRepository.getCampaignLevel(currentLevel);
      }

      _resetLevelState();
    } catch (e) {
      debugPrint('Error starting level $currentLevel: $e');
      currentPuzzle = MathLevelRepository.getCampaignLevelSync(currentLevel);
      _resetLevelState();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetLevelState() {
    isLevelComplete = false;
    levelProgressSaved = false;
    score = 0;
    lastRewards = null;
    hintsUsedInLevel = 0;
    mistakesInLevel = 0;
    activeHint = null;
    cellNotes.clear();
    moveHistory.clear();
    satisfiedEquationIds.clear();
    violatedEquationIds.clear();

    if (currentPuzzle == null) return;

    final p = currentPuzzle!;

    // Initialize 2D grid
    currentValues = List.generate(
      p.rows,
      (r) => List.generate(
        p.cols,
        (c) => p.grid[r][c].isGiven ? p.grid[r][c].solutionValue : null,
      ),
    );

    // Initialize tray
    availableTray = List<int>.from(p.trayNumbers)..sort();

    // Auto-select first empty blank cell
    selectedCell = null;
    for (int r = 0; r < p.rows; r++) {
      for (int c = 0; c < p.cols; c++) {
        if (p.grid[r][c].isBlank && currentValues[r][c] == null) {
          selectedCell = Point(r, c);
          break;
        }
      }
      if (selectedCell != null) break;
    }

    _evaluateEquations();
  }

  void startSpecificLevel(int level) {
    currentLevel = level;
    isCustomPuzzle = false;
    isDailyChallenge = false;
    _startCurrentLevel();
  }

  void startDailyChallenge() {
    isDailyChallenge = true;
    isCustomPuzzle = false;
    _startCurrentLevel();
  }

  void startCustomSeed(String seedCode) {
    isCustomPuzzle = true;
    isDailyChallenge = false;
    final puzzle = MathLevelRepository.getFromSeedCode(seedCode);
    if (puzzle != null) {
      currentPuzzle = puzzle;
      _resetLevelState();
      notifyListeners();
    }
  }

  void startCustomLevel([List<String>? words]) {
    isCustomPuzzle = true;
    isDailyChallenge = false;
    currentPuzzle = MathLevelRepository.generateLevelForNumber(currentLevel > 0 ? currentLevel : 1);
    _resetLevelState();
    notifyListeners();
  }

  void restartLevel() {
    _resetLevelState();
    notifyListeners();
  }

  void nextLevel() {
    currentLevel++;
    isDailyChallenge = false;
    isCustomPuzzle = false;
    _startCurrentLevel();
  }

  // --- Board Interaction ---

  void selectCell(int r, int c) {
    if (currentPuzzle == null || isLevelComplete) return;
    final cell = currentPuzzle!.grid[r][c];

    // Only blank number cells can be selected by player
    if (cell.isBlank) {
      selectedCell = Point(r, c);
      SoundService.playClick();
      notifyListeners();
    }
  }

  void toggleNotesMode() {
    isNotesMode = !isNotesMode;
    SoundService.playClick();
    notifyListeners();
  }

  void placeNumber(int number) {
    if (currentPuzzle == null || isLevelComplete) return;

    // If no cell is currently focused, select the first empty blank
    if (selectedCell == null) {
      for (int r = 0; r < currentPuzzle!.rows; r++) {
        for (int c = 0; c < currentPuzzle!.cols; c++) {
          if (currentPuzzle!.grid[r][c].isBlank && currentValues[r][c] == null) {
            selectedCell = Point(r, c);
            break;
          }
        }
        if (selectedCell != null) break;
      }
    }

    if (selectedCell == null) return;
    final r = selectedCell!.x;
    final c = selectedCell!.y;
    final key = '$r,$c';

    if (isNotesMode) {
      // Toggle note candidate
      final notes = Set<int>.from(cellNotes[key] ?? {});
      final prevNotes = Set<int>.from(notes);

      if (notes.contains(number)) {
        notes.remove(number);
      } else {
        notes.add(number);
      }
      cellNotes[key] = notes;

      moveHistory.add(MathMove(
        row: r,
        col: c,
        prevNotes: prevNotes,
        newNotes: notes,
      ));

      SoundService.playClick();
      notifyListeners();
      return;
    }

    // Normal placement mode
    if (!availableTray.contains(number)) return;

    final prevVal = currentValues[r][c];
    final prevNotes = cellNotes[key] != null ? Set<int>.from(cellNotes[key]!) : null;

    // Return previous value to tray if replacing
    if (prevVal != null) {
      availableTray.add(prevVal);
      availableTray.sort();
    }

    // Consume chosen number from tray
    availableTray.remove(number);
    currentValues[r][c] = number;
    cellNotes.remove(key); // Clear notes when number placed

    moveHistory.add(MathMove(
      row: r,
      col: c,
      prevValue: prevVal,
      newValue: number,
      prevNotes: prevNotes,
      newNotes: null,
    ));

    SoundService.playThwack();

    // Check equations and victory condition
    _evaluateEquations();
    _checkLevelSolved();

    // Auto-advance selection to next empty blank cell
    _advanceToNextEmptyBlank();

    notifyListeners();
  }

  void clearSelectedCell() {
    if (currentPuzzle == null || selectedCell == null || isLevelComplete) return;
    final r = selectedCell!.x;
    final c = selectedCell!.y;
    final key = '$r,$c';

    final prevVal = currentValues[r][c];
    final prevNotes = cellNotes[key] != null ? Set<int>.from(cellNotes[key]!) : null;

    if (prevVal == null && (prevNotes == null || prevNotes.isEmpty)) return;

    if (prevVal != null) {
      availableTray.add(prevVal);
      availableTray.sort();
      currentValues[r][c] = null;
    }

    if (prevNotes != null) {
      cellNotes.remove(key);
    }

    moveHistory.add(MathMove(
      row: r,
      col: c,
      prevValue: prevVal,
      newValue: null,
      prevNotes: prevNotes,
      newNotes: null,
    ));

    SoundService.playClick();
    _evaluateEquations();
    notifyListeners();
  }

  void undo() {
    if (moveHistory.isEmpty || isLevelComplete) return;

    final lastMove = moveHistory.removeLast();
    final r = lastMove.row;
    final c = lastMove.col;
    final key = '$r,$c';

    // Revert value
    if (lastMove.newValue != null) {
      // Put placed new value back to tray
      availableTray.add(lastMove.newValue!);
      availableTray.sort();
    }

    if (lastMove.prevValue != null) {
      // Consume prevValue from tray
      availableTray.remove(lastMove.prevValue!);
      currentValues[r][c] = lastMove.prevValue;
    } else {
      currentValues[r][c] = null;
    }

    // Revert notes
    if (lastMove.prevNotes != null && lastMove.prevNotes!.isNotEmpty) {
      cellNotes[key] = Set<int>.from(lastMove.prevNotes!);
    } else {
      cellNotes.remove(key);
    }

    selectedCell = Point(r, c);
    SoundService.playClick();
    _evaluateEquations();
    notifyListeners();
  }

  void _advanceToNextEmptyBlank() {
    if (currentPuzzle == null) return;
    final p = currentPuzzle!;

    for (int r = 0; r < p.rows; r++) {
      for (int c = 0; c < p.cols; c++) {
        if (p.grid[r][c].isBlank && currentValues[r][c] == null) {
          selectedCell = Point(r, c);
          return;
        }
      }
    }
  }

  void _evaluateEquations() {
    if (currentPuzzle == null) return;

    satisfiedEquationIds.clear();
    violatedEquationIds.clear();

    for (final eq in currentPuzzle!.equations) {
      final operands = <int>[];
      bool allFilled = true;

      for (final cell in eq.operandCells) {
        final val = currentValues[cell.row][cell.col];
        if (val == null) {
          allFilled = false;
          break;
        }
        operands.add(val);
      }

      final targetVal = currentValues[eq.resultCell.row][eq.resultCell.col];
      if (targetVal == null) allFilled = false;

      if (allFilled) {
        final isCorrect = MathEvaluator.isSatisfied(operands, eq.operators, targetVal!);
        if (isCorrect) {
          satisfiedEquationIds.add(eq.id);
        } else {
          violatedEquationIds.add(eq.id);
        }
      }
    }
  }

  void _checkLevelSolved() {
    if (currentPuzzle == null || isLevelComplete) return;

    // Check if any blank cell is still empty
    for (int r = 0; r < currentPuzzle!.rows; r++) {
      for (int c = 0; c < currentPuzzle!.cols; c++) {
        if (currentPuzzle!.grid[r][c].isBlank && currentValues[r][c] == null) {
          return; // Still in progress
        }
      }
    }

    // All cells filled. Check if all equations are satisfied
    if (violatedEquationIds.isEmpty &&
        satisfiedEquationIds.length == currentPuzzle!.equations.length) {
      _triggerVictory();
    } else {
      mistakesInLevel++;
      SoundService.playFailure();
      showFeedback('Equations not matching! Check red lines.');
    }
  }

  void _triggerVictory() {
    isLevelComplete = true;
    final eqCount = currentPuzzle?.equations.length ?? 4;
    final diffIndex = currentPuzzle?.difficulty.index ?? 0;
    final baseScore = (eqCount * 120) + (diffIndex * 80);
    score = baseScore + (100 * calculateStars());
    SoundService.playLevelComplete();
    notifyListeners();
    onLevelCompleteCallback?.call();
  }

  // --- Smart Hint ---

  SmartHint? requestSmartHint() {
    if (currentPuzzle == null || isLevelComplete) return null;

    final hint = MathHintEngine.getSmartHint(
      puzzle: currentPuzzle!,
      currentValues: currentValues,
      currentTray: availableTray,
    );

    if (hint != null) {
      activeHint = hint;
      hintsUsedInLevel++;
      selectedCell = hint.targetCell;
      SoundService.playSuccess();
      notifyListeners();
    }

    return hint;
  }

  void applyActiveHint() {
    if (activeHint == null) return;
    placeNumber(activeHint!.solutionValue);
    activeHint = null;
    notifyListeners();
  }

  void dismissActiveHint() {
    activeHint = null;
    notifyListeners();
  }
}
