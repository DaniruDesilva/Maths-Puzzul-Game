import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/ui/game_screen.dart';
import 'package:number_haven/ui/store_screen.dart';
import 'package:number_haven/ui/village/overlays/fortune_wheel_dialog.dart';
import 'package:number_haven/ui/village/overlays/acorn_vault_dialog.dart';
import 'package:flutter/services.dart';
import 'package:number_haven/services/sound_service.dart';
import 'package:number_haven/data/math_level_repository.dart';

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
    SharedPreferences.setMockInitialValues({
      'setting_sound': false,
      'setting_music': false,
    });
    SoundService.setSoundEnabled(false);
    SoundService.setMusicEnabled(false);
  });

  group('Monetization: UserProvider Logic Tests', () {
    test('Acorn Vault accumulates 5 coins per equation solved up to 1500 max', () async {
      final user = UserProvider();
      await user.initialized;
      expect(user.acornVaultCoins, 0);
      expect(user.canCrackAcornVault, false);
      expect(user.isAcornVaultFull, false);

      // Solve 4 equations -> 4 * 5 = 20 coins
      user.addEquationSolved(4);
      expect(user.acornVaultCoins, 20);

      // Solve 100 equations -> 500 more -> total 520
      user.addEquationSolved(100);
      expect(user.acornVaultCoins, 520);
      expect(user.canCrackAcornVault, true);
      expect(user.isAcornVaultFull, false);

      // Solve 300 equations -> capped at 1500
      user.addEquationSolved(300);
      expect(user.acornVaultCoins, 1500);
      expect(user.isAcornVaultFull, true);
    });

    test('Cracking Acorn Vault transfers all saved coins to user wallet and resets vault', () async {
      final user = UserProvider();
      await user.initialized;
      user.coins = 200;
      user.acornVaultCoins = 850;

      final cracked = user.crackAcornVault();
      expect(cracked, 850);
      expect(user.coins, 1050);
      expect(user.acornVaultCoins, 0);
      expect(user.canCrackAcornVault, false);
    });

    test('Welcome Acorn Pack grants 1000 coins + 10 hints + 2 mega + 1 ultra hints strictly once', () async {
      final user = UserProvider();
      await user.initialized;
      user.coins = 50;
      user.hintsRegular = 3;
      user.hintsMega = 0;
      user.hintsUltra = 0;
      expect(user.hasPurchasedWelcomePack, false);

      await user.purchaseWelcomePack();
      expect(user.hasPurchasedWelcomePack, true);
      expect(user.coins, 1050);
      expect(user.hintsRegular, 13);
      expect(user.hintsMega, 2);
      expect(user.hintsUltra, 1);

      // Purchasing again should do nothing
      await user.purchaseWelcomePack();
      expect(user.coins, 1050);
      expect(user.hintsRegular, 13);
    });

    test('Daily Fortune Spin tracking and extra spin consumption', () async {
      final user = UserProvider();
      await user.initialized;
      expect(user.canClaimFreeSpin, true);

      user.recordFreeSpin();
      expect(user.canClaimFreeSpin, false);

      expect(user.extraSpinsAvailable, 0);
      expect(user.useExtraSpin(), false);

      user.addExtraSpin(2);
      expect(user.extraSpinsAvailable, 2);
      expect(user.useExtraSpin(), true);
      expect(user.extraSpinsAvailable, 1);

      // Ad spin limit tracking
      expect(user.remainingAdSpinsToday, UserProvider.maxDailyAdSpins);
      expect(user.canClaimAdSpin, true);

      user.recordAdSpin();
      expect(user.remainingAdSpinsToday, UserProvider.maxDailyAdSpins - 1);

      user.recordAdSpin();
      user.recordAdSpin();
      expect(user.remainingAdSpinsToday, 0);
      expect(user.canClaimAdSpin, false);
    });
  });

  group('Monetization: FortuneWheelDialog Widget Tests', () {
    testWidgets('FortuneWheelDialog displays free spin button when daily spin is available', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      expect(user.canClaimFreeSpin, true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneWheelDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VILLAGE FORTUNE WHEEL'), findsOneWidget);
      expect(find.text('FREE DAILY SPIN'), findsOneWidget);
    });

    testWidgets('FortuneWheelDialog displays watch ad button with remaining quota when free spin claimed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      user.recordFreeSpin();
      expect(user.canClaimFreeSpin, false);
      expect(user.canClaimAdSpin, true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneWheelDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SPIN AGAIN (WATCH AD)'), findsOneWidget);
      expect(find.textContaining('3 of 3 ad spins left today'), findsOneWidget);
    });

    testWidgets('FortuneWheelDialog disables button when daily ad spins limit is reached', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      user.recordFreeSpin();
      user.recordAdSpin();
      user.recordAdSpin();
      user.recordAdSpin(); // All 3 used up
      expect(user.canClaimAdSpin, false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneWheelDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DAILY SPINS COMPLETED'), findsOneWidget);
      expect(find.textContaining('Daily limit reached'), findsOneWidget);
    });

    testWidgets('FortuneWheelDialog free spin starts spinning and completes gracefully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      expect(user.canClaimFreeSpin, true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FortuneWheelDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Free Daily Spin
      await tester.tap(find.text('FREE DAILY SPIN'));
      await tester.pump();
      // Animate 3.6 seconds to completion
      await tester.pump(const Duration(milliseconds: 3700));
      await tester.pump(const Duration(milliseconds: 500));

      expect(user.canClaimFreeSpin, false);
      // Either a prize or try again was awarded
      expect(find.byType(FortuneWheelDialog), findsOneWidget);
    });
  });

  group('Monetization: AcornVaultDialog Widget Tests', () {
    testWidgets('AcornVaultDialog shows unlock threshold when coins < 500', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      user.acornVaultCoins = 200;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcornVaultDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ACORN PIGGY BANK'), findsOneWidget);
      expect(find.text('200 / 1500 COINS'), findsOneWidget);
      expect(find.text('UNLOCKS AT 500 COINS (300 LEFT)'), findsOneWidget);
    });

    testWidgets('AcornVaultDialog shows CRACK VAULT button and cracks vault when tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      final user = UserProvider();
      await user.initialized;
      user.coins = 100;
      user.acornVaultCoins = 750;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcornVaultDialog(user: user),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CRACK VAULT (\$1.49)'), findsOneWidget);

      await tester.tap(find.text('CRACK VAULT (\$1.49)'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(user.coins, 850);
      expect(user.acornVaultCoins, 0);
      expect(find.text('+750 COINS COLLECTED!'), findsOneWidget);
      expect(find.text('CONTINUE PLAYING'), findsOneWidget);
    });
  });

  group('Monetization: StoreScreen Features Tests', () {
    testWidgets('StoreScreen displays Welcome Acorn Pack in Bundles and Acorn Vault Card in Coins', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      final user = UserProvider();
      await user.initialized;
      user.acornVaultCoins = 600;

      // 1. In Bundles category:
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
          ],
          child: const MaterialApp(
            home: StoreScreen(initialCategory: 'bundles'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome Acorn Pack'), findsOneWidget);
      expect(find.text('90% OFF ⚡'), findsOneWidget);

      // 2. In Coins category:
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
          ],
          child: const MaterialApp(
            home: StoreScreen(initialCategory: 'coins'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Acorn Piggy Bank'), findsOneWidget);
      expect(find.text('600 / 1500 Bonus Coins Saved'), findsOneWidget);
      expect(find.text('CRACK\n\$1.49'), findsOneWidget);
    });
  });

  group('Monetization: Victory 2x Coin Multiplier Widget Tests', () {
    testWidgets('GameScreen level complete displays 2x Coin Multiplier and doubles coins on tap', (tester) async {
      tester.view.physicalSize = const Size(840, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final user = UserProvider();
      await user.initialized;
      user.coins = 50;

      final game = GameProvider(initialPuzzle: MathLevelRepository.getCampaignLevelSync(1));
      // Simulate completing level with 80 coins
      game.lastRewards = {
        'baseCoins': 50,
        'starCoins': 30,
        'libraryCoins': 0,
        'totalCoins': 80,
        'brainEarned': 150,
        'scoreEarned': 600,
        'newStars': 3,
        'isNewLevel': 1,
      };
      game.levelProgressSaved = true;
      game.isLevelComplete = true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
            ChangeNotifierProvider<GameProvider>.value(value: game),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify 2x Coin Multiplier button is present
      expect(find.text('DOUBLE COINS (+80)'), findsOneWidget);
      expect(find.text('WATCH AD FOR BONUS'), findsOneWidget);
      expect(find.text('2X'), findsOneWidget);

      // Tap 2x Coin Multiplier button
      await tester.tap(find.text('DOUBLE COINS (+80)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In debug mode fallback, AdService grants onReward directly
      expect(user.coins, 130); // 50 initial + 80 doubled
      expect(find.text('COINS DOUBLED! (+80)'), findsOneWidget);

      // Advance clock past all delayed animation timers so widget disposal has zero pending timers
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
