import 'dart:math';
import 'models.dart';

class RawEquationLayout {
  final int id;
  final int startRow;
  final int startCol;
  final bool isHorizontal;
  final int length; // 5 for (N op N = N), 7 for (N op N op N = N)

  const RawEquationLayout({
    required this.id,
    required this.startRow,
    required this.startCol,
    required this.isHorizontal,
    required this.length,
  });

  List<Point<int>> get coordinates {
    final list = <Point<int>>[];
    for (int i = 0; i < length; i++) {
      if (isHorizontal) {
        list.add(Point(startRow, startCol + i));
      } else {
        list.add(Point(startRow + i, startCol));
      }
    }
    return list;
  }

  /// Indices within the equation that are numbers (even indices: 0, 2, 4, etc.)
  List<int> get numberIndices {
    return [for (int i = 0; i < length; i += 2) i];
  }
}

class GridLayoutResult {
  final int rows;
  final int cols;
  final List<List<CellKind>> gridKinds;
  final List<RawEquationLayout> equations;

  const GridLayoutResult({
    required this.rows,
    required this.cols,
    required this.gridKinds,
    required this.equations,
  });
}

class MathLayoutGenerator {
  /// Generates a valid, connected crossword grid layout of interlocking equations.
  static GridLayoutResult? generate({
    required int maxRows,
    required int maxCols,
    required int targetEquationCount,
    required Random rng,
    bool allowLength7 = false,
    int maxAttempts = 50,
  }) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final result = _tryGenerateLayout(
        maxRows: maxRows,
        maxCols: maxCols,
        targetEquationCount: targetEquationCount,
        allowLength7: allowLength7,
        rng: rng,
      );
      if (result != null && result.equations.length >= targetEquationCount - 1) {
        return _trimGrid(result);
      }
    }
    return null;
  }

  static GridLayoutResult? _tryGenerateLayout({
    required int maxRows,
    required int maxCols,
    required int targetEquationCount,
    required bool allowLength7,
    required Random rng,
  }) {
    final grid = List.generate(
      maxRows,
      (_) => List.generate(maxCols, (_) => CellKind.block),
    );

    final equations = <RawEquationLayout>[];

    // Seed the first equation horizontally near the center
    final startLen = (allowLength7 && rng.nextDouble() < 0.3) ? 7 : 5;
    final firstR = maxRows ~/ 2;
    final firstC = (maxCols - startLen) ~/ 2;

    final firstEq = RawEquationLayout(
      id: 1,
      startRow: firstR,
      startCol: firstC,
      isHorizontal: true,
      length: startLen,
    );

    if (!_canPlaceEquation(grid, firstEq, equations)) {
      return null;
    }

    _placeEquation(grid, firstEq);
    equations.add(firstEq);

    // Iteratively branch off existing number cells
    int tries = 0;
    while (equations.length < targetEquationCount && tries < 150) {
      tries++;

      // Pick an existing equation and an intersection number cell
      final baseEq = equations[rng.nextInt(equations.length)];
      final numberIndices = baseEq.numberIndices..shuffle(rng);

      bool placedBranch = false;
      for (final baseIdx in numberIndices) {
        final crossPt = baseEq.coordinates[baseIdx];

        // Ensure this point is not already crossed
        final existingCrossings = equations.where((e) =>
            e.coordinates.any((p) => p.x == crossPt.x && p.y == crossPt.y));
        if (existingCrossings.length >= 2) continue;

        final newHorizontal = !baseEq.isHorizontal;
        final newLen = (allowLength7 && rng.nextDouble() < 0.25) ? 7 : 5;
        final newNumIndices = [for (int i = 0; i < newLen; i += 2) i]..shuffle(rng);

        for (final newIdx in newNumIndices) {
          final int newStartR =
              newHorizontal ? crossPt.x : crossPt.x - newIdx;
          final int newStartC =
              newHorizontal ? crossPt.y - newIdx : crossPt.y;

          final candidate = RawEquationLayout(
            id: equations.length + 1,
            startRow: newStartR,
            startCol: newStartC,
            isHorizontal: newHorizontal,
            length: newLen,
          );

          if (_canPlaceEquation(grid, candidate, equations)) {
            _placeEquation(grid, candidate);
            equations.add(candidate);
            placedBranch = true;
            break;
          }
        }

        if (placedBranch) break;
      }
    }

    if (equations.length < 3) return null;

    return GridLayoutResult(
      rows: maxRows,
      cols: maxCols,
      gridKinds: grid,
      equations: equations,
    );
  }

  static bool _canPlaceEquation(
    List<List<CellKind>> grid,
    RawEquationLayout candidate,
    List<RawEquationLayout> existing,
  ) {
    final maxR = grid.length;
    final maxC = grid[0].length;

    final coords = candidate.coordinates;

    // 1. Boundary check (with 1-cell border margin for clean display)
    for (final p in coords) {
      if (p.x < 0 || p.x >= maxR || p.y < 0 || p.y >= maxC) return false;
    }

    // 2. Head and Tail spacing check (must be empty before start and after end)
    final Point<int> beforeStart = candidate.isHorizontal
        ? Point(candidate.startRow, candidate.startCol - 1)
        : Point(candidate.startRow - 1, candidate.startCol);
    if (beforeStart.x >= 0 &&
        beforeStart.x < maxR &&
        beforeStart.y >= 0 &&
        beforeStart.y < maxC) {
      if (grid[beforeStart.x][beforeStart.y] != CellKind.block) return false;
    }

    final Point<int> afterEnd = candidate.isHorizontal
        ? Point(candidate.startRow, candidate.startCol + candidate.length)
        : Point(candidate.startRow + candidate.length, candidate.startCol);
    if (afterEnd.x >= 0 &&
        afterEnd.x < maxR &&
        afterEnd.y >= 0 &&
        afterEnd.y < maxC) {
      if (grid[afterEnd.x][afterEnd.y] != CellKind.block) return false;
    }

    // 3. Coordinate validation
    int sharedCount = 0;
    for (int i = 0; i < candidate.length; i++) {
      final p = coords[i];
      final currentKind = grid[p.x][p.y];
      final isNumberPos = i % 2 == 0;

      if (currentKind != CellKind.block) {
        // Can only intersect at NUMBER cells
        if (!isNumberPos || currentKind != CellKind.number) return false;
        sharedCount++;
      } else {
        // Neighbor checks: ensure no side-by-side unintended collisions
        if (candidate.isHorizontal) {
          // Check top and bottom neighbors
          for (final dy in [-1, 1]) {
            final nr = p.x + dy;
            if (nr >= 0 && nr < maxR) {
              if (grid[nr][p.y] != CellKind.block) {
                // Allowed only if this is an intersecting perpendicular equation
                final isCrossing = existing.any((e) =>
                    !e.isHorizontal &&
                    e.coordinates.any((pt) => pt.x == p.x && pt.y == p.y));
                if (!isCrossing) return false;
              }
            }
          }
        } else {
          // Check left and right neighbors
          for (final dx in [-1, 1]) {
            final nc = p.y + dx;
            if (nc >= 0 && nc < maxC) {
              if (grid[p.x][nc] != CellKind.block) {
                final isCrossing = existing.any((e) =>
                    e.isHorizontal &&
                    e.coordinates.any((pt) => pt.x == p.x && pt.y == p.y));
                if (!isCrossing) return false;
              }
            }
          }
        }
      }
    }

    // New equation must intersect with existing equations (unless it's the very first)
    if (existing.isNotEmpty && (sharedCount < 1 || sharedCount > 3)) {
      return false;
    }

    return true;
  }

  static void _placeEquation(
    List<List<CellKind>> grid,
    RawEquationLayout eq,
  ) {
    final coords = eq.coordinates;
    for (int i = 0; i < eq.length; i++) {
      final p = coords[i];
      if (i % 2 == 0) {
        grid[p.x][p.y] = CellKind.number;
      } else if (i == eq.length - 2) {
        grid[p.x][p.y] = CellKind.equals;
      } else {
        grid[p.x][p.y] = CellKind.op;
      }
    }
  }

  /// Trims excess blank borders around the generated layout to minimize grid size.
  static GridLayoutResult _trimGrid(GridLayoutResult raw) {
    int minR = raw.rows, maxR = 0, minC = raw.cols, maxC = 0;

    for (final eq in raw.equations) {
      for (final p in eq.coordinates) {
        if (p.x < minR) minR = p.x;
        if (p.x > maxR) maxR = p.x;
        if (p.y < minC) minC = p.y;
        if (p.y > maxC) maxC = p.y;
      }
    }

    final trimmedRows = (maxR - minR + 1);
    final trimmedCols = (maxC - minC + 1);

    final trimmedGrid = List.generate(
      trimmedRows,
      (r) => List.generate(
        trimmedCols,
        (c) => raw.gridKinds[r + minR][c + minC],
      ),
    );

    final shiftedEquations = raw.equations.map((eq) {
      return RawEquationLayout(
        id: eq.id,
        startRow: eq.startRow - minR,
        startCol: eq.startCol - minC,
        isHorizontal: eq.isHorizontal,
        length: eq.length,
      );
    }).toList();

    return GridLayoutResult(
      rows: trimmedRows,
      cols: trimmedCols,
      gridKinds: trimmedGrid,
      equations: shiftedEquations,
    );
  }
}
