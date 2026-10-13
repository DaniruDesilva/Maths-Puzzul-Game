import 'dart:convert';
import 'dart:io';
import 'models.dart';

/// Utilities for encoding and decoding puzzles, daily seeds, and shareable level codes.
class MathPuzzleCodec {
  /// Encodes a seed configuration into a compact shareable string (e.g., "NH1-E-1024-42", "NH1-X-999-816268").
  static String encodeSeed({
    required Difficulty difficulty,
    required int seed,
    required int id,
  }) {
    final String diffCode;
    switch (difficulty) {
      case Difficulty.easy:
        diffCode = 'E';
        break;
      case Difficulty.medium:
        diffCode = 'M';
        break;
      case Difficulty.hard:
        diffCode = 'H';
        break;
      case Difficulty.expert:
        diffCode = 'X';
        break;
    }
    return 'NH1-$diffCode-$id-$seed';
  }

  /// Decodes a shareable seed string back into its parameters.
  /// Also supports extracting the code if the user pasted an entire share message.
  static ({Difficulty difficulty, int seed, int id})? decodeSeed(String code) {
    try {
      String clean = code.trim();
      final match = RegExp(r'NH1-[A-Za-z0-9]+-\d+-\d+', caseSensitive: false).firstMatch(clean);
      if (match != null) {
        clean = match.group(0)!;
      }

      final parts = clean.split('-');
      if (parts.length != 4 || parts[0].toUpperCase() != 'NH1') return null;

      Difficulty? difficulty;
      switch (parts[1].toUpperCase()) {
        case 'E':
        case 'EZ':
        case 'EASY':
          difficulty = Difficulty.easy;
          break;
        case 'M':
        case 'MED':
        case 'MEDIUM':
          difficulty = Difficulty.medium;
          break;
        case 'H':
        case 'HRD':
        case 'HARD':
          difficulty = Difficulty.hard;
          break;
        case 'X':
        case 'EX':
        case 'EXP':
        case 'EXPERT':
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
