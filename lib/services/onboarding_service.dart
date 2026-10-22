import 'dart:math';

enum OnboardingStep {
  selectFirstCell,
  placeFirstNumber,
  selectSecondCell,
  placeSecondNumber,
  selectThirdCell,
  placeThirdNumber,
  completed,
}

class OnboardingStepInfo {
  final OnboardingStep step;
  final Point<int>? targetCell;
  final int? targetTrayNumber;
  final String title;
  final String instruction;
  final String? equationFormula;
  final int currentStepIndex;
  final int totalSteps;

  const OnboardingStepInfo({
    required this.step,
    this.targetCell,
    this.targetTrayNumber,
    required this.title,
    required this.instruction,
    this.equationFormula,
    required this.currentStepIndex,
    this.totalSteps = 3,
  });
}

class OnboardingService {
  static const String keyCompletedInteractive = 'has_completed_interactive_onboarding';
  static const String keyNotesTooltip = 'has_seen_notes_tooltip';
  static const String keyHintTooltip = 'has_seen_hint_tooltip';
  static const String keyMistakeTooltip = 'has_seen_mistake_tooltip';

  /// Evaluates current puzzle state during Level 1 and produces the exact step guidance.
  /// Returns null if onboarding is not active for this level or completed.
  static OnboardingStepInfo? evaluateStep({
    required int levelNumber,
    required bool isDailyChallenge,
    required bool isCustomPuzzle,
    required bool hasCompletedInteractiveOnboarding,
    required bool forceReplay,
    required Point<int>? selectedCell,
    required List<List<int?>> currentValues,
    required List<int> availableTray,
  }) {
    // Interactive Onboarding is exclusively crafted for Campaign Level 1
    if (levelNumber != 1 || isDailyChallenge || isCustomPuzzle) {
      return null;
    }

    if (hasCompletedInteractiveOnboarding && !forceReplay) {
      return null;
    }

    // Level 1 blanks:
    // Slot 1: (2, 4) - expected value 28 (14 + 14 = ?)
    // Slot 2: (0, 2) - expected value 19 (? - 14 = 5)
    // Slot 3: (0, 6) - expected value 20 (19 + 1 = ?)
    if (currentValues.length < 5 || currentValues[0].length < 7) {
      return null;
    }

    final valSlot1 = currentValues[2][4]; // 28
    final valSlot2 = currentValues[0][2]; // 19
    final valSlot3 = currentValues[0][6]; // 20

    final bool isSlot1Empty = valSlot1 == null;
    final bool isSlot2Empty = valSlot2 == null;
    final bool isSlot3Empty = valSlot3 == null;

    // All slots filled
    if (!isSlot1Empty && !isSlot2Empty && !isSlot3Empty) {
      return const OnboardingStepInfo(
        step: OnboardingStep.completed,
        targetCell: null,
        targetTrayNumber: null,
        title: 'PUZZLE COMPLETED! 🎉',
        instruction: 'All equations solved! Tap to claim your stars.',
        equationFormula: null,
        currentStepIndex: 3,
        totalSteps: 3,
      );
    }

    // Dynamic resolution based on remaining slots and player's current selection
    if (isSlot1Empty) {
      if (selectedCell != null && selectedCell.x == 2 && selectedCell.y == 4) {
        return const OnboardingStepInfo(
          step: OnboardingStep.placeFirstNumber,
          targetCell: Point(2, 4),
          targetTrayNumber: 28,
          title: 'SOLVE: 14 + 14 = ?',
          instruction: '14 + 14 = 28! Tap the glowing "28" tile in your wood tray below to place it.',
          equationFormula: '14 + 14 = [ 28 ]',
          currentStepIndex: 1,
          totalSteps: 3,
        );
      } else if (selectedCell != null && selectedCell.x == 0 && selectedCell.y == 2 && isSlot2Empty) {
        // Player selected slot 2 first
        return const OnboardingStepInfo(
          step: OnboardingStep.placeSecondNumber,
          targetCell: Point(0, 2),
          targetTrayNumber: 19,
          title: 'SOLVE: [ ? ] - 14 = 5',
          instruction: 'What minus 14 equals 5? 19 - 14 = 5! Tap "19" in your tray below.',
          equationFormula: '[ 19 ] - 14 = 5',
          currentStepIndex: 1,
          totalSteps: 3,
        );
      } else if (selectedCell != null && selectedCell.x == 0 && selectedCell.y == 6 && isSlot3Empty) {
        // Player selected slot 3 first
        return const OnboardingStepInfo(
          step: OnboardingStep.placeThirdNumber,
          targetCell: Point(0, 6),
          targetTrayNumber: 20,
          title: 'SOLVE: 19 + 1 = ?',
          instruction: '19 + 1 = 20! Tap "20" from your wood tray below.',
          equationFormula: '19 + 1 = [ 20 ]',
          currentStepIndex: 1,
          totalSteps: 3,
        );
      } else {
        return const OnboardingStepInfo(
          step: OnboardingStep.selectFirstCell,
          targetCell: Point(2, 4),
          targetTrayNumber: null,
          title: 'WELCOME TO NUMBER HAVEN! 🌿',
          instruction: 'Equations cross each other like a crossword! Tap the pulsing empty slot to select it.',
          equationFormula: '14 + 14 = [ ? ]',
          currentStepIndex: 1,
          totalSteps: 3,
        );
      }
    }

    if (isSlot2Empty) {
      if (selectedCell != null && selectedCell.x == 0 && selectedCell.y == 2) {
        return const OnboardingStepInfo(
          step: OnboardingStep.placeSecondNumber,
          targetCell: Point(0, 2),
          targetTrayNumber: 19,
          title: 'SOLVE: [ ? ] - 14 = 5',
          instruction: 'What minus 14 equals 5? 19 - 14 = 5! Tap the glowing "19" in your tray.',
          equationFormula: '[ 19 ] - 14 = 5',
          currentStepIndex: 2,
          totalSteps: 3,
        );
      } else if (selectedCell != null && selectedCell.x == 0 && selectedCell.y == 6 && isSlot3Empty) {
        return const OnboardingStepInfo(
          step: OnboardingStep.placeThirdNumber,
          targetCell: Point(0, 6),
          targetTrayNumber: 20,
          title: 'SOLVE: 19 + 1 = ?',
          instruction: '19 + 1 = 20! Tap "20" in your tray below.',
          equationFormula: '19 + 1 = [ 20 ]',
          currentStepIndex: 2,
          totalSteps: 3,
        );
      } else {
        return const OnboardingStepInfo(
          step: OnboardingStep.selectSecondCell,
          targetCell: Point(0, 2),
          targetTrayNumber: null,
          title: 'EQUATION SOLVED! ✨',
          instruction: 'The row turned green! Now look at the vertical column. Tap the top empty slot!',
          equationFormula: '[ ? ] - 14 = 5',
          currentStepIndex: 2,
          totalSteps: 3,
        );
      }
    }

    if (isSlot3Empty) {
      if (selectedCell != null && selectedCell.x == 0 && selectedCell.y == 6) {
        return const OnboardingStepInfo(
          step: OnboardingStep.placeThirdNumber,
          targetCell: Point(0, 6),
          targetTrayNumber: 20,
          title: 'THE FINAL PIECE! 🏆',
          instruction: '19 + 1 = 20! Tap "20" in the tray to complete your first crossword puzzle!',
          equationFormula: '19 + 1 = [ 20 ]',
          currentStepIndex: 3,
          totalSteps: 3,
        );
      } else {
        return const OnboardingStepInfo(
          step: OnboardingStep.selectThirdCell,
          targetCell: Point(0, 6),
          targetTrayNumber: null,
          title: 'ALMOST THERE! 🎯',
          instruction: 'Across the top: 19 + 1 = ? Tap the final empty slot to finish Level 1!',
          equationFormula: '19 + 1 = [ ? ]',
          currentStepIndex: 3,
          totalSteps: 3,
        );
      }
    }

    return null;
  }
}
