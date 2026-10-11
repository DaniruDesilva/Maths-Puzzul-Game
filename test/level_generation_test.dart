import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzle_game/data/level_data.dart';
import 'package:word_puzzle_game/engine/level_engine.dart';

void main() {
  final levels = LevelData.generateAllLevels();

  test('280 levels are generated', () {
    expect(levels.length, 280);
  });

  test('no word is repeated across any level', () {
    final seen = <String, int>{};
    for (final level in levels) {
      for (final w in level['words'] as List<String>) {
        expect(seen.containsKey(w), isFalse,
            reason: '$w appears in level ${seen[w]} and level ${level['id']}');
        seen[w] = level['id'] as int;
      }
    }
  });

  test('no confusing word pairs inside a level', () {
    for (final level in levels) {
      final words = level['words'] as List<String>;
      for (int i = 0; i < words.length; i++) {
        for (int j = i + 1; j < words.length; j++) {
          final a = words[i], b = words[j];
          final rb = b.split('').reversed.join();
          expect(a.contains(b) || b.contains(a) || a.contains(rb) || rb.contains(a), isFalse,
              reason: 'Level ${level['id']}: $a / $b');
        }
      }
    }
  });

  test('every board has each target traceable exactly once', () {
    final sw = Stopwatch()..start();
    for (final level in levels) {
      final words = level['words'] as List<String>;
      final engine = LevelEngine(cols: level['cols'] as int, rows: level['rows'] as int, words: words);
      for (final w in words) {
        expect(engine.countPaths(w, limit: 3), 1,
            reason: 'Level ${level['id']} word $w\n${engine.debugBoard()}');
      }
    }
    // ignore: avoid_print
    print('Built 280 boards in ${sw.elapsedMilliseconds} ms');
  });

  test('daily challenge is stable for the day and valid', () {
    final a = LevelData.generateDailyChallenge();
    final b = LevelData.generateDailyChallenge();
    expect(a['words'], b['words']);
    final words = a['words'] as List<String>;
    final engine = LevelEngine(cols: a['cols'] as int, rows: a['rows'] as int, words: words);
    for (final w in words) {
      expect(engine.countPaths(w, limit: 3), 1);
    }
    // ignore: avoid_print
    print('Daily: $words');
  });

  test('sample levels', () {
    for (final id in [1, 6, 11, 22, 41, 61, 121, 161, 201, 241, 280]) {
      // ignore: avoid_print
      print('Level $id: ${levels[id - 1]['words']}');
    }
  });
}
