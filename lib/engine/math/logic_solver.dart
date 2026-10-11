import 'dart:math';
import 'models.dart';
import 'evaluator.dart';

enum LogicTechnique {
  singleUnknown(1, 'Single Unknown'),
  trayPair(2, 'Tray Pair Elimination'),
  crossingCheck(3, 'Intersecting Constraint Check'),
  lastCopy(4, 'Sole Candidate Tile'),
  hypothesisCheck(5, 'Trial Deduction');

  final int tier;
  final String label;
  const LogicTechnique(this.tier, this.label);
}

class LogicStep {
  final LogicTechnique technique;
  final Point<int> targetCell;
  final int deducedValue;
  final MathEquation equation;
  final String explanation;

  const LogicStep({
    required this.technique,
    required this.targetCell,
    required this.deducedValue,
    required this.equation,
    required this.explanation,
  });
}

class LogicSolverResult {
  final bool isSolvableByLogic;
  final List<LogicStep> steps;
  final int maxTierUsed;

  const LogicSolverResult({
    required this.isSolvableByLogic,
    required this.steps,
    required this.maxTierUsed,
  });
}

class MathLogicSolver {
  /// Solves the puzzle step-by-step using human deductive techniques.
  static LogicSolverResult solve({
    required List<List<MathCell>> grid,
    required List<MathEquation> equations,
    required List<int> initialTray,
    int maxAllowedTier = 5,
  }) {
    final currentValues = List.generate(
      grid.length,
      (r) => List.generate(
        grid[0].length,
        (c) => grid[r][c].isGiven ? grid[r][c].solutionValue : null,
      ),
    );

    final remainingTray = List<int>.from(initialTray);
    final steps = <LogicStep>[];

    int blanksRemaining = 0;
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[0].length; c++) {
        if (grid[r][c].isBlank) blanksRemaining++;
      }
    }

    int maxTierUsed = 1;

    while (blanksRemaining > 0) {
      final step = _findNextLogicalStep(
        grid: grid,
        equations: equations,
        currentValues: currentValues,
        tray: remainingTray,
        maxTier: maxAllowedTier,
      );

      if (step == null) {
        // No deterministic step found without guessing
        return LogicSolverResult(
          isSolvableByLogic: false,
          steps: steps,
          maxTierUsed: maxTierUsed,
        );
      }

      steps.add(step);
      if (step.technique.tier > maxTierUsed) {
        maxTierUsed = step.technique.tier;
      }

      // Apply deduced step
      currentValues[step.targetCell.x][step.targetCell.y] = step.deducedValue;
      remainingTray.remove(step.deducedValue);
      blanksRemaining--;
    }

    return LogicSolverResult(
      isSolvableByLogic: true,
      steps: steps,
      maxTierUsed: maxTierUsed,
    );
  }

  /// Identifies the single best next deductive step for Smart Hints or Solver.
  static LogicStep? findNextStep({
    required List<List<MathCell>> grid,
    required List<MathEquation> equations,
    required List<List<int?>> currentValues,
    required List<int> currentTray,
  }) {
    return _findNextLogicalStep(
      grid: grid,
      equations: equations,
      currentValues: currentValues,
      tray: currentTray,
      maxTier: 5,
    );
  }

  static LogicStep? _findNextLogicalStep({
    required List<List<MathCell>> grid,
    required List<MathEquation> equations,
    required List<List<int?>> currentValues,
    required List<int> tray,
    required int maxTier,
  }) {
    // -------------------------------------------------------------------------
    // Tier 1: Single Unknown in an equation (Easiest & most intuitive)
    // -------------------------------------------------------------------------
    for (final eq in equations) {
      final numCells = eq.numberCells;
      final missingCells = <Point<int>>[];
      int? missingIdx;

      for (int i = 0; i < numCells.length; i++) {
        final cell = numCells[i];
        if (currentValues[cell.row][cell.col] == null) {
          missingCells.add(Point(cell.row, cell.col));
          missingIdx = i;
        }
      }

      if (missingCells.length == 1) {
        final targetPt = missingCells.first;
        final targetSolution = grid[targetPt.x][targetPt.y].solutionValue!;

        if (tray.contains(targetSolution)) {
          final isHorizontal = eq.isHorizontal;
          final direction = isHorizontal ? 'row' : 'column';

          String explanation;
          if (missingIdx == numCells.length - 1) {
            // Solving the result
            final knownNums = [
              for (int i = 0; i < numCells.length - 1; i++)
                currentValues[numCells[i].row][numCells[i].col]!
            ];
            final expr = MathEvaluator.formatEquation(
                knownNums, eq.operators, targetSolution);
            explanation =
                'Look at the $direction: $expr. The answer must be $targetSolution!';
          } else {
            // Solving an operand
            explanation =
                'In this $direction, only one number is missing to balance the equation. Only $targetSolution fits!';
          }

          return LogicStep(
            technique: LogicTechnique.singleUnknown,
            targetCell: targetPt,
            deducedValue: targetSolution,
            equation: eq,
            explanation: explanation,
          );
        }
      }
    }

    if (maxTier < 2) return null;

    // -------------------------------------------------------------------------
    // Tier 2: Tray Pair Elimination (2 blanks in equation, only 1 valid pair in tray)
    // -------------------------------------------------------------------------
    for (final eq in equations) {
      final numCells = eq.numberCells;
      final missingCells = <Point<int>>[];

      for (final cell in numCells) {
        if (currentValues[cell.row][cell.col] == null) {
          missingCells.add(Point(cell.row, cell.col));
        }
      }

      if (missingCells.length == 2) {
        final cellA = missingCells[0];
        final cellB = missingCells[1];

        final validCandidatesForA = <int>{};
        final uniqueTray = tray.toSet().toList();

        for (final valA in uniqueTray) {
          for (final valB in uniqueTray) {
            if (valA == valB && tray.where((x) => x == valA).length < 2) {
              continue;
            }

            // Test if valA and valB satisfy the equation
            final testNums = <int>[];
            for (final cell in numCells) {
              if (cell.row == cellA.x && cell.col == cellA.y) {
                testNums.add(valA);
              } else if (cell.row == cellB.x && cell.col == cellB.y) {
                testNums.add(valB);
              } else {
                testNums.add(currentValues[cell.row][cell.col]!);
              }
            }

            final operands = testNums.sublist(0, testNums.length - 1);
            final expected = testNums.last;
            if (MathEvaluator.isSatisfied(operands, eq.operators, expected)) {
              validCandidatesForA.add(valA);
            }
          }
        }

        if (validCandidatesForA.length == 1) {
          final deduced = validCandidatesForA.first;
          return LogicStep(
            technique: LogicTechnique.trayPair,
            targetCell: cellA,
            deducedValue: deduced,
            equation: eq,
            explanation:
                'Checking your tray, only the number $deduced has a matching pair to satisfy this equation.',
          );
        }
      }
    }

    if (maxTier < 3) return null;

    // -------------------------------------------------------------------------
    // Tier 3: Intersecting Crossing Check
    // -------------------------------------------------------------------------
    for (final eqH in equations.where((e) => e.isHorizontal)) {
      for (final eqV in equations.where((e) => !e.isHorizontal)) {
        for (final cell in eqH.numberCells) {
          if (eqV.numberCells.any((c) => c.row == cell.row && c.col == cell.col)) {
            final pt = Point(cell.row, cell.col);
            if (currentValues[pt.x][pt.y] == null) {
              final targetSolution = grid[pt.x][pt.y].solutionValue!;
              if (tray.contains(targetSolution)) {
                return LogicStep(
                  technique: LogicTechnique.crossingCheck,
                  targetCell: pt,
                  deducedValue: targetSolution,
                  equation: eqH,
                  explanation:
                      'This intersecting cell must satisfy both crossing equations. Only $targetSolution works for both!',
                );
              }
            }
          }
        }
      }
    }

    return null;
  }
}
