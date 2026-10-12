import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/ui/village/overlays/starter_gift_dialog.dart';

import 'package:flutter/services.dart';
import 'package:number_haven/services/sound_service.dart';

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

  test('UserProvider starter gift is awarded once and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final user = UserProvider();
    await user.initialized;

    // Verify initial fresh user state: 0 coins, unearned starter bonus
    expect(user.hasClaimedStarterGift, isFalse);
    expect(user.coins, 0);

    // Claim the 100 starter gift coins
    await user.claimStarterGift();
    expect(user.hasClaimedStarterGift, isTrue);
    expect(user.coins, 100);

    // Verify it cannot be claimed again (strictly one-time reward)
    await user.claimStarterGift();
    expect(user.coins, 100);

    // Verify persistence in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('starter_coins_awarded'), isTrue);
    expect(prefs.getInt('coins'), 100);
  });

  test('UserProvider respects existing starter_coins_awarded flag', () async {
    // User already claimed starter gift in a previous session
    SharedPreferences.setMockInitialValues({
      'coins': 120,
      'starter_coins_awarded': true,
    });

    final user = UserProvider();
    await user.initialized;

    expect(user.hasClaimedStarterGift, isTrue);
    expect(user.coins, 120);

    // Calling claim does not award coins again
    await user.claimStarterGift();
    expect(user.coins, 120);
  });

  testWidgets('StarterGiftDialog renders cottage stage and claim button without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final user = UserProvider();
    await user.initialized;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarterGiftDialog(user: user),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('WELCOME STARTER GIFT'), findsOneWidget);
    expect(find.text('WELCOME TO OAKHEART!'), findsOneWidget);
    expect(find.text('+100 GOLDEN COINS'), findsOneWidget);
    expect(find.text('Meadow Cottage'), findsOneWidget);
    expect(find.text('LEVEL 1 • STAGE 1'), findsOneWidget);
    expect(find.text('CLAIM YOUR 100 COINS'), findsOneWidget);
  });
}
