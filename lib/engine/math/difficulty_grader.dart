import 'dart:math';
import 'models.dart';
import 'logic_solver.dart';

class DifficultyScore {
  final double compositeScore;
  final int maxLogicTier;
  final double givensRatio;
  final int equationCount;
  final int blankCount;

  const DifficultyScore({
    required this.compositeScore,
    required this.maxLogicTier,
    required this.givensRatio,
    required this.equationCount,
    required this.blankCount,
  });
}

class MathDifficultyGrader {
  /// Evaluates and grades the difficulty of a generated MathPuzzle.
  static DifficultyScore grade(MathPuzzle puzzle) {
    int totalNumberCells = 0;
    int givenCells = 0;
    int maxNumber = 0;

    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        final cell = puzzle.grid[r][c];
        if (cell.isNumber) {
          totalNumberCells++;
          if (cell.isGiven) {
            givenCells++;
          }
          if (cell.solutionValue != null && cell.solutionValue! > maxNumber) {
            maxNumber = cell.solutionValue!;
          }
        }
      }
    }

    final blankCount = totalNumberCells - givenCells;
    final givensRatio =
        totalNumberCells > 0 ? (givenCells / totalNumberCells) : 0.5;

    // Operator weight calculation
    double opWeightSum = 0;
    int totalOps = 0;
    for (final eq in puzzle.equations) {
      for (final op in eq.operators) {
        totalOps++;
        switch (op) {
          case Op.add:
            opWeightSum += 1.0;
            break;
          case Op.sub:
            opWeightSum += 1.2;
            break;
          case Op.mul:
            opWeightSum += 1.8;
            break;
          case Op.div:
            opWeightSum += 2.2;
            break;
        }
      }
    }
    final avgOpWeight = totalOps > 0 ? (opWeightSum / totalOps) : 1.0;

    // Test logic solvability
    final logicResult = MathLogicSolver.solve(
      grid: puzzle.grid,
      equations: puzzle.equations,
      initialTray: puzzle.trayNumbers,
    );

    final maxTier = logicResult.isSolvableByLogic ? logicResult.maxTierUsed : 5;

    // Composite score formula
    final compositeScore = (1.0 - givensRatio) * 40.0 +
        (puzzle.equations.length * 3.5) +
        (avgOpWeight * 8.0) +
        (maxTier * 5.0) +
        (log(max(maxNumber, 2)) * 3.0);

    return DifficultyScore(
      compositeScore: compositeScore,
      maxLogicTier: maxTier,
      givensRatio: givensRatio,
      equationCount: puzzle.equations.length,
      blankCount: blankCount,
    );
  }
}
