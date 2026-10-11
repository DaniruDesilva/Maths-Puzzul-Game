import 'package:flutter_test/flutter_test.dart';
import 'package:number_haven/data/math_level_repository.dart';
import 'package:number_haven/engine/math/models.dart';
import 'package:number_haven/engine/math/puzzle_codec.dart';

void main() {
  group('Number Haven Campaign & Daily Repository Tests', () {
    test('Campaign has 280 levels mapped across difficulties', () {
      expect(MathLevelRepository.totalCampaignLevels, equals(280));

      final level1 = MathLevelRepository.getCampaignLevelSync(1);
      expect(level1.difficulty, equals(Difficulty.easy));

      final level50 = MathLevelRepository.getCampaignLevelSync(50);
      expect(level50.difficulty, equals(Difficulty.medium));

      final level150 = MathLevelRepository.getCampaignLevelSync(150);
      expect(level150.difficulty, equals(Difficulty.hard));

      final level250 = MathLevelRepository.getCampaignLevelSync(250);
      expect(level250.difficulty, equals(Difficulty.expert));
    });

    test('All sample levels have valid interlocking equations and tray numbers', () {
      final sampleLevels = [1, 10, 42, 85, 125, 175, 220, 280];

      for (final lvl in sampleLevels) {
        final puzzle = MathLevelRepository.getCampaignLevelSync(lvl);
        expect(puzzle.equations.isNotEmpty, isTrue);
        expect(puzzle.trayNumbers.isNotEmpty, isTrue);
        expect(puzzle.blankCells.length, equals(puzzle.trayNumbers.length));
      }
    });

    test('Daily challenge is stable for the day and unique per day', () {
      final today = DateTime(2026, 10, 12);
      final p1 = MathLevelRepository.getDailyChallenge(today);
      final p2 = MathLevelRepository.getDailyChallenge(today);
      expect(p1.seed, equals(p2.seed));

      final tomorrow = DateTime(2026, 10, 13);
      final p3 = MathLevelRepository.getDailyChallenge(tomorrow);
      expect(p1.seed, isNot(equals(p3.seed)));
    });

    test('Seed codes resolve correctly from MathLevelRepository', () {
      final code = MathPuzzleCodec.encodeSeed(
        difficulty: Difficulty.hard,
        seed: 777888,
        id: 42,
      );

      final puzzle = MathLevelRepository.getFromSeedCode(code);
      expect(puzzle, isNotNull);
      expect(puzzle!.difficulty, equals(Difficulty.hard));
      expect(puzzle.seed, equals(777888));
      expect(puzzle.id, equals(42));
    });
  });
}
