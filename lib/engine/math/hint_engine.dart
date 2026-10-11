import 'dart:math';
import 'models.dart';
import 'logic_solver.dart';

class SmartHint {
  final Point<int> targetCell;
  final int equationId;
  final int solutionValue;
  final String explanation;
  final LogicTechnique technique;

  const SmartHint({
    required this.targetCell,
    required this.equationId,
    required this.solutionValue,
    required this.explanation,
    required this.technique,
  });
}

class MathHintEngine {
  /// Computes a Smart Deductive Hint based on the player's current board state.
  static SmartHint? getSmartHint({
    required MathPuzzle puzzle,
    required List<List<int?>> currentValues,
    required List<int> currentTray,
  }) {
    // 1. Try to find the next logical human step
    final step = MathLogicSolver.findNextStep(
      grid: puzzle.grid,
      equations: puzzle.equations,
      currentValues: currentValues,
      currentTray: currentTray,
    );

    if (step != null) {
      return SmartHint(
        targetCell: step.targetCell,
        equationId: step.equation.id,
        solutionValue: step.deducedValue,
        explanation: step.explanation,
        technique: step.technique,
      );
    }

    // 2. Fallback: If player got into an unconventional state, find the first remaining empty cell
    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        final cell = puzzle.grid[r][c];
        if (cell.isBlank && currentValues[r][c] == null) {
          final eq = puzzle.equations.firstWhere(
            (e) => e.numberCells.any((nc) => nc.row == r && nc.col == c),
          );
          return SmartHint(
            targetCell: Point(r, c),
            equationId: eq.id,
            solutionValue: cell.solutionValue!,
            explanation:
                'Focus on this equation. Placing ${cell.solutionValue} here unlocks the next step!',
            technique: LogicTechnique.singleUnknown,
          );
        }
      }
    }

    return null;
  }
}
