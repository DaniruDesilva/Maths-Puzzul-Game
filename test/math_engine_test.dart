import 'package:flutter_test/flutter_test.dart';
import 'package:number_haven/engine/math/models.dart';
import 'package:number_haven/engine/math/evaluator.dart';
import 'package:number_haven/engine/math/layout_generator.dart';
import 'package:number_haven/engine/math/puzzle_factory.dart';
import 'package:number_haven/engine/math/puzzle_codec.dart';
import 'package:number_haven/engine/math/unique_solver.dart';
import 'package:number_haven/engine/math/logic_solver.dart';
import 'package:number_haven/engine/math/hint_engine.dart';
import 'dart:math';

void main() {
  group('PEMDAS Evaluator Tests', () {
    test('Standard PEMDAS operator precedence', () {
      // 2 + 3 * 4 = 14 (not 20)
      expect(
        MathEvaluator.evaluateTokens([2, 3, 4], [Op.add, Op.mul]),
        equals(14),
      );

      // 4 * 3 + 2 = 14
      expect(
        MathEvaluator.evaluateTokens([4, 3, 2], [Op.mul, Op.add]),
        equals(14),
      );

      // 20 - 6 / 2 = 17
      expect(
        MathEvaluator.evaluateTokens([20, 6, 2], [Op.sub, Op.div]),
        equals(17),
      );

      // 12 / 3 * 2 = 8 (left to right for equal precedence)
      expect(
        MathEvaluator.evaluateTokens([12, 3, 2], [Op.div, Op.mul]),
        equals(8),
      );

      // 10 - 4 + 2 = 8 (left to right for equal precedence)
      expect(
        MathEvaluator.evaluateTokens([10, 4, 2], [Op.sub, Op.add]),
        equals(8),
      );
    });

    test('Non-integer division returns null', () {
      // 7 / 2 = 3.5 -> null
      expect(
        MathEvaluator.evaluateTokens([7, 2], [Op.div]),
        isNull,
      );

      // Division by zero -> null
      expect(
        MathEvaluator.evaluateTokens([10, 0], [Op.div]),
        isNull,
      );
    });

    test('Negative intermediate or final results return null', () {
      // 3 - 8 = -5 -> null
      expect(
        MathEvaluator.evaluateTokens([3, 8], [Op.sub]),
        isNull,
      );
    });

    test('isSatisfied correctly validates equations', () {
      // 7 + 5 = 12
      expect(
        MathEvaluator.isSatisfied([7, 5], [Op.add], 12),
        isTrue,
      );

      // 6 + 5 != 12
      expect(
        MathEvaluator.isSatisfied([6, 5], [Op.add], 12),
        isFalse,
      );

      // 3 * 4 - 2 = 10
      expect(
        MathEvaluator.isSatisfied([3, 4, 2], [Op.mul, Op.sub], 10),
        isTrue,
      );
    });
  });

  group('Layout Generator Tests', () {
    test('Generates connected crossword layouts where all intersections are numbers', () {
      final rng = Random(42);
      final layout = MathLayoutGenerator.generate(
        maxRows: 9,
        maxCols: 9,
        targetEquationCount: 4,
        allowLength7: false,
        rng: rng,
      );

      expect(layout, isNotNull);
      expect(layout!.equations.length, greaterThanOrEqualTo(3));

      // Check intersections
      for (int i = 0; i < layout.equations.length; i++) {
        for (int j = i + 1; j < layout.equations.length; j++) {
          final eqA = layout.equations[i];
          final eqB = layout.equations[j];
          final commonCoords = eqA.coordinates.toSet().intersection(eqB.coordinates.toSet());

          for (final pt in commonCoords) {
            // Must intersect at a number slot!
            final idxA = eqA.coordinates.indexOf(pt);
            final idxB = eqB.coordinates.indexOf(pt);
            expect(idxA % 2, equals(0), reason: 'Intersection in eqA must be number slot');
            expect(idxB % 2, equals(0), reason: 'Intersection in eqB must be number slot');
          }
        }
      }
    });
  });

  group('Unique Solver & Logic Deduction Tests', () {
    test('Emergency fallback puzzle is uniquely solvable and logical', () {
      final puzzle = MathPuzzleFactory.generate(
        id: 1,
        seed: 12345,
        difficulty: Difficulty.easy,
      );

      expect(puzzle.grid.isNotEmpty, isTrue);
      expect(puzzle.equations.isNotEmpty, isTrue);
      expect(puzzle.trayNumbers.isNotEmpty, isTrue);

      final solCount = MathUniqueSolver.countSolutions(
        grid: puzzle.grid,
        equations: puzzle.equations,
        tray: puzzle.trayNumbers,
        stopAt: 2,
      );
      expect(solCount, equals(1), reason: 'Must have strictly 1 unique solution');

      final logicRes = MathLogicSolver.solve(
        grid: puzzle.grid,
        equations: puzzle.equations,
        initialTray: puzzle.trayNumbers,
      );
      expect(logicRes.isSolvableByLogic, isTrue);
    });

    test('Hint Engine produces actionable hint step', () {
      final puzzle = MathPuzzleFactory.generate(
        id: 1,
        seed: 12345,
        difficulty: Difficulty.easy,
      );

      final currentGrid = List.generate(
        puzzle.rows,
        (r) => List.generate(
          puzzle.cols,
          (c) => puzzle.grid[r][c].isGiven ? puzzle.grid[r][c].solutionValue : null,
        ),
      );

      final hint = MathHintEngine.getSmartHint(
        puzzle: puzzle,
        currentValues: currentGrid,
        currentTray: List<int>.from(puzzle.trayNumbers),
      );

      expect(hint, isNotNull);
      expect(hint!.explanation.isNotEmpty, isTrue);
      expect(hint.solutionValue, greaterThan(0));
    });
  });

  group('Puzzle Codec Tests', () {
    test('Seed encoding and decoding roundtrip', () {
      const diff = Difficulty.hard;
      const seed = 987654;
      const id = 105;

      final encoded = MathPuzzleCodec.encodeSeed(
        difficulty: diff,
        seed: seed,
        id: id,
      );
      expect(encoded, equals('NH1-H-105-987654'));

      final decoded = MathPuzzleCodec.decodeSeed(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.difficulty, equals(diff));
      expect(decoded.seed, equals(seed));
      expect(decoded.id, equals(id));
    });

    test('Daily seed is deterministic for same date', () {
      final date1 = DateTime(2026, 10, 12);
      final date2 = DateTime(2026, 10, 12);
      final date3 = DateTime(2026, 10, 13);

      expect(MathPuzzleCodec.dailySeedForDate(date1), equals(MathPuzzleCodec.dailySeedForDate(date2)));
      expect(MathPuzzleCodec.dailySeedForDate(date1), isNot(equals(MathPuzzleCodec.dailySeedForDate(date3))));
    });

    test('Full puzzle compression roundtrip', () {
      final puzzle = MathPuzzleFactory.generate(
        id: 1,
        seed: 42,
        difficulty: Difficulty.easy,
      );

      final encoded = MathPuzzleCodec.encodePuzzle(puzzle);
      expect(encoded.isNotEmpty, isTrue);

      final decoded = MathPuzzleCodec.decodePuzzle(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.id, equals(puzzle.id));
      expect(decoded.rows, equals(puzzle.rows));
      expect(decoded.cols, equals(puzzle.cols));
      expect(decoded.trayNumbers, equals(puzzle.trayNumbers));
    });
  });
}
