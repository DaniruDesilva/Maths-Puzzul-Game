import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:number_haven/providers/user_provider.dart';
import 'package:number_haven/ui/store_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoreScreen Categorization and Coins Tests', () {
    testWidgets('StoreScreen opens directly in Coins category when initialCategory is coins', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      final user = UserProvider();

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

      // Screen title and currency header
      expect(find.text('VILLAGE MERCHANT'), findsOneWidget);
      expect(find.text('COIN VAULT'), findsOneWidget);

      // Verify all coin packages are present
      expect(find.text('Free Daily Coins'), findsOneWidget);
      expect(find.text('Handful of Coins'), findsOneWidget);
      expect(find.text('Pouch of Coins'), findsOneWidget);
      expect(find.text('Chest of Coins'), findsOneWidget);
      expect(find.text('Sack of Treasures'), findsOneWidget);
      expect(find.text('Village Vault'), findsOneWidget);

      // Verify hint section is NOT rendered in coins-only tab
      expect(find.text('HINTS & POWER-SOLVERS'), findsNothing);
    });

    testWidgets('Tapping coin package adds coins to UserProvider balance', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      final user = UserProvider();
      final initialCoins = user.coins;

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

      // Tap buy 250 Coins ($0.99)
      final buyButton = find.text('\$0.99');
      expect(buyButton, findsOneWidget);
      await tester.tap(buyButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Coins balance should be increased by 250
      expect(user.coins, initialCoins + 250);
      expect(find.textContaining('Purchased: 250 Coins'), findsOneWidget);
    });

    testWidgets('Switching category tabs filters items accurately without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 2400)); // Test on compact screen width
      final user = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
          ],
          child: const MaterialApp(
            home: StoreScreen(initialCategory: 'all'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 'ALL' tab shows COIN VAULT at the top
      expect(find.text('COIN VAULT'), findsOneWidget);

      // Tap HINTS tab
      await tester.tap(find.text('HINTS'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COIN VAULT'), findsNothing);
      expect(find.text('HINTS & POWER-SOLVERS'), findsOneWidget);
      expect(find.text('10 Regular Hints'), findsOneWidget);
      expect(find.text('30 Regular Hints'), findsOneWidget);

      // Tap BUNDLES tab
      await tester.tap(find.text('BUNDLES'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('COIN VAULT'), findsNothing);
      expect(find.text('HINTS & POWER-SOLVERS'), findsNothing);
      expect(find.text('SPECIAL BUNDLES & PERKS'), findsOneWidget);
      expect(find.text('Cozy Starter Pack'), findsOneWidget);
      expect(find.text('Master Village Bundle'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
  });
}
