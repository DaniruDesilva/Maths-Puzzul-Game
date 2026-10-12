import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/data/village_data.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
  });

  group('Village Progression & Economy Gating Tests', () {
    test('Oakheart Village buildings enforce required levels and rebalanced costs', () {
      final meadow = VillageData.meadow;
      expect(meadow.buildings.length, 5);

      final cottage = meadow.buildings.firstWhere((b) => b.id == 'cottage');
      final bakery = meadow.buildings.firstWhere((b) => b.id == 'bakery');
      final windmill = meadow.buildings.firstWhere((b) => b.id == 'windmill');
      final library = meadow.buildings.firstWhere((b) => b.id == 'library');
      final tower = meadow.buildings.firstWhere((b) => b.id == 'tower');

      // Check level gates
      expect(cottage.requiredLevel, 1);
      expect(bakery.requiredLevel, 6);
      expect(windmill.requiredLevel, 14);
      expect(library.requiredLevel, 22);
      expect(tower.requiredLevel, 30);

      // Check stage 1 costs
      expect(cottage.costs[0], 100);
      expect(bakery.costs[0], 200);
      expect(windmill.costs[0], 350);
      expect(library.costs[0], 500);
      expect(tower.costs[0], 800);

      // Check total stages and max costs
      expect(cottage.costs, [100, 250, 500]);
      expect(bakery.costs, [200, 450, 850]);
      expect(windmill.costs, [350, 750, 1400]);
      expect(library.costs, [500, 1100, 2000]);
      expect(tower.costs, [800, 1600, 3000]);
    });

    test('UserProvider tracks current level and upgrades buildings when eligible', () {
      final user = UserProvider();
      user.levelsCompleted = 5; // currentLevel is 6

      expect(user.currentLevel, 6);

      final bakery = VillageData.meadow.buildings.firstWhere((b) => b.id == 'bakery');
      expect(user.currentLevel >= bakery.requiredLevel, isTrue);

      final windmill = VillageData.meadow.buildings.firstWhere((b) => b.id == 'windmill');
      expect(user.currentLevel >= windmill.requiredLevel, isFalse); // Locked until level 14
    });
  });

  group('Hint Power-Ups Isolation & Inventory Tests', () {
    test('Independent hint deductions: regular hints do not burn mega or ultra hints', () {
      final user = UserProvider();
      user.hintsRegular = 2;
      user.hintsMega = 3;
      user.hintsUltra = 1;

      expect(user.useRegularHint(), isTrue);
      expect(user.hintsRegular, 1);
      expect(user.hintsMega, 3);
      expect(user.hintsUltra, 1);

      expect(user.useMegaHint(), isTrue);
      expect(user.hintsRegular, 1);
      expect(user.hintsMega, 2);
      expect(user.hintsUltra, 1);

      expect(user.useUltraHint(), isTrue);
      expect(user.hintsRegular, 1);
      expect(user.hintsMega, 2);
      expect(user.hintsUltra, 0);

      // Ultra hint is now 0
      expect(user.useUltraHint(), isFalse);
    });

    test('useHint uses regular hint and never deducts Mega hint', () {
      final user = UserProvider();
      user.hintsRegular = 0;
      user.hintsMega = 5;

      expect(user.useHint(), isFalse);
      expect(user.hintsMega, 5); // Remains protected
    });
  });

  group('Mega Hint & Ultra Hint Game Engine Execution Tests', () {
    test('applyMegaHint solves an entire equation on the active board', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentPuzzle, isNotNull);
      final initialSatisfied = provider.satisfiedEquationIds.length;

      // Apply Mega Hint
      final success = provider.applyMegaHint();
      expect(success, isTrue);

      // Satisfied equation count must have increased
      expect(provider.satisfiedEquationIds.length, greaterThan(initialSatisfied));
      expect(provider.hintsUsedInLevel, 1);
    });

    test('applyUltraHint solves 2 equations or the whole board', () async {
      final provider = GameProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentPuzzle, isNotNull);
      final totalEqs = provider.currentPuzzle!.equations.length;

      final success = provider.applyUltraHint();
      expect(success, isTrue);

      // Should have solved at least 2 equations (or all if total <= 2)
      expect(provider.satisfiedEquationIds.length, greaterThanOrEqualTo(2.clamp(1, totalEqs)));
      expect(provider.hintsUsedInLevel, 2);
    });
  });
}
