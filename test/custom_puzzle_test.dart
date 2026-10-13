import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:number_haven/engine/math/models.dart';
import 'package:number_haven/engine/math/puzzle_codec.dart';
import 'package:number_haven/data/math_level_repository.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/ui/custom_puzzle_screen.dart';

void main() {
  group('MathPuzzleCodec Tests', () {
    test('encodeSeed produces unique letter for all four difficulties', () {
      final easyCode = MathPuzzleCodec.encodeSeed(difficulty: Difficulty.easy, seed: 816268, id: 999);
      final medCode = MathPuzzleCodec.encodeSeed(difficulty: Difficulty.medium, seed: 816268, id: 999);
      final hardCode = MathPuzzleCodec.encodeSeed(difficulty: Difficulty.hard, seed: 816268, id: 999);
      final expCode = MathPuzzleCodec.encodeSeed(difficulty: Difficulty.expert, seed: 816268, id: 999);

      expect(easyCode, 'NH1-E-999-816268');
      expect(medCode, 'NH1-M-999-816268');
      expect(hardCode, 'NH1-H-999-816268');
      expect(expCode, 'NH1-X-999-816268');

      // Crucial: Expert must NOT encode to 'E' (which was the bug causing Expert to play as Easy)
      expect(expCode.contains('-X-'), isTrue);
      expect(expCode.contains('-E-'), isFalse);
    });

    test('decodeSeed correctly resolves all difficulty codes', () {
      final decodedEasy = MathPuzzleCodec.decodeSeed('NH1-E-999-816268');
      final decodedMed = MathPuzzleCodec.decodeSeed('NH1-M-999-816268');
      final decodedHard = MathPuzzleCodec.decodeSeed('NH1-H-999-816268');
      final decodedExp = MathPuzzleCodec.decodeSeed('NH1-X-999-816268');

      expect(decodedEasy?.difficulty, Difficulty.easy);
      expect(decodedMed?.difficulty, Difficulty.medium);
      expect(decodedHard?.difficulty, Difficulty.hard);
      expect(decodedExp?.difficulty, Difficulty.expert);

      expect(decodedExp?.seed, 816268);
      expect(decodedExp?.id, 999);
    });

    test('decodeSeed supports case-insensitivity and aliases', () {
      expect(MathPuzzleCodec.decodeSeed('nh1-x-999-816268')?.difficulty, Difficulty.expert);
      expect(MathPuzzleCodec.decodeSeed('NH1-EXP-999-816268')?.difficulty, Difficulty.expert);
      expect(MathPuzzleCodec.decodeSeed('NH1-EX-999-816268')?.difficulty, Difficulty.expert);
      expect(MathPuzzleCodec.decodeSeed('NH1-EASY-999-816268')?.difficulty, Difficulty.easy);
      expect(MathPuzzleCodec.decodeSeed('NH1-MED-999-816268')?.difficulty, Difficulty.medium);
    });

    test('decodeSeed automatically extracts code when pasted inside full share text', () {
      const fullMessage = '''
Play my custom Number Haven math crossword puzzle!

Difficulty: Expert
Code: NH1-X-999-816268

Download Number Haven: Cozy Math Village and enter this code to play!
''';
      final decoded = MathPuzzleCodec.decodeSeed(fullMessage);
      expect(decoded, isNotNull);
      expect(decoded?.difficulty, Difficulty.expert);
      expect(decoded?.seed, 816268);
      expect(decoded?.id, 999);
    });

    test('Round-trip encode and decode preserves exact properties for all difficulties', () {
      for (final diff in Difficulty.values) {
        final code = MathPuzzleCodec.encodeSeed(difficulty: diff, seed: 554433, id: 999);
        final decoded = MathPuzzleCodec.decodeSeed(code);
        expect(decoded?.difficulty, diff);
        expect(decoded?.seed, 554433);
        expect(decoded?.id, 999);
      }
    });
  });

  group('MathLevelRepository Custom Seed Tests', () {
    test('getFromSeedCode generates correct difficulty puzzle for Expert', () {
      final puzzle = MathLevelRepository.getFromSeedCode('NH1-X-999-816268');
      expect(puzzle, isNotNull);
      expect(puzzle!.difficulty, Difficulty.expert);
      expect(puzzle.seed, 816268);
      // Expert puzzles have more equations than Easy puzzles (easy = 4, expert = 11)
      expect(puzzle.equations.length, greaterThanOrEqualTo(4));
    });

    test('getFromSeedCode generates correct difficulty puzzle for Medium', () {
      final puzzle = MathLevelRepository.getFromSeedCode('NH1-M-999-816268');
      expect(puzzle, isNotNull);
      expect(puzzle!.difficulty, Difficulty.medium);
    });
  });

  group('GameProvider Custom Seed Integration Tests', () {
    test('startCustomSeed loads Expert puzzle and sets custom flags correctly', () {
      final provider = GameProvider();
      final success = provider.startCustomSeed('NH1-X-999-816268');

      expect(success, isTrue);
      expect(provider.isCustomPuzzle, isTrue);
      expect(provider.isDailyChallenge, isFalse);
      expect(provider.currentPuzzle, isNotNull);
      expect(provider.currentPuzzle!.difficulty, Difficulty.expert);
    });
  });

  group('CustomPuzzleScreen Widget Tests', () {
    testWidgets('CustomPuzzleScreen renders and updates share code when switching difficulty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final gameProvider = GameProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ],
          child: const MaterialApp(
            home: CustomPuzzleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('CUSTOM PUZZLE'), findsOneWidget);
      expect(find.text('Craft & Share Crossmath Puzzles'), findsOneWidget);

      // Default selected is Medium: code has NH1-M-999-
      expect(find.textContaining('NH1-M-999-'), findsOneWidget);

      // Tap Expert
      await tester.tap(find.text('Expert'));
      await tester.pumpAndSettle();

      // Crucial: Code must now show NH1-X-999- (NOT NH1-E-999-!)
      expect(find.textContaining('NH1-X-999-'), findsOneWidget);
      expect(find.textContaining('NH1-E-999-'), findsNothing);

      // Tap Easy
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('NH1-E-999-'), findsOneWidget);
      expect(find.textContaining('NH1-X-999-'), findsNothing);

      // Test "Learn More" explainer toggle
      expect(find.text('Learn More'), findsOneWidget);
      await tester.tap(find.text('Learn More'));
      await tester.pumpAndSettle();

      expect(find.text('Hide'), findsOneWidget);
      expect(find.textContaining('Seed = Puzzle DNA'), findsOneWidget);
      expect(find.textContaining('Play Identical Boards'), findsOneWidget);
    });
  });
}
