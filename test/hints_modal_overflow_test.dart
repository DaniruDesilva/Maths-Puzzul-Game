import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/ui/game/game_toolbar.dart';
import 'package:number_haven/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
  });

  group('MathGameToolbar Hints & Power-Ups Modal Zero-Overflow Tests', () {
    final screenSizes = [
      const Size(320, 568), // Ultra-narrow screen (iPhone SE / narrow Android)
      const Size(360, 640), // User's device screen profile
      const Size(412, 892), // Modern flagship Android
    ];

    for (final size in screenSizes) {
      testWidgets(
          'Hints modal renders with zero overflow on ${size.width}x${size.height} when user has 0 hints',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final gameProvider = GameProvider();
        final userProvider = UserProvider();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 60));
        });

        // Ensure user has 0 hints to trigger '25 COINS' / 'STORE' action buttons
        userProvider.hintsRegular = 0;
        userProvider.hintsMega = 0;
        userProvider.hintsUltra = 0;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return MathGameToolbar(provider: gameProvider);
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap the Hint button to trigger modal sheet
        await tester.tap(find.text('Smart Hint'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify the modal title and cards are visible
        expect(find.text('HINTS & POWER-UPS'), findsOneWidget);
        expect(find.text('Smart Hint'), findsAtLeast(1));
        expect(find.text('Mega Hint'), findsOneWidget);
        expect(find.text('Ultra Hint'), findsOneWidget);
        expect(find.text('25 COINS'), findsOneWidget);
        expect(find.text('STORE'), findsNWidgets(2));

        // Check for any RenderFlex overflow exceptions
        final exception = tester.takeException();
        if (exception is FlutterError) {
          fail('RenderFlex overflow detected: $exception');
        }
      });

      testWidgets(
          'Hints modal renders with zero overflow on ${size.width}x${size.height} when user has available hints',
          (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final gameProvider = GameProvider();
        final userProvider = UserProvider();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 60));
        });

        // User has available hints of each type
        userProvider.hintsRegular = 5;
        userProvider.hintsMega = 2;
        userProvider.hintsUltra = 1;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return MathGameToolbar(provider: gameProvider);
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // With special hints, tapping toolbar button opens power-up sheet directly
        await tester.tap(find.text('Boosters'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify sheet content
        expect(find.text('HINTS & POWER-UPS'), findsOneWidget);
        expect(find.text('USE HINT'), findsOneWidget);
        expect(find.text('USE MEGA'), findsOneWidget);
        expect(find.text('USE ULTRA'), findsOneWidget);
        expect(find.text('5 available'), findsOneWidget);
        expect(find.text('2 available'), findsOneWidget);
        expect(find.text('1 available'), findsOneWidget);

        // Check for any RenderFlex overflow exceptions
        final exception = tester.takeException();
        if (exception is FlutterError) {
          fail('RenderFlex overflow detected: $exception');
        }
      });
    }
  });
}
