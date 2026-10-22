import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:number_haven/services/onboarding_service.dart';
import 'package:number_haven/ui/game/interactive_onboarding_overlay.dart';
import 'package:number_haven/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService Logic Tests', () {
    test('Returns null for non-Level-1 puzzles or daily challenges', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      final step = OnboardingService.evaluateStep(
        levelNumber: 2,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20, 28],
      );
      expect(step, isNull);

      final dailyStep = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: true,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20, 28],
      );
      expect(dailyStep, isNull);
    });

    test('Returns null when onboarding completed and forceReplay is false', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      final step = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: true,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20, 28],
      );
      expect(step, isNull);
    });

    test('Activates when forceReplay is true even if completed', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      final step = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: true,
        forceReplay: true,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20, 28],
      );
      expect(step, isNotNull);
      expect(step!.step, OnboardingStep.selectFirstCell);
      expect(step.targetCell, const Point(2, 4));
    });

    test('Level 1 Step 1: selectFirstCell guides player to slot (2, 4)', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      final step = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20, 28],
      );

      expect(step, isNotNull);
      expect(step!.step, OnboardingStep.selectFirstCell);
      expect(step.targetCell, const Point(2, 4));
      expect(step.targetTrayNumber, isNull);
      expect(step.currentStepIndex, 1);
    });

    test('Level 1 Step 2: placeFirstNumber guides player to tap 28 when (2, 4) selected', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      final step = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: const Point(2, 4),
        currentValues: grid,
        availableTray: [19, 20, 28],
      );

      expect(step, isNotNull);
      expect(step!.step, OnboardingStep.placeFirstNumber);
      expect(step.targetCell, const Point(2, 4));
      expect(step.targetTrayNumber, 28);
      expect(step.equationFormula, contains('28'));
    });

    test('Level 1 Step 3 & 4: selectSecondCell & placeSecondNumber for (0, 2) and 19', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      grid[2][4] = 28; // slot 1 solved!

      // Before selecting (0, 2)
      final step3 = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [19, 20],
      );
      expect(step3!.step, OnboardingStep.selectSecondCell);
      expect(step3.targetCell, const Point(0, 2));
      expect(step3.currentStepIndex, 2);

      // Once (0, 2) is selected
      final step4 = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: const Point(0, 2),
        currentValues: grid,
        availableTray: [19, 20],
      );
      expect(step4!.step, OnboardingStep.placeSecondNumber);
      expect(step4.targetTrayNumber, 19);
    });

    test('Level 1 Step 5 & 6: selectThirdCell & placeThirdNumber for (0, 6) and 20', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      grid[2][4] = 28;
      grid[0][2] = 19; // slot 1 & 2 solved!

      final step5 = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [20],
      );
      expect(step5!.step, OnboardingStep.selectThirdCell);
      expect(step5.targetCell, const Point(0, 6));
      expect(step5.currentStepIndex, 3);

      final step6 = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: const Point(0, 6),
        currentValues: grid,
        availableTray: [20],
      );
      expect(step6!.step, OnboardingStep.placeThirdNumber);
      expect(step6.targetTrayNumber, 20);
    });

    test('Level 1 Completed Step when all 3 slots filled', () {
      final grid = List.generate(5, (_) => List<int?>.filled(7, null));
      grid[2][4] = 28;
      grid[0][2] = 19;
      grid[0][6] = 20;

      final stepDone = OnboardingService.evaluateStep(
        levelNumber: 1,
        isDailyChallenge: false,
        isCustomPuzzle: false,
        hasCompletedInteractiveOnboarding: false,
        forceReplay: false,
        selectedCell: null,
        currentValues: grid,
        availableTray: [],
      );
      expect(stepDone!.step, OnboardingStep.completed);
    });
  });

  group('UserProvider Onboarding Flags & Methods', () {
    test('completeInteractiveOnboarding updates flags', () async {
      final user = UserProvider();
      expect(user.hasCompletedInteractiveOnboarding, isFalse);

      user.completeInteractiveOnboarding();
      expect(user.hasCompletedInteractiveOnboarding, isTrue);

      user.resetInteractiveOnboarding();
      expect(user.hasCompletedInteractiveOnboarding, isFalse);
    });

    test('markNotesTooltipSeen, markHintTooltipSeen, markMistakeTooltipSeen work', () {
      final user = UserProvider();
      expect(user.hasSeenNotesTooltip, isFalse);
      user.markNotesTooltipSeen();
      expect(user.hasSeenNotesTooltip, isTrue);

      expect(user.hasSeenHintTooltip, isFalse);
      user.markHintTooltipSeen();
      expect(user.hasSeenHintTooltip, isTrue);

      expect(user.hasSeenMistakeTooltip, isFalse);
      user.markMistakeTooltipSeen();
      expect(user.hasSeenMistakeTooltip, isTrue);
    });
  });

  group('Interactive Onboarding Widgets Test', () {
    testWidgets('InteractiveOnboardingCard renders and fires onSkip', (tester) async {
      bool skipped = false;
      const stepInfo = OnboardingStepInfo(
        step: OnboardingStep.selectFirstCell,
        targetCell: Point(2, 4),
        title: 'WELCOME TO NUMBER HAVEN! 🌿',
        instruction: 'Tap the pulsing empty slot to select it.',
        equationFormula: '14 + 14 = [ ? ]',
        currentStepIndex: 1,
        totalSteps: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveOnboardingCard(
              info: stepInfo,
              onSkip: () => skipped = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WELCOME TO NUMBER HAVEN! 🌿'), findsOneWidget);
      expect(find.text('14 + 14 = [ ? ]'), findsOneWidget);
      expect(find.text('STEP 1/3'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      expect(skipped, isTrue);
    });

    testWidgets('InGameContextualTooltip renders and fires onDismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameContextualTooltip(
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFF34D399),
              title: 'SMART HINT AVAILABLE',
              message: 'Stuck on tricky intersections? Tap the Smart Hint button anytime!',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SMART HINT AVAILABLE'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });
  });
}
