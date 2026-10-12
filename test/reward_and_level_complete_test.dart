import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/providers/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProvider Reward Synchronization Tests', () {
    test('First-time level complete with 3 stars awards 80 coins and 150cc brain size', () {
      final user = UserProvider();
      user.coins = 100;
      user.brainSize = 0;
      user.levelsCompleted = 0;

      final rewards = user.recordLevelComplete(
        levelIndex: 1,
        scoreEarned: 600,
        starsEarned: 3,
        hintsUsed: 0,
        isDaily: false,
        isCustom: false,
        equationsSolved: 4,
      );

      // Verify returned breakdown
      expect(rewards['baseCoins'], 50);
      expect(rewards['starCoins'], 30);
      expect(rewards['totalCoins'], 80);
      expect(rewards['brainEarned'], 150);
      expect(rewards['newStars'], 3);
      expect(rewards['isNewLevel'], 1);

      // Verify wallet state
      expect(user.coins, 180);
      expect(user.brainSize, 150);
      expect(user.levelsCompleted, 1);
      expect(user.levelStars[1], 3);
    });

    test('Replaying already completed level with same stars awards 0 coins and 0 brain size', () {
      final user = UserProvider();
      user.coins = 200;
      user.brainSize = 150;
      user.levelsCompleted = 1;
      user.levelStars[1] = 3;

      final rewards = user.recordLevelComplete(
        levelIndex: 1,
        scoreEarned: 600,
        starsEarned: 3,
        hintsUsed: 0,
        isDaily: false,
        isCustom: false,
        equationsSolved: 4,
      );

      expect(rewards['baseCoins'], 0);
      expect(rewards['starCoins'], 0);
      expect(rewards['totalCoins'], 0);
      expect(rewards['brainEarned'], 0);
      expect(rewards['newStars'], 0);
      expect(rewards['isNewLevel'], 0);

      // Balance remains unchanged
      expect(user.coins, 200);
      expect(user.brainSize, 150);
    });

    test('Library building perk awards extra coins per equation on new clear', () {
      final user = UserProvider();
      user.coins = 0;
      user.levelsCompleted = 1;
      user.villageBuildings['library'] = 2; // Stage 2 Library (+2 coins per equation)

      final rewards = user.recordLevelComplete(
        levelIndex: 2,
        scoreEarned: 600,
        starsEarned: 3,
        hintsUsed: 0,
        isDaily: false,
        isCustom: false,
        equationsSolved: 4, // 4 * 2 = 8 bonus coins
      );

      expect(rewards['baseCoins'], 50);
      expect(rewards['starCoins'], 30);
      expect(rewards['libraryCoins'], 8);
      expect(rewards['totalCoins'], 88);
      expect(user.coins, 88);
    });

    test('Hints unification allows useAnyHint with mega and ultra hints', () {
      final user = UserProvider();
      user.hintsRegular = 0;
      user.hintsMega = 2;
      user.hintsUltra = 1;

      expect(user.totalHintsAvailable, 3);
      final used = user.useAnyHint();
      expect(used, isTrue);
      expect(user.hintsMega, 1);
      expect(user.totalHintsAvailable, 2);
    });
  });

  group('GameProvider Score Isolation Tests', () {
    test('GameProvider resets level score to 0 on level restart', () {
      final provider = GameProvider();
      provider.score = 1200;
      provider.restartLevel();
      expect(provider.score, 0);
      expect(provider.lastRewards, isNull);
    });
  });
}
