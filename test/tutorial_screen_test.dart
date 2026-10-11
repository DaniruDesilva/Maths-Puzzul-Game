import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_haven/ui/tutorial_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TutorialScreen renders slides and navigates properly without overflow', (WidgetTester tester) async {
    // Test on a realistic compact phone screen (392 x 872 dp)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: const TutorialScreen(),
        routes: {
          '/home': (context) => const Scaffold(body: Text('Home Screen')),
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 0 header and welcome title
    expect(find.text('WELCOME TO WORD HAVEN!'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 1 / 6'), findsOneWidget);
    expect(find.text('MAYOR BRAMBLE • VILLAGE GUIDE'), findsOneWidget);

    // Tap NEXT to advance to slide 1
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 1 (Hexagonal Word Swiping)
    expect(find.text('HEXAGONAL WORD SWIPING'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 2 / 6'), findsOneWidget);
    expect(find.text('SWIPE IN ALL 6 DIRECTIONS!'), findsOneWidget);

    // Tap NEXT to advance to slide 2
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 2 (Target Word Boxes)
    expect(find.text('TARGET WORD BOXES'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 3 / 6'), findsOneWidget);
    expect(find.text('FERN THE FOX • MASTER BAKER'), findsOneWidget);

    // Tap NEXT to advance to slide 3
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 3 (Helpful Puzzle Tools)
    expect(find.text('HELPFUL PUZZLE TOOLS'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 4 / 6'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text('MEGA HINT'), findsOneWidget);
    expect(find.text('ULTRA HINT'), findsOneWidget);
    expect(find.text('SHUFFLE'), findsOneWidget);

    // Tap NEXT to advance to slide 4
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 4 (Restore Oakheart Village)
    expect(find.text('RESTORE OAKHEART VILLAGE'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 5 / 6'), findsOneWidget);
    expect(find.text('MAYOR BRAMBLE • VILLAGE ECONOMY'), findsOneWidget);

    // Tap NEXT to advance to slide 5
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify slide 5 (Ready for Adventure & Start Journey)
    expect(find.text('READY FOR ADVENTURE!'), findsOneWidget);
    expect(find.text('OAKHEART GUIDE • 6 / 6'), findsOneWidget);
    expect(find.text('START YOUR JOURNEY'), findsOneWidget);

    // Tap START YOUR JOURNEY button
    await tester.tap(find.text('START YOUR JOURNEY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check shared preferences flag is persisted
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_tutorial'), isTrue);
  });

  testWidgets('Skipping tutorial persists has_seen_tutorial flag and navigates to home', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'has_seen_tutorial': false});

    await tester.pumpWidget(
      MaterialApp(
        home: const TutorialScreen(),
        routes: {
          '/home': (context) => const Scaffold(body: Text('Home Screen')),
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap SKIP on slide 0
    await tester.tap(find.text('SKIP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check flag is true
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_tutorial'), isTrue);
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
