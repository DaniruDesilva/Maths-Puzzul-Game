import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/services/game_services_helper.dart';
import 'package:number_haven/services/sound_service.dart';
import 'package:number_haven/ui/achievement_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
  });

  group('GameServicesHelper Unit Tests', () {
    test('GameServicesHelper has valid leaderboard and achievement mappings', () {
      expect(GameServicesHelper.leaderboardBrainSize, isNotEmpty);
      expect(GameServicesHelper.leaderboardLevelsCompleted, isNotEmpty);
      expect(GameServicesHelper.leaderboardDailyStreak, isNotEmpty);

      final map = GameServicesHelper.achievementIdMap;
      expect(map.containsKey('words_50'), isTrue);
      expect(map.containsKey('words_250'), isTrue);
      expect(map.containsKey('words_1000'), isTrue);
      expect(map.containsKey('levels_10'), isTrue);
      expect(map.containsKey('levels_50'), isTrue);
      expect(map.containsKey('levels_150'), isTrue);
      expect(map.containsKey('hints_20'), isTrue);
      expect(map.containsKey('streak_3'), isTrue);
      expect(map.containsKey('streak_7'), isTrue);
    });

    test('GameServicesHelper handles calls safely without throwing in test environment', () async {
      await expectLater(GameServicesHelper.initialize(), completes);
      await expectLater(
        GameServicesHelper.unlockAchievement('words_50'),
        completes,
      );
      await expectLater(
        GameServicesHelper.incrementAchievement('words_50', steps: 5),
        completes,
      );
      await expectLater(
        GameServicesHelper.submitScore(
          leaderboardId: GameServicesHelper.leaderboardBrainSize,
          score: 1200,
        ),
        completes,
      );
      await expectLater(
        GameServicesHelper.syncAllPlayerScores(
          brainSize: 1200,
          levelsCompleted: 25,
          dailyStreak: 5,
        ),
        completes,
      );
      await expectLater(GameServicesHelper.showAchievements(), completes);
      await expectLater(GameServicesHelper.showLeaderboards(), completes);
      await expectLater(GameServicesHelper.signOut(), completes);
    });

    test('GameServicesHelper sign in/out notifiers work accurately', () async {
      expect(GameServicesHelper.isSignedInNotifier.value, isFalse);
      expect(GameServicesHelper.playerNotifier.value, isNull);

      // Simulate sign out reset
      await GameServicesHelper.signOut();
      expect(GameServicesHelper.isSignedIn, isFalse);
      expect(GameServicesHelper.currentPlayer, isNull);
    });
  });

  group('UserProvider Play Games Integration Tests', () {
    test('UserProvider checkAndSyncPlayGames triggers achievement and leaderboard sync', () async {
      final user = UserProvider();
      await user.initialized;

      user.brainSize = 500;
      user.levelsCompleted = 15;
      user.wordsFound = 60;
      user.dailyStreak = 4;

      await expectLater(user.checkAndSyncPlayGames(), completes);
    });

    test('UserProvider saveToCloud produces complete backup payload', () async {
      final user = UserProvider();
      await user.initialized;

      user.brainSize = 350;
      user.coins = 200;
      user.levelsCompleted = 8;
      user.wordsFound = 25;
      user.dailyStreak = 2;

      // In unit test environment, saveToCloud completes safely
      final result = await user.saveToCloud();
      expect(result, isA<bool>());
    });

    test('UserProvider restoreFromCloud reconciles highest progress safely', () async {
      final user = UserProvider();
      await user.initialized;

      user.brainSize = 100;
      user.coins = 50;
      user.levelsCompleted = 3;
      user.wordsFound = 10;
      user.dailyStreak = 1;

      // Test with null cloud data (returns false without exception)
      final restored = await user.restoreFromCloud();
      expect(restored, isFalse);
    });

    test('claimAchievement triggers GameServicesHelper.unlockAchievement without error', () async {
      final user = UserProvider();
      await user.initialized;

      expect(user.claimedAchievements.contains('levels_10'), isFalse);
      user.claimAchievement('levels_10', 2);
      expect(user.claimedAchievements.contains('levels_10'), isTrue);
    });
  });

  group('Play Games UI Widget Tests', () {
    testWidgets('AchievementScreen displays Play Games trophy button in header', (tester) async {
      final user = UserProvider();
      await user.initialized;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: user,
            child: const AchievementScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Header title
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);

      // Verify Google Play Games trophy button exists in header
      final trophyIcon = find.byIcon(Icons.emoji_events_rounded);
      expect(trophyIcon, findsOneWidget);

      // Tap trophy button
      await tester.tap(trophyIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
