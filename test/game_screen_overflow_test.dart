import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/ui/game/board_view.dart';
import 'package:number_haven/ui/game_screen.dart';
import 'package:number_haven/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SoundService.setSoundEnabled(false);
  });

  group('MathBoardView & GameScreen Zero-Overflow Responsive Tests', () {
    final testScreenSizes = [
      const Size(320, 568), // iPhone SE / small Android
      const Size(360, 640), // Standard budget Android (user device profile)
      const Size(392, 780), // Modern Android phone
      const Size(412, 915), // Large Android flagship
      const Size(600, 960), // Small tablet
    ];

    for (final size in testScreenSizes) {
      testWidgets('Level 1 renders on ${size.width}x${size.height} without any RenderFlex overflow', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final gameProvider = GameProvider();
        final userProvider = UserProvider();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 60));
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const MaterialApp(
              home: GameScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Ensure zero layout exceptions / overflows occurred
        expect(tester.takeException(), isNull);

        // Verify board view is present and laid out
        expect(find.byType(MathBoardView), findsOneWidget);
      });
    }

    testWidgets('Large 13x13 grid board renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final gameProvider = GameProvider();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 60));
      });

      // Jump to Level 204 (13x13 expert puzzle)
      gameProvider.startSpecificLevel(204);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 60));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
            ChangeNotifierProvider<UserProvider>.value(value: UserProvider()),
          ],
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Absolutely zero overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(MathBoardView), findsOneWidget);
    });
  });
}
