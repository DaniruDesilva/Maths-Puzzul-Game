import 'dart:convert';
import 'dart:io';
import 'models.dart';

/// Utilities for encoding and decoding puzzles, daily seeds, and shareable level codes.
class MathPuzzleCodec {
  /// Encodes a seed configuration into a compact shareable string (e.g., "NH1-E-1024-42").
  static String encodeSeed({
    required Difficulty difficulty,
    required int seed,
    required int id,
  }) {
    final diffCode = difficulty.name[0].toUpperCase();
    return 'NH1-$diffCode-$id-$seed';
  }

  /// Decodes a shareable seed string back into its parameters.
  static ({Difficulty difficulty, int seed, int id})? decodeSeed(String code) {
    try {
      final parts = code.trim().split('-');
      if (parts.length != 4 || parts[0] != 'NH1') return null;

      Difficulty? difficulty;
      switch (parts[1].toUpperCase()) {
        case 'E':
          difficulty = Difficulty.easy;
          break;
        case 'M':
          difficulty = Difficulty.medium;
          break;
        case 'H':
          difficulty = Difficulty.hard;
          break;
        case 'X':
          difficulty = Difficulty.expert;
          break;
        default:
          return null;
      }

      final id = int.tryParse(parts[2]);
      final seed = int.tryParse(parts[3]);
      if (id == null || seed == null) return null;

      return (difficulty: difficulty, seed: seed, id: id);
    } catch (_) {
      return null;
    }
  }

  /// Generates a deterministic daily challenge seed for a specific calendar date.
  static int dailySeedForDate(DateTime date) {
    // Format: YYYYMMDD with a prime multiplier for good dispersion
    final num = date.year * 10000 + date.month * 100 + date.day;
    return (num * 2654435761) & 0x7FFFFFFF;
  }

  /// Encodes a full MathPuzzle into a compressed Base64 string for offline storage or export.
  static String encodePuzzle(MathPuzzle puzzle) {
    final jsonStr = jsonEncode(puzzle.toJson());
    final bytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(bytes);
    return base64UrlEncode(compressed);
  }

  /// Decodes a compressed Base64 string back into a MathPuzzle.
  static MathPuzzle? decodePuzzle(String encoded) {
    try {
      final compressed = base64Url.decode(encoded);
      final bytes = gzip.decode(compressed);
      final jsonStr = utf8.decode(bytes);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return MathPuzzle.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }
}
