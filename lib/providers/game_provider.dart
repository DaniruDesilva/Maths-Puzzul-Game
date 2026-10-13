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

  GameProvider({MathPuzzle? initialPuzzle}) {
    if (initialPuzzle != null) {
      currentPuzzle = initialPuzzle;
      isLoading = false;
      _resetLevelState();
    } else {
      _init();
    }
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

  bool startCustomSeed(String seedCode) {
    isCustomPuzzle = true;
    isDailyChallenge = false;
    final puzzle = MathLevelRepository.getFromSeedCode(seedCode);
    if (puzzle != null) {
      currentPuzzle = puzzle;
      _resetLevelState();
      notifyListeners();
      return true;
    }
    return false;
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
    if (isNotesMode) {
      showFeedback('✏️ Notes Mode ON: Tap tray numbers to pencil candidates!', durationMs: 2500);
    } else {
      showFeedback('✍️ Placement Mode: Tap numbers to place onto board', durationMs: 1800);
    }
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
      if (currentValues[r][c] != null) {
        showFeedback('Clear placed number with Erase to add notes!', durationMs: 2000);
        return;
      }

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

  // --- Mega & Ultra Hints ---

  bool applyMegaHint() {
    if (currentPuzzle == null || isLevelComplete) return false;

    // Find candidate incomplete equations:
    // Prefer the equation containing the currently selected cell, if incomplete.
    MathEquation? targetEq;
    if (selectedCell != null) {
      for (final eq in currentPuzzle!.equations) {
        if (!satisfiedEquationIds.contains(eq.id) &&
            eq.numberCells.any((c) => c.row == selectedCell!.x && c.col == selectedCell!.y)) {
          targetEq = eq;
          break;
        }
      }
    }

    // Otherwise, pick the first unsatisfied equation
    if (targetEq == null) {
      for (final eq in currentPuzzle!.equations) {
        if (!satisfiedEquationIds.contains(eq.id)) {
          targetEq = eq;
          break;
        }
      }
    }

    if (targetEq == null) return false;

    activeHint = null;
    _solveEquationDirectly(targetEq);

    hintsUsedInLevel++;
    SoundService.playBonus();
    showFeedback('Mega Hint: Solved 1 full equation!');
    notifyListeners();
    return true;
  }

  bool applyUltraHint() {
    if (currentPuzzle == null || isLevelComplete) return false;

    final incomplete = currentPuzzle!.equations
        .where((eq) => !satisfiedEquationIds.contains(eq.id))
        .toList();

    if (incomplete.isEmpty) return false;

    activeHint = null;
    _solveEquationDirectly(incomplete[0]);

    if (incomplete.length > 1) {
      _solveEquationDirectly(incomplete[1]);
    }

    hintsUsedInLevel += 2;
    SoundService.playBonus();
    showFeedback(incomplete.length > 1
        ? 'Ultra Hint: Solved 2 full equations!'
        : 'Ultra Hint: Solved equation!');
    notifyListeners();
    return true;
  }

  void _solveEquationDirectly(MathEquation eq) {
    if (currentPuzzle == null) return;

    for (final cell in eq.numberCells) {
      if (!cell.isBlank) continue;

      final targetVal = cell.solutionValue;
      if (targetVal == null) continue;

      final r = cell.row;
      final c = cell.col;
      final currentVal = currentValues[r][c];

      if (currentVal == targetVal) continue;

      if (currentVal != null) {
        availableTray.add(currentVal);
      }

      if (availableTray.contains(targetVal)) {
        availableTray.remove(targetVal);
      } else {
        for (int gr = 0; gr < currentPuzzle!.rows; gr++) {
          for (int gc = 0; gc < currentPuzzle!.cols; gc++) {
            if ((gr != r || gc != c) &&
                currentPuzzle!.grid[gr][gc].isBlank &&
                currentValues[gr][gc] == targetVal) {
              currentValues[gr][gc] = null;
              break;
            }
          }
        }
      }

      currentValues[r][c] = targetVal;
      cellNotes.remove('$r,$c');

      moveHistory.add(MathMove(
        row: r,
        col: c,
        prevValue: currentVal,
        newValue: targetVal,
      ));
    }

    availableTray.sort();
    _evaluateEquations();
    _checkLevelSolved();
    _advanceToNextEmptyBlank();
  }
}

