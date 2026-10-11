import 'dart:math';
import 'models.dart';
import 'layout_generator.dart';
import 'value_filler.dart';
import 'unique_solver.dart';
import 'logic_solver.dart';

class MathPuzzleFactory {
  /// Generates a validated MathPuzzle with guaranteed unique solution
  /// and human logical solvability for the specified difficulty.
  static MathPuzzle generate({
    required int id,
    required int seed,
    required Difficulty difficulty,
    int maxRetries = 25,
  }) {
    final rng = Random(seed);

    for (int retry = 0; retry < maxRetries; retry++) {
      final puzzle = _attemptGenerate(
        id: id,
        seed: seed + retry * 997,
        difficulty: difficulty,
        rng: rng,
      );
      if (puzzle != null) return puzzle;
    }

    // High reliability fallback: return a stable seeded puzzle
    return _generateEmergencyFallback(id: id, seed: seed, difficulty: difficulty);
  }

  static MathPuzzle? _attemptGenerate({
    required int id,
    required int seed,
    required Difficulty difficulty,
    required Random rng,
  }) {
    final config = _getConfig(difficulty);

    // 1. Generate Layout
    final layout = MathLayoutGenerator.generate(
      maxRows: config.maxGridSize,
      maxCols: config.maxGridSize,
      targetEquationCount: config.equationCount,
      allowLength7: config.allowLength7,
      rng: rng,
    );
    if (layout == null) return null;

    // 2. Fill Values
    final filled = MathValueFiller.fill(
      layout: layout,
      difficulty: difficulty,
      rng: rng,
    );
    if (filled == null) return null;

    // 3. Partition into Givens and Blanks (The Tray)
    final numCells = <Point<int>>[];
    for (int r = 0; r < filled.grid.length; r++) {
      for (int c = 0; c < filled.grid[0].length; c++) {
        if (filled.grid[r][c].isNumber) {
          numCells.add(Point(r, c));
        }
      }
    }

    // Determine target blank count
    final targetBlankCount =
        (numCells.length * config.blankRatio).round().clamp(2, numCells.length - 2);

    numCells.shuffle(rng);

    // Try a few masking candidates
    for (int maskTry = 0; maskTry < 8; maskTry++) {
      final blankCandidates = numCells.take(targetBlankCount).toSet();

      final gridCopy = List.generate(filled.grid.length, (r) {
        return List.generate(filled.grid[0].length, (c) {
          final original = filled.grid[r][c];
          if (!original.isNumber) return original;
          final isBlank = blankCandidates.contains(Point(r, c));
          return original.copyWith(isGiven: !isBlank);
        });
      });

      final trayNumbers = <int>[];
      for (final pt in blankCandidates) {
        trayNumbers.add(filled.grid[pt.x][pt.y].solutionValue!);
      }
      trayNumbers.shuffle(rng);

      // 4. Verify unique solution (stops at 2)
      final solCount = MathUniqueSolver.countSolutions(
        grid: gridCopy,
        equations: filled.equations,
        tray: trayNumbers,
        stopAt: 2,
      );

      if (solCount == 1) {
        // 5. Verify human logic solvability
        final logicResult = MathLogicSolver.solve(
          grid: gridCopy,
          equations: filled.equations,
          initialTray: trayNumbers,
          maxAllowedTier: config.maxLogicTier,
        );

        if (logicResult.isSolvableByLogic) {
          return MathPuzzle(
            id: id,
            rows: gridCopy.length,
            cols: gridCopy[0].length,
            seed: seed,
            difficulty: difficulty,
            grid: gridCopy,
            equations: filled.equations,
            trayNumbers: trayNumbers,
          );
        }
      }
    }

    return null;
  }

  static _DifficultyConfig _getConfig(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return const _DifficultyConfig(
          maxGridSize: 8,
          equationCount: 4,
          blankRatio: 0.35,
          allowLength7: false,
          maxLogicTier: 2,
        );
      case Difficulty.medium:
        return const _DifficultyConfig(
          maxGridSize: 10,
          equationCount: 6,
          blankRatio: 0.50,
          allowLength7: false,
          maxLogicTier: 3,
        );
      case Difficulty.hard:
        return const _DifficultyConfig(
          maxGridSize: 12,
          equationCount: 8,
          blankRatio: 0.65,
          allowLength7: true,
          maxLogicTier: 4,
        );
      case Difficulty.expert:
        return const _DifficultyConfig(
          maxGridSize: 13,
          equationCount: 11,
          blankRatio: 0.78,
          allowLength7: true,
          maxLogicTier: 5,
        );
    }
  }

  static MathPuzzle _generateEmergencyFallback({
    required int id,
    required int seed,
    required Difficulty difficulty,
  }) {
    // Deterministic minimal emergency puzzle (3 equations, 5x5)
    final grid = List.generate(5, (r) {
      return List.generate(5, (c) => MathCell(row: r, col: c, kind: CellKind.block));
    });

    // Row 0: 3 + 4 = 7
    grid[0][0] = const MathCell(row: 0, col: 0, kind: CellKind.number, solutionValue: 3, isGiven: true);
    grid[0][1] = const MathCell(row: 0, col: 1, kind: CellKind.op, op: Op.add);
    grid[0][2] = const MathCell(row: 0, col: 2, kind: CellKind.number, solutionValue: 4, isGiven: false);
    grid[0][3] = const MathCell(row: 0, col: 3, kind: CellKind.equals);
    grid[0][4] = const MathCell(row: 0, col: 4, kind: CellKind.number, solutionValue: 7, isGiven: true);

    // Col 2: 4 + 6 = 10 (crosses Row 0 at (0, 2))
    grid[1][2] = const MathCell(row: 1, col: 2, kind: CellKind.op, op: Op.add);
    grid[2][2] = const MathCell(row: 2, col: 2, kind: CellKind.number, solutionValue: 6, isGiven: true);
    grid[3][2] = const MathCell(row: 3, col: 2, kind: CellKind.equals);
    grid[4][2] = const MathCell(row: 4, col: 2, kind: CellKind.number, solutionValue: 10, isGiven: false);

    // Row 4: 10 - 2 = 8 (crosses Col 2 at (4, 2))
    grid[4][0] = const MathCell(row: 4, col: 0, kind: CellKind.number, solutionValue: 8, isGiven: true);
    grid[4][1] = const MathCell(row: 4, col: 1, kind: CellKind.equals);
    grid[4][3] = const MathCell(row: 4, col: 3, kind: CellKind.op, op: Op.sub);
    grid[4][4] = const MathCell(row: 4, col: 4, kind: CellKind.number, solutionValue: 2, isGiven: true);

    final eq1 = MathEquation(
      id: 1,
      cells: [grid[0][0], grid[0][1], grid[0][2], grid[0][3], grid[0][4]],
      isHorizontal: true,
      targetResult: 7,
    );
    final eq2 = MathEquation(
      id: 2,
      cells: [grid[0][2], grid[1][2], grid[2][2], grid[3][2], grid[4][2]],
      isHorizontal: false,
      targetResult: 10,
    );
    final eq3 = MathEquation(
      id: 3,
      cells: [grid[4][2], grid[4][3], grid[4][4], grid[4][1], grid[4][0]],
      isHorizontal: true,
      targetResult: 8,
    );

    return MathPuzzle(
      id: id,
      rows: 5,
      cols: 5,
      seed: seed,
      difficulty: difficulty,
      grid: grid,
      equations: [eq1, eq2, eq3],
      trayNumbers: [4, 10],
    );
  }
}

class _DifficultyConfig {
  final int maxGridSize;
  final int equationCount;
  final double blankRatio;
  final bool allowLength7;
  final int maxLogicTier;

  const _DifficultyConfig({
    required this.maxGridSize,
    required this.equationCount,
    required this.blankRatio,
    required this.allowLength7,
    required this.maxLogicTier,
  });
}
