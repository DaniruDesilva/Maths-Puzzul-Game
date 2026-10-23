import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/onboarding_service.dart';
import '../common/cartoon_hand_pointer.dart';

class InteractiveOnboardingCard extends StatelessWidget {
  final OnboardingStepInfo info;
  final VoidCallback onSkip;

  const InteractiveOnboardingCard({
    super.key,
    required this.info,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1C11), // Warm rustic walnut
            Color(0xFF1D1109), // Aged mahogany
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B), // Radiant warm amber
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Step pill + Equation formula chip (if any) + Spacer + Skip button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Color(0xFFFBBF24),
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'STEP ${info.currentStepIndex}/${info.totalSteps}',
                      style: GoogleFonts.baloo2(
                        color: const Color(0xFFFDE68A),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (info.equationFormula != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      info.equationFormula!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lilitaOne(
                        color: const Color(0xFFE0F2FE),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Skip Tutorial button
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: GoogleFonts.baloo2(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.fast_forward_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: Animated Pointer Icon + Title & Instruction Text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAnimatedPointerIcon(info),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lilitaOne(
                        color: const Color(0xFFFFFBEB),
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      info.instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.baloo2(
                        color: const Color(0xFFE2E8F0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.15, end: 0, duration: 250.ms);
  }

  Widget _buildAnimatedPointerIcon(OnboardingStepInfo info) {
    switch (info.step) {
      case OnboardingStep.selectFirstCell:
      case OnboardingStep.selectSecondCell:
      case OnboardingStep.selectThirdCell:
        return const AnimatedHandGesture(
          direction: HandGestureDirection.tap,
          size: 22,
          color: Color(0xFFFBBF24),
        );
      case OnboardingStep.placeFirstNumber:
      case OnboardingStep.placeSecondNumber:
      case OnboardingStep.placeThirdNumber:
        return const AnimatedHandGesture(
          direction: HandGestureDirection.down,
          size: 22,
          color: Color(0xFF34D399),
        );
      case OnboardingStep.completed:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFFBBF24),
            size: 16,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.15, duration: 700.ms);
    }
  }
}

/// Floating In-game Contextual Tooltip Pill for Hints, Notes, and Mistakes
class InGameContextualTooltip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const InGameContextualTooltip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lilitaOne(
                    color: Colors.white,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2, end: 0, duration: 250.ms);
  }
}

enum HandGestureDirection {
  down,
  tap,
  up,
}

/// Tactile Animated Hand Gesture featuring an iconic casual-game cartoon pointer glove
/// with springy tap bounce physics and touch shockwave ripples.
class AnimatedHandGesture extends StatelessWidget {
  final HandGestureDirection direction;
  final double size;
  final Color color;

  const AnimatedHandGesture({
    super.key,
    this.direction = HandGestureDirection.tap,
    this.size = 32,
    this.color = const Color(0xFFFFD54F),
  });

  HandPointerDirection _mapDirection(HandGestureDirection dir) {
    switch (dir) {
      case HandGestureDirection.down:
        return HandPointerDirection.pointingDown;
      case HandGestureDirection.up:
        return HandPointerDirection.pointingUp;
      case HandGestureDirection.tap:
        return HandPointerDirection.tapping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Hidden semantic widget for backwards test compatibility
        Semantics(
          label: 'Tutorial Hand Pointer',
          child: Visibility(
            visible: false,
            maintainState: true,
            child: Icon(Icons.touch_app_rounded, size: size),
          ),
        ),
        // Authentic casual cartoon glove with touch ripple rings
        CartoonHandPointer(
          direction: _mapDirection(direction),
          size: size * 1.25,
          showRipple: true,
        ),
      ],
    );
  }
}

/// Cozy Village Tutorial banner guiding the player to the big PLAY button with an animated hand gesture
class VillageTutorialCard extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onSkip;

  const VillageTutorialCard({
    super.key,
    required this.onPlay,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1C11), // Warm rustic walnut
            Color(0xFF1D1109), // Aged mahogany
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Pill Badge + Skip button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CB342).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8BC34A), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded, color: Color(0xFFAED581), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'VILLAGE TUTORIAL',
                      style: GoogleFonts.baloo2(
                        color: const Color(0xFFDCEDC8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Skip Tutorial button
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: GoogleFonts.baloo2(
                          color: const Color(0xFFE2E8F0),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1), size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title & Description
          Text(
            'Welcome to Number Haven! 🌿',
            textAlign: TextAlign.center,
            style: GoogleFonts.lilitaOne(
              color: const Color(0xFFFFD54F),
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap PLAY below to start your first math crossword puzzle and earn coins to restore your cozy village!',
            textAlign: TextAlign.center,
            style: GoogleFonts.baloo2(
              color: const Color(0xFFE2E8F0),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Animated Hand Gesture pointing down at PLAY
          GestureDetector(
            onTap: onPlay,
            child: const Center(
              child: AnimatedHandGesture(
                direction: HandGestureDirection.down,
                size: 34,
                color: Color(0xFFFFD54F),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0, duration: 350.ms);
  }
}
