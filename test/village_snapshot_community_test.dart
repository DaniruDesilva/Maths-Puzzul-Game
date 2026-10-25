import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/engine/math/models.dart';
import 'package:number_haven/engine/math/puzzle_codec.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/services/sound_service.dart';
import 'package:number_haven/ui/village/overlays/village_snapshot_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
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
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
  });

  group('Village Prosperity & Architect Title Logic Tests', () {
    test('Default village has 0 stages, 0% completion, and Village Pioneer title', () {
      final user = UserProvider();
      expect(user.villageTotalBuildingStages, 0);
      expect(user.villageCompletionPercent, 0);
      expect(user.villageArchitectTitle, 'Village Pioneer 🌿');
    });

    test('Progression through stages unlocks titles and updates prosperity score', () {
      final user = UserProvider();

      // Upgrade cottage to stage 3
      user.upgradeBuilding('cottage');
      user.upgradeBuilding('cottage');
      user.upgradeBuilding('cottage');
      expect(user.villageTotalBuildingStages, 3);
      expect(user.villageCompletionPercent, 20); // 3/15 = 20%
      expect(user.villageArchitectTitle, 'Cozy Builder 🏡');

      // Upgrade bakery to stage 3
      user.upgradeBuilding('bakery');
      user.upgradeBuilding('bakery');
      user.upgradeBuilding('bakery');
      expect(user.villageTotalBuildingStages, 6);
      expect(user.villageCompletionPercent, 40); // 6/15 = 40%
      expect(user.villageArchitectTitle, 'Hamlet Craftsman 🔨');

      // Upgrade windmill to stage 3
      user.upgradeBuilding('windmill');
      user.upgradeBuilding('windmill');
      user.upgradeBuilding('windmill');
      expect(user.villageTotalBuildingStages, 9);
      expect(user.villageCompletionPercent, 60); // 9/15 = 60%
      expect(user.villageArchitectTitle, 'Grand Visionary 🏰');

      // Upgrade library to stage 3
      user.upgradeBuilding('library');
      user.upgradeBuilding('library');
      user.upgradeBuilding('library');
      expect(user.villageTotalBuildingStages, 12);
      expect(user.villageCompletionPercent, 80); // 12/15 = 80%
      expect(user.villageArchitectTitle, 'Master Architect 🏛️');

      // Upgrade tower to stage 3 (all 15 stages maxed!)
      user.upgradeBuilding('tower');
      user.upgradeBuilding('tower');
      user.upgradeBuilding('tower');
      expect(user.villageTotalBuildingStages, 15);
      expect(user.villageCompletionPercent, 100);
      expect(user.villageArchitectTitle, 'Legendary Mayor 👑');
      expect(user.villageProsperityScore, greaterThanOrEqualTo(1800));
    });

    test('MathPuzzleCodec encodes and decodes community friend challenges cleanly', () {
      final code = MathPuzzleCodec.encodeSeed(
        difficulty: Difficulty.hard,
        seed: 42195,
        id: 15,
      );
      expect(code, 'NH1-H-15-42195');

      final parsed = MathPuzzleCodec.decodeSeed(code);
      expect(parsed, isNotNull);
      expect(parsed!.difficulty, Difficulty.hard);
      expect(parsed.seed, 42195);
      expect(parsed.id, 15);
    });
  });

  group('VillageSnapshotDialog Widget & Community Showcase Tests', () {
    Widget buildTestDialog({
      required UserProvider user,
      required GameProvider game,
      Size size = const Size(360, 640),
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: user),
          ChangeNotifierProvider<GameProvider>.value(value: game),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: VillageSnapshotDialog(user: user),
            ),
          ),
        ),
      );
    }

    testWidgets('VillageSnapshotDialog renders Postcard tab without overflow on 360px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      final user = UserProvider();
      await user.initialized;
      user.upgradeBuilding('cottage');
      user.upgradeBuilding('bakery');
      final game = GameProvider();

      await tester.pumpWidget(buildTestDialog(user: user, game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('VILLAGE SHOWCASE 📸'), findsOneWidget);
      expect(find.text('NUMBER HAVEN POSTCARD'), findsOneWidget);
      expect(find.text('AIR MAIL'), findsOneWidget);
      expect(find.text('SHARE POSTCARD 📸'), findsOneWidget);
    });

    testWidgets('VillageSnapshotDialog renders cleanly on narrow 320px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      final user = UserProvider();
      await user.initialized;
      final game = GameProvider();

      await tester.pumpWidget(buildTestDialog(user: user, game: game, size: const Size(320, 568)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(VillageSnapshotDialog), findsOneWidget);
    });

    testWidgets('Switching tabs to CHALLENGES and MILESTONES works and displays content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));
      final user = UserProvider();
      await user.initialized;
      user.upgradeBuilding('cottage');
      final game = GameProvider();

      await tester.pumpWidget(buildTestDialog(user: user, game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Switch to CHALLENGES tab
      await tester.tap(find.text('CHALLENGES'));
      await tester.pumpAndSettle();

      expect(find.text('CREATE FRIEND CHALLENGE'), findsOneWidget);
      expect(find.text('PLAY A FRIEND\'S CODE'), findsOneWidget);
      expect(find.text('SEND TO FRIENDS 🚀'), findsOneWidget);

      // 2. Switch to MILESTONES tab
      await tester.tap(find.text('MILESTONES'));
      await tester.pumpAndSettle();

      expect(find.text('Founding Settler'), findsOneWidget);
      expect(find.text('Master Baker'), findsOneWidget);
      expect(find.text('Breeze Keeper'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsAtLeastNWidgets(1)); // Cottage was built
    });

    testWidgets('High Contrast Mode and Dark Mode adapt correctly without crash', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      final user = UserProvider();
      await user.initialized;
      user.toggleDarkMode();
      user.toggleHighContrast();
      final game = GameProvider();

      await tester.pumpWidget(buildTestDialog(user: user, game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('VILLAGE SHOWCASE 📸'), findsOneWidget);
    });
  });
}
