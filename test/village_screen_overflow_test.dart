import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/data/village_data.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/providers/game_provider.dart';
import 'package:number_haven/services/sound_service.dart';
import 'package:number_haven/ui/village_screen.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.setSoundEnabled(false);
  });

  group('VillageScreen Top Bar Layout & Overflow Prevention Tests', () {
    testWidgets('VillageScreen top bar renders without overflow on 360px screen with large currency', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      final user = UserProvider();
      await user.initialized;
      user.claimStarterGift();
      user.addCoins(99999);
      user.addHint(99);

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
      await tester.pump(const Duration(milliseconds: 1000));

      // Ensure no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.byType(VillageScreen), findsOneWidget);
    });

    testWidgets('VillageScreen top bar renders without overflow on narrow 320px screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      final user = UserProvider();
      await user.initialized;
      user.claimStarterGift();
      user.addCoins(500);

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
      await tester.pump(const Duration(milliseconds: 1000));

      expect(tester.takeException(), isNull);
    });
  });
}
