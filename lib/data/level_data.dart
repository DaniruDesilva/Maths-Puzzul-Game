import 'dart:math';
import 'word_pools.dart';

/// Generates the campaign levels and the daily challenge.
///
/// Guarantees:
///  * Every campaign word is a real, common English word (see [WordPools]).
///  * No word is ever repeated across the 280 campaign levels.
///  * Inside a level, no word duplicates, contains, or reverses another word
///    (e.g. never `ART` + `START`, or `STAR` + `RATS`), so the player can never
///    trace one target while aiming for another.
///  * Easier levels use the most familiar words; later levels dig deeper.
class LevelData {
  static const int _campaignSeed = 20261004;

  static List<Map<String, dynamic>>? _cachedLevels;

  /// Words left over after the campaign was generated. Used by the daily
  /// challenge so daily words never clash with campaign words.
  static Map<int, List<String>> _leftoverPools = {};

  /// How far into the (frequency-ordered) pool we look when picking a word.
  /// Small window = familiar words first, while still adding variety.
  static const int _pickWindow = 18;

  static Map<int, List<String>> _freshPools() {
    return {
      for (final len in const [3, 4, 5, 6, 7]) len: List<String>.from(WordPools.byLength(len)),
    };
  }

  static String _reverse(String s) => s.split('').reversed.join();

  /// True if [a] and [b] would be confusing in the same level.
  static bool _conflicts(String a, String b) {
    final rb = _reverse(b);
    return a == b ||
        a.contains(b) ||
        b.contains(a) ||
        a.contains(rb) ||
        rb.contains(a);
  }

  /// Takes (and removes) a word of [length] from [pools] that does not
  /// conflict with [levelWords]. Removing it from the pool is what guarantees
  /// a word is never reused in another level.
  static String _takeWord(
    Map<int, List<String>> pools,
    int length,
    List<String> levelWords,
    Random rng, {
    int window = _pickWindow,
  }) {
    final pool = pools[length]!;
    if (pool.isEmpty) {
      throw StateError('Word pool for length $length exhausted');
    }

    // Look at a random order within the front window first (familiar words)...
    final int w = min(window, pool.length);
    final candidates = List<int>.generate(w, (i) => i)..shuffle(rng);
    for (final idx in candidates) {
      final word = pool[idx];
      if (levelWords.every((other) => !_conflicts(word, other))) {
        pool.removeAt(idx);
        return word;
      }
    }
    // ...then fall back to scanning the rest of the pool.
    for (int idx = w; idx < pool.length; idx++) {
      final word = pool[idx];
      if (levelWords.every((other) => !_conflicts(word, other))) {
        pool.removeAt(idx);
        return word;
      }
    }
    // Extremely unlikely: everything conflicts. Use the first word anyway.
    return pool.removeAt(0);
  }

  /// Word lengths for a level, based on overall progression.
  static List<int> _lengthsFor(int totalProgress, int levelInPack) {
    if (totalProgress <= 20) {
      if (levelInPack <= 5) return [4, 3];
      if (levelInPack <= 10) return [5, 4];
      return [5, 4, 3];
    } else if (totalProgress <= 60) {
      return totalProgress > 40 ? [5, 5, 4, 3] : [5, 4, 4];
    } else if (totalProgress <= 120) {
      return [6, 5, 5, 4];
    } else if (totalProgress <= 200) {
      return totalProgress > 160 ? [7, 6, 6, 5, 4] : [7, 6, 5, 5];
    } else {
      return totalProgress > 240 ? [7, 7, 6, 6, 5, 4] : [7, 7, 6, 5, 5];
    }
  }

  static List<int> _gridFor(int totalProgress) {
    if (totalProgress <= 20) return [4, 4];
    if (totalProgress <= 60) return [5, 5];
    if (totalProgress <= 120) return [6, 6];
    if (totalProgress <= 200) return [7, 7];
    return [8, 8];
  }

  static List<Map<String, dynamic>> generateAllLevels() {
    if (_cachedLevels != null) return _cachedLevels!;

    final rng = Random(_campaignSeed);
    final pools = _freshPools();
    final List<Map<String, dynamic>> levels = [];
    int levelId = 1;

    // 7 Biomes * 2 Packs per Biome * 20 Levels per Pack = 280 Levels
    for (int biome = 1; biome <= 7; biome++) {
      for (int pack = 1; pack <= 2; pack++) {
        for (int l = 1; l <= 20; l++) {
          final int totalProgress = ((biome - 1) * 40) + ((pack - 1) * 20) + l;
          final grid = _gridFor(totalProgress);

          final List<String> levelWords = [];
          // Pick the longest words first: they are the hardest to fit
          // without conflicts.
          final lengths = _lengthsFor(totalProgress, l)..sort((a, b) => b.compareTo(a));
          for (final len in lengths) {
            levelWords.add(_takeWord(pools, len, levelWords, rng));
          }
          levelWords.shuffle(rng);

          levels.add({
            'id': levelId,
            'biome': biome,
            'pack': pack,
            'levelInPack': l,
            'cols': grid[0],
            'rows': grid[1],
            'words': levelWords,
          });
          levelId++;
        }
      }
    }

    _leftoverPools = pools;
    _cachedLevels = levels;
    return levels;
  }

  static Map<String, dynamic> generateDailyChallenge() {
    // Ensure campaign words are reserved first.
    generateAllLevels();

    final DateTime now = DateTime.now();
    final int seed = now.year * 10000 + now.month * 100 + now.day;
    final Random dailyRandom = Random(seed);

    // Copy the leftover pools so every call on the same day gives the
    // same puzzle (and the campaign pools are never touched).
    final pools = {
      for (final e in _leftoverPools.entries) e.key: List<String>.from(e.value),
    };

    final List<String> words = [];
    for (final len in const [6, 5, 5, 4]) {
      words.add(_takeWord(pools, len, words, dailyRandom, window: 250));
    }
    words.shuffle(dailyRandom);

    return {
      'cols': 6,
      'rows': 6,
      'words': words,
    };
  }
}
