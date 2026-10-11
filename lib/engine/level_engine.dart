import 'package:flutter/foundation.dart';
import 'dart:math';

class HexCell {
  final int q; // col (x)
  final int r; // row (y)
  String letter;
  bool isFound;
  bool isFever; // For combo effects
  bool isHinted; // For persistent hints
  int version;

  HexCell({
    required this.q,
    required this.r,
    required this.letter,
    this.isFound = false,
    this.isFever = false,
    this.isHinted = false,
    this.version = 0,
  });
}

class LevelEngine {
  final int cols; // width
  final int rows; // height
  final List<String> words;
  late List<List<HexCell>> grid; // grid[col][row]
  final Random _random = Random();

  /// English letter frequencies (x1000). Filler letters follow natural English
  /// distribution so the board looks like real language (and hides the target
  /// words better) instead of being full of Z/X/J. `Q` is excluded because it
  /// is useless without a following `U`.
  static const Map<String, int> _letterWeights = {
    'E': 120, 'T': 85, 'A': 85, 'O': 75, 'I': 72, 'N': 67, 'S': 63, 'R': 60,
    'H': 40, 'L': 42, 'D': 40, 'C': 30, 'U': 30, 'M': 26, 'P': 22, 'G': 22,
    'B': 18, 'F': 18, 'Y': 18, 'W': 16, 'K': 10, 'V': 10, 'X': 3, 'J': 2, 'Z': 2,
  };
  static final List<String> _weightedLetters = [
    for (final e in _letterWeights.entries) ...List.filled(e.value, e.key),
  ];

  LevelEngine({required this.cols, required this.rows, required this.words}) {
    if (!_build(words)) {
      // Should never happen, but make sure the board is at least playable.
      _fillEmptySpaces();
    }
  }

  bool rePlaceWords(List<String> remaining) {
    return _build(remaining);
  }

  /// Builds a fresh board for [wordsToPlace].
  ///
  /// 1. Words are placed WITHOUT sharing tiles, so every target owns its own
  ///    tiles (finding one word can never break or "re-show" another).
  /// 2. Empty tiles are filled with natural-looking letters.
  /// 3. The board is verified so every target can be traced in exactly ONE
  ///    way - filler letters can never create a duplicate copy of a target.
  bool _build(List<String> wordsToPlace) {
    final upper = wordsToPlace.map((w) => w.toUpperCase()).toList();
    // Longest words first: they are hardest to fit.
    final ordered = List<String>.from(upper)..sort((a, b) => b.length.compareTo(a.length));

    for (int pass = 0; pass < 2; pass++) {
      final bool allowShared = pass == 1; // last-resort fallback for crowded boards
      for (int attempt = 0; attempt < 60; attempt++) {
        _initGrid();
        if (!_placeWords(ordered, allowShared)) continue;

        // Try several filler variations for this placement.
        final placed = _snapshotLetters();
        for (int fill = 0; fill < 25; fill++) {
          _restoreLetters(placed);
          _fillEmptySpaces();
          if (allowShared || upper.every((w) => countPaths(w, limit: 2) == 1)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<List<String>> _snapshotLetters() =>
      List.generate(cols, (q) => List.generate(rows, (r) => grid[q][r].letter));

  void _restoreLetters(List<List<String>> snap) {
    for (int q = 0; q < cols; q++) {
      for (int r = 0; r < rows; r++) {
        grid[q][r].letter = snap[q][r];
      }
    }
  }

  void _initGrid() {
    grid = List.generate(cols, (q) {
      return List.generate(rows, (r) {
        return HexCell(q: q, r: r, letter: ' ');
      });
    });
  }

  // Get valid neighbors in an odd-q vertical layout
  List<HexCell> getNeighbors(int q, int r) {
    List<HexCell> neighbors = [];
    List<List<int>> dirs;
    if (q.isEven) {
      dirs = [[1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [0, 1]];
    } else {
      dirs = [[1, 1], [1, 0], [0, -1], [-1, 0], [-1, 1], [0, 1]];
    }

    for (var dir in dirs) {
      int nq = q + dir[0];
      int nr = r + dir[1];
      if (nq >= 0 && nq < cols && nr >= 0 && nr < rows) {
        neighbors.add(grid[nq][nr]);
      }
    }
    return neighbors;
  }

  bool _placeWords(List<String> wordsToPlace, bool allowShared) {
    for (final word in wordsToPlace) {
      // Try every start cell in random order.
      final starts = <List<int>>[
        for (int q = 0; q < cols; q++)
          for (int r = 0; r < rows; r++) [q, r],
      ]..shuffle(_random);

      bool placed = false;
      for (final s in starts) {
        if (_tryPlaceWordDFS(word, 0, s[0], s[1], <String>{}, allowShared)) {
          placed = true;
          break;
        }
      }
      if (!placed) return false;
    }
    return true;
  }

  bool _tryPlaceWordDFS(String word, int index, int q, int r, Set<String> visited, bool allowShared) {
    if (visited.contains('$q,$r')) return false;

    final current = grid[q][r].letter;
    if (current != ' ') {
      // Tiles are exclusive to one word unless we're in fallback mode.
      if (!allowShared || current != word[index]) return false;
    }

    if (index == word.length - 1) {
      grid[q][r].letter = word[index];
      return true;
    }

    visited.add('$q,$r');
    grid[q][r].letter = word[index];

    List<HexCell> neighbors = getNeighbors(q, r)..shuffle(_random);
    for (var neighbor in neighbors) {
      if (_tryPlaceWordDFS(word, index + 1, neighbor.q, neighbor.r, visited, allowShared)) {
        return true;
      }
    }

    // Backtrack
    grid[q][r].letter = current;
    visited.remove('$q,$r');
    return false;
  }

  void _fillEmptySpaces() {
    for (int q = 0; q < cols; q++) {
      for (int r = 0; r < rows; r++) {
        if (grid[q][r].letter == ' ') {
          grid[q][r].letter = _weightedLetters[_random.nextInt(_weightedLetters.length)];
        }
      }
    }
  }

  /// Counts the distinct tile-sets on which [word] can be traced (forwards
  /// or backwards). Stops counting at [limit]. Found/removed tiles are ignored.
  int countPaths(String word, {int limit = 2}) {
    final keys = <String>{};
    final w = word.toUpperCase();
    for (final candidate in {w, w.split('').reversed.join()}) {
      for (int q = 0; q < cols; q++) {
        for (int r = 0; r < rows; r++) {
          final c = grid[q][r];
          if (c.isFound || c.letter != candidate[0]) continue;
          _collectPaths(candidate, 0, c, [c], keys, limit);
          if (keys.length >= limit) return keys.length;
        }
      }
    }
    return keys.length;
  }

  void _collectPaths(String word, int index, HexCell cell, List<HexCell> path, Set<String> keys, int limit) {
    if (keys.length >= limit) return;
    if (index == word.length - 1) {
      final ids = path.map((c) => c.q * 100 + c.r).toList()..sort();
      keys.add(ids.join(','));
      return;
    }
    for (final n in getNeighbors(cell.q, cell.r)) {
      if (n.isFound || path.contains(n) || n.letter != word[index + 1]) continue;
      path.add(n);
      _collectPaths(word, index + 1, n, path, keys, limit);
      path.removeLast();
      if (keys.length >= limit) return;
    }
  }

  @visibleForTesting
  String debugBoard() {
    final sb = StringBuffer();
    for (int r = 0; r < rows; r++) {
      for (int q = 0; q < cols; q++) {
        sb.write(grid[q][r].letter);
      }
      sb.writeln();
    }
    return sb.toString();
  }
}
