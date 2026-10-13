import 'package:flutter_test/flutter_test.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SoundService.setSoundEnabled(false);
  });

  group('GameProvider Math Gameplay Tests', () {
    test('Initializes with level 1 puzzle and tray numbers', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentLevel, equals(1));
      expect(provider.currentPuzzle, isNotNull);
      expect(provider.currentValues.isNotEmpty, isTrue);
      expect(provider.availableTray.isNotEmpty, isTrue);
      expect(provider.selectedCell, isNotNull);
    });

    test('Placing a number removes it from tray and updates cell', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialTrayCount = provider.availableTray.length;
      final numberToPlace = provider.availableTray.first;
      final targetCell = provider.selectedCell!;

      provider.placeNumber(numberToPlace);

      expect(provider.currentValues[targetCell.x][targetCell.y], equals(numberToPlace));
      expect(provider.availableTray.length, equals(initialTrayCount - 1));
      expect(provider.moveHistory.length, equals(1));
    });

    test('Undo reverts placed number back to tray', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final numberToPlace = provider.availableTray.first;
      final targetCell = provider.selectedCell!;

      provider.placeNumber(numberToPlace);
      expect(provider.currentValues[targetCell.x][targetCell.y], equals(numberToPlace));

      provider.undo();
      expect(provider.currentValues[targetCell.x][targetCell.y], isNull);
      expect(provider.availableTray.contains(numberToPlace), isTrue);
      expect(provider.moveHistory.isEmpty, isTrue);
    });

    test('Notes mode records pencil candidate marks without placing number', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialTrayCount = provider.availableTray.length;
      final targetCell = provider.selectedCell!;
      final key = '${targetCell.x},${targetCell.y}';

      provider.toggleNotesMode();
      expect(provider.isNotesMode, isTrue);

      provider.placeNumber(7);
      expect(provider.cellNotes[key]?.contains(7), isTrue);
      expect(provider.currentValues[targetCell.x][targetCell.y], isNull);
      expect(provider.availableTray.length, equals(initialTrayCount)); // Tray untouched

      // Toggle off
      provider.placeNumber(7);
      expect(provider.cellNotes[key]?.contains(7) ?? false, isFalse);
    });

    test('Notes mode prevents adding notes to already filled cell', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final targetCell = provider.selectedCell!;
      final key = '${targetCell.x},${targetCell.y}';
      final numberToPlace = provider.availableTray.first;

      // Place number normally
      provider.placeNumber(numberToPlace);
      expect(provider.currentValues[targetCell.x][targetCell.y], equals(numberToPlace));

      // Now turn Notes mode ON and select the filled cell
      provider.toggleNotesMode();
      expect(provider.isNotesMode, isTrue);
      expect(provider.feedbackMessage, contains('Notes Mode ON'));

      provider.selectCell(targetCell.x, targetCell.y);

      // Tapping number on filled cell should show feedback and not corrupt notes
      provider.placeNumber(99);
      expect(provider.currentValues[targetCell.x][targetCell.y], equals(numberToPlace));
      expect(provider.cellNotes[key], isNull);
      expect(provider.feedbackMessage, contains('Clear placed number'));
    });

    test('Smart Hint deductions work and can be applied', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final hint = provider.requestSmartHint();
      expect(hint, isNotNull);
      expect(provider.activeHint, isNotNull);
      expect(provider.hintsUsedInLevel, equals(1));

      provider.applyActiveHint();
      expect(provider.activeHint, isNull);
    });
  });
}
