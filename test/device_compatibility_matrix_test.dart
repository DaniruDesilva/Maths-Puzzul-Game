import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:number_haven/data/village_data.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/services/sound_service.dart';
import 'package:number_haven/ui/game_screen.dart';
import 'package:number_haven/ui/village_screen.dart';
import 'package:number_haven/ui/store_screen.dart';
import 'package:number_haven/ui/tutorial_screen.dart';
import 'package:number_haven/ui/village/overlays/fortune_wheel_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:number_haven/data/math_level_repository.dart';
import 'package:number_haven/ui/village/overlays/acorn_vault_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
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

    try {
      await MathLevelRepository.preloadCampaign();
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
    SoundService.setMusicEnabled(false);
  });

  // Device Form Factors Matrix
  final deviceFormFactors = <String, Size>{
    'Small Budget Android Phone (320x568)': const Size(320, 568),
    'Standard Android Phone (360x780)': const Size(360, 780),
    'Modern Flagship Phone (390x844)': const Size(390, 844),
    'Large Screen Phone (412x915)': const Size(412, 915),
    'Foldable / 7-inch Tablet (600x960)': const Size(600, 960),
    '10-inch Android Tablet (800x1280)': const Size(800, 1280),
    'Large 12.9-inch Tablet (1024x1366)': const Size(1024, 1366),
  };

  group('Device Matrix Compatibility & Zero-Overflow Tests', () {
    for (final entry in deviceFormFactors.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      testWidgets('GameScreen renders without overflow on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        final game = GameProvider();
        final user = UserProvider();
        await user.initialized;

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
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('VillageScreen renders perfectly on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        final user = UserProvider();
        await user.initialized;
        user.claimStarterGift();
        user.addCoins(12500);
        user.addHint(15);
        final game = GameProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(value: user),
              ChangeNotifierProvider<GameProvider>.value(value: game),
            ],
            child: MaterialApp(
              home: VillageScreen(
                village: VillageData.meadow,
                isRoot: true,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('StoreScreen renders without overflow on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        final user = UserProvider();
        await user.initialized;

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>.value(
            value: user,
            child: const MaterialApp(
              home: StoreScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('TutorialScreen renders without overflow on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          const MaterialApp(
            home: TutorialScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('FortuneWheelDialog renders without overflow on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        final user = UserProvider();
        await user.initialized;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FortuneWheelDialog(user: user),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('AcornVaultDialog renders without overflow on $deviceName', (tester) async {
        await tester.binding.setSurfaceSize(size);
        final user = UserProvider();
        await user.initialized;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AcornVaultDialog(user: user),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
