import 'dart:math';
import 'models.dart';
import 'evaluator.dart';
import 'layout_generator.dart';

class ValueFillerResult {
  final List<List<MathCell>> grid;
  final List<MathEquation> equations;

  const ValueFillerResult({
    required this.grid,
    required this.equations,
  });
}

class MathValueFiller {
  /// Solves and assigns valid numbers and operators to a given layout skeleton.
  static ValueFillerResult? fill({
    required GridLayoutResult layout,
    required Difficulty difficulty,
    required Random rng,
    int maxTries = 40,
  }) {
    for (int t = 0; t < maxTries; t++) {
      final result = _backtrackFill(layout, difficulty, rng);
      if (result != null) return result;
    }
    return null;
  }

  static ValueFillerResult? _backtrackFill(
    GridLayoutResult layout,
    Difficulty difficulty,
    Random rng,
  ) {
    // 2D grid of solution values and operators
    final cellValues = List.generate(
      layout.rows,
      (_) => List<int?>.filled(layout.cols, null),
    );
    final cellOps = List.generate(
      layout.rows,
      (_) => List<Op?>.filled(layout.cols, null),
    );

    final allowedOps = _getAllowedOperators(difficulty);
    final maxNum = _getMaxNumber(difficulty);

    bool solveEquationIndex(int eqIdx) {
      if (eqIdx >= layout.equations.length) return true;

      final eq = layout.equations[eqIdx];
      final coords = eq.coordinates;

      // Identify number cell coordinates and operator coordinates
      final numPoints = [for (int i = 0; i < eq.length; i += 2) coords[i]];
      final opPoints = [for (int i = 1; i < eq.length - 2; i += 2) coords[i]];

      // Shuffle operator choices
      final opCombinations = _generateOperatorCombinations(
        opCount: opPoints.length,
        allowed: allowedOps,
        rng: rng,
      );

      for (final ops in opCombinations) {
        // Attempt to find numbers that satisfy: operands -> result
        final candidateNumberSets = _findCandidateNumbers(
          numPoints: numPoints,
          currentGridValues: cellValues,
          ops: ops,
          maxNum: maxNum,
          rng: rng,
        );

        for (final nums in candidateNumberSets) {
          // Temporarily assign
          for (int i = 0; i < numPoints.length; i++) {
            cellValues[numPoints[i].x][numPoints[i].y] = nums[i];
          }
          for (int i = 0; i < opPoints.length; i++) {
            cellOps[opPoints[i].x][opPoints[i].y] = ops[i];
          }

          if (solveEquationIndex(eqIdx + 1)) {
            return true;
          }

          // Backtrack: only clear cells that weren't fixed prior to this equation
          // (Handled cleanly since earlier equations override their own cells)
        }
      }

      // Revert values for this equation
      for (final p in numPoints) {
        // Only clear if not part of an earlier equation
        bool usedInEarlier = false;
        for (int i = 0; i < eqIdx; i++) {
          if (layout.equations[i].coordinates.contains(p)) {
            usedInEarlier = true;
            break;
          }
        }
        if (!usedInEarlier) {
          cellValues[p.x][p.y] = null;
        }
      }
      for (final p in opPoints) {
        cellOps[p.x][p.y] = null;
      }

      return false;
    }

    if (!solveEquationIndex(0)) {
      return null;
    }

    // Convert into final MathCells and MathEquations
    final finalGrid = List.generate(layout.rows, (r) {
      return List.generate(layout.cols, (c) {
        final kind = layout.gridKinds[r][c];
        return MathCell(
          row: r,
          col: c,
          kind: kind,
          op: cellOps[r][c],
          solutionValue: cellValues[r][c],
          isGiven: false,
        );
      });
    });

    final finalEquations = <MathEquation>[];
    for (int i = 0; i < layout.equations.length; i++) {
      final eqLayout = layout.equations[i];
      final eqCells = eqLayout.coordinates
          .map((p) => finalGrid[p.x][p.y])
          .toList();
      final target = cellValues[eqLayout.coordinates.last.x]
          [eqLayout.coordinates.last.y]!;

      finalEquations.add(MathEquation(
        id: eqLayout.id,
        cells: eqCells,
        isHorizontal: eqLayout.isHorizontal,
        targetResult: target,
      ));
    }

    return ValueFillerResult(
      grid: finalGrid,
      equations: finalEquations,
    );
  }

  static List<Op> _getAllowedOperators(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return const [Op.add, Op.sub];
      case Difficulty.medium:
        return const [Op.add, Op.sub, Op.mul];
      case Difficulty.hard:
      case Difficulty.expert:
        return const [Op.add, Op.sub, Op.mul, Op.div];
    }
  }

  static int _getMaxNumber(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 20;
      case Difficulty.medium:
        return 45;
      case Difficulty.hard:
        return 80;
      case Difficulty.expert:
        return 120;
    }
  }

  static List<List<Op>> _generateOperatorCombinations({
    required int opCount,
    required List<Op> allowed,
    required Random rng,
  }) {
    final list = <List<Op>>[];
    if (opCount == 1) {
      final shuffled = List<Op>.from(allowed)..shuffle(rng);
      for (final op in shuffled) {
        list.add([op]);
      }
    } else {
      // 2 operators (for 7-length equations)
      for (final op1 in allowed) {
        for (final op2 in allowed) {
          list.add([op1, op2]);
        }
      }
      list.shuffle(rng);
    }
    return list;
  }

  static List<List<int>> _findCandidateNumbers({
    required List<Point<int>> numPoints,
    required List<List<int?>> currentGridValues,
    required List<Op> ops,
    required int maxNum,
    required Random rng,
  }) {
    final candidates = <List<int>>[];
    final knownValues = [for (final p in numPoints) currentGridValues[p.x][p.y]];

    // Case 1: Standard 3-number equation (a op b = c)
    if (numPoints.length == 3) {
      final knownA = knownValues[0];
      final knownB = knownValues[1];
      final knownC = knownValues[2];
      final op = ops[0];

      final samplePool = [for (int i = 1; i <= maxNum; i++) i]..shuffle(rng);

      for (final a in (knownA != null ? [knownA] : samplePool)) {
        for (final b in (knownB != null ? [knownB] : samplePool)) {
          if (op == Op.div && (b == 0 || a % b != 0)) continue;
          final c = MathEvaluator.evaluateTokens([a, b], [op]);
          if (c == null || c <= 0 || c > maxNum + 20) continue;
          if (knownC != null && knownC != c) continue;

          candidates.add([a, b, c]);
          if (candidates.length >= 8) return candidates;
        }
      }
    } else if (numPoints.length == 4) {
      // Case 2: Extended 4-number equation (a op1 b op2 c = d)
      final knownA = knownValues[0];
      final knownB = knownValues[1];
      final knownC = knownValues[2];
      final knownD = knownValues[3];

      final samplePool = [for (int i = 1; i <= min(maxNum, 35); i++) i]..shuffle(rng);

      for (final a in (knownA != null ? [knownA] : samplePool.take(15))) {
        for (final b in (knownB != null ? [knownB] : samplePool.take(15))) {
          for (final c in (knownC != null ? [knownC] : samplePool.take(15))) {
            final d = MathEvaluator.evaluateTokens([a, b, c], ops);
            if (d == null || d <= 0 || d > maxNum + 30) continue;
            if (knownD != null && knownD != d) continue;

            candidates.add([a, b, c, d]);
            if (candidates.length >= 6) return candidates;
          }
        }
      }
    }

    return candidates;
  }
}
