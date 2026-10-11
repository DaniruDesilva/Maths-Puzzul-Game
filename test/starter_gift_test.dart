import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
}
