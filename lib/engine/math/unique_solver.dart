import 'dart:math';
import 'models.dart';
import 'evaluator.dart';

class MathUniqueSolver {
  /// Counts valid solutions using the available tray numbers.
  /// Stops as soon as [stopAt] solutions are found (default 2 to prove uniqueness).
  static int countSolutions({
    required List<List<MathCell>> grid,
    required List<MathEquation> equations,
    required List<int> tray,
    int stopAt = 2,
  }) {
    // 1. Identify blank cells
    final blanks = <Point<int>>[];
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[0].length; c++) {
        if (grid[r][c].isBlank) {
          blanks.add(Point(r, c));
        }
      }
    }

    if (blanks.isEmpty) return 1;

    // 2. Count tray frequencies to avoid duplicate permutation counting
    final trayCounts = <int, int>{};
    for (final num in tray) {
      trayCounts[num] = (trayCounts[num] ?? 0) + 1;
    }

    // 3. Grid value assignments
    final currentValues = List.generate(
      grid.length,
      (r) => List.generate(
        grid[0].length,
        (c) => grid[r][c].isGiven ? grid[r][c].solutionValue : null,
      ),
    );

    // Map each point to the equations it participates in for fast constraint checks
    final pointToEquations = <Point<int>, List<MathEquation>>{};
    for (final eq in equations) {
      for (final cell in eq.numberCells) {
        final pt = Point(cell.row, cell.col);
        pointToEquations.putIfAbsent(pt, () => []).add(eq);
      }
    }

    int solutionsFound = 0;

    bool isEquationValid(MathEquation eq) {
      final nums = <int>[];
      for (final cell in eq.numberCells) {
        final val = currentValues[cell.row][cell.col];
        if (val == null) return true; // Still incomplete, potential valid
        nums.add(val);
      }

      // All numbers in equation are filled; verify mathematical truth
      final operands = nums.sublist(0, nums.length - 1);
      final expected = nums.last;
      return MathEvaluator.isSatisfied(operands, eq.operators, expected);
    }

    void search(int blankIdx) {
      if (solutionsFound >= stopAt) return;

      if (blankIdx == blanks.length) {
        solutionsFound++;
        return;
      }

      final pt = blanks[blankIdx];
      final uniqueTrayVals = trayCounts.keys.toList();

      for (final val in uniqueTrayVals) {
        final count = trayCounts[val]!;
        if (count <= 0) continue;

        // Try assigning
        currentValues[pt.x][pt.y] = val;
        trayCounts[val] = count - 1;

        // Constraint check on intersecting equations
        final relatedEqs = pointToEquations[pt] ?? const [];
        bool allValid = true;
        for (final eq in relatedEqs) {
          if (!isEquationValid(eq)) {
            allValid = false;
            break;
          }
        }

        if (allValid) {
          search(blankIdx + 1);
        }

        // Backtrack
        currentValues[pt.x][pt.y] = null;
        trayCounts[val] = count;

        if (solutionsFound >= stopAt) break;
      }
    }

    search(0);
    return solutionsFound;
  }
}
