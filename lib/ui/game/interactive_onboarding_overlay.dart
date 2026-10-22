import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/onboarding_service.dart';

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
    final IconData iconData;
    final Color iconColor;

    switch (info.step) {
      case OnboardingStep.selectFirstCell:
      case OnboardingStep.selectSecondCell:
      case OnboardingStep.selectThirdCell:
        iconData = Icons.touch_app_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      case OnboardingStep.placeFirstNumber:
      case OnboardingStep.placeSecondNumber:
      case OnboardingStep.placeThirdNumber:
        iconData = Icons.arrow_downward_rounded;
        iconColor = const Color(0xFF34D399);
        break;
      case OnboardingStep.completed:
        iconData = Icons.star_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: 1.2),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 14,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(begin: 0.9, end: 1.15, duration: 700.ms);
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
