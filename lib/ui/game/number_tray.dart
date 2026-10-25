import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import 'interactive_onboarding_overlay.dart';

class MathNumberTray extends StatelessWidget {
  final GameProvider provider;
  final int? tutorialTargetNumber;

  const MathNumberTray({
    super.key,
    required this.provider,
    this.tutorialTargetNumber,
  });

  @override
  Widget build(BuildContext context) {
    final available = provider.availableTray;
    final user = Provider.of<UserProvider>(context);
    final isHighContrast = user.highContrastEnabled;

    if (available.isEmpty) {
      return Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : null,
          gradient: isHighContrast
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF26190F),
                    Color(0xFF1A1009),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighContrast ? Colors.white : const Color(0xFF10B981).withValues(alpha: 0.5),
            width: isHighContrast ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: isHighContrast ? const Color(0xFFFFEA00) : const Color(0xFFFBBF24),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'All numbers placed!',
              style: TextStyle(
                color: isHighContrast ? Colors.white : const Color(0xFFFDE68A),
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Group available candidate numbers by count
    final counts = <int, int>{};
    for (final num in available) {
      counts[num] = (counts[num] ?? 0) + 1;
    }
    final sortedUniqueNumbers = counts.keys.toList()..sort();

    final isNotes = provider.isNotesMode;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: isNotes ? 6 : 8,
        top: tutorialTargetNumber != null ? 24 : (isNotes ? 6 : 8),
      ),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : null,
        gradient: isHighContrast
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isNotes
                    ? const [
                        Color(0xFF332012), // Warm amber wood tone
                        Color(0xFF1E1208),
                      ]
                    : const [
                        Color(0xFF2A1B10), // Warm workbench oak
                        Color(0xFF191008), // Shadowed cedar
                      ],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighContrast
              ? (isNotes ? const Color(0xFFFFEA00) : Colors.white)
              : (isNotes ? const Color(0xFFF59E0B) : const Color(0xFF5A3C23)),
          width: isHighContrast ? 2.6 : (isNotes ? 2.0 : 1.8),
        ),
        boxShadow: [
          if (isNotes && !isHighContrast)
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: isHighContrast ? const Color(0xFFFFEA00) : const Color(0xFFFFD54F),
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'PENCIL NOTES ACTIVE • Tap numbers to jot candidates',
                    style: TextStyle(
                      color: isHighContrast ? const Color(0xFFFFEA00) : const Color(0xFFFFD54F),
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: sortedUniqueNumbers.map((number) {
                  final count = counts[number]!;
                  final isHintNumber = provider.activeHint != null &&
                      provider.activeHint!.solutionValue == number;
                  final isTutorialNumber = tutorialTargetNumber == number;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: _buildTile(
                      context,
                      number,
                      count,
                      isHintNumber,
                      isTutorialNumber,
                      isNotes,
                      isHighContrast: isHighContrast,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildTile(
    BuildContext context,
    int number,
    int count,
    bool isHintNumber,
    bool isTutorialNumber,
    bool isNotes, {
    bool isHighContrast = false,
  }) {
    return GestureDetector(
      onTap: () => provider.placeNumber(number),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isHighContrast
                  ? (isTutorialNumber
                      ? const Color(0xFFFFEA00)
                      : (isHintNumber
                          ? const Color(0xFF00FF66)
                          : (isNotes ? const Color(0xFF1E1E1E) : Colors.white)))
                  : null,
              gradient: isHighContrast
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isTutorialNumber
                          ? [
                              const Color(0xFFF59E0B),
                              const Color(0xFFB45309),
                            ]
                          : isHintNumber
                              ? [
                                  const Color(0xFF10B981),
                                  const Color(0xFF047857),
                                ]
                              : [
                                  const Color(0xFF785130), // Beveled top highlight
                                  const Color(0xFF4E321C), // Deep wooden core
                                ],
                    ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isHighContrast
                    ? (isTutorialNumber
                        ? Colors.black
                        : (isHintNumber
                            ? Colors.black
                            : (isNotes ? const Color(0xFFFFEA00) : Colors.black)))
                    : (isTutorialNumber
                        ? const Color(0xFFFDE68A)
                        : isHintNumber
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFA07248)),
                width: isHighContrast ? 2.8 : (isTutorialNumber ? 2.6 : (isHintNumber ? 2.2 : 1.5)),
              ),
              boxShadow: [
                if (isTutorialNumber)
                  const BoxShadow(
                    color: Color(0xCCF59E0B),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                if (isHintNumber)
                  const BoxShadow(
                    color: Color(0x8810B981),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 3.5),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: isHighContrast
                    ? (isNotes ? const Color(0xFFFFEA00) : Colors.black)
                    : const Color(0xFFFFFBEB), // Warm glowing ivory
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                shadows: isHighContrast
                    ? null
                    : const [
                        Shadow(
                          color: Color(0xAA000000),
                          offset: Offset(0, 1.5),
                          blurRadius: 2,
                        ),
                      ],
              ),
            ),
          ),

          // Animated cartoon hand gesture pointing down at target candidate tile
          if (isTutorialNumber)
            const Positioned(
              left: 0,
              right: 0,
              top: -42,
              child: Center(
                child: AnimatedHandGesture(
                  direction: HandGestureDirection.down,
                  size: 36,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ),

          // Multiple candidate count wax seal badge (e.g. x2)
          if (count > 1)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.black : null,
                  gradient: isHighContrast
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFD97706),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHighContrast ? const Color(0xFFFFEA00) : Colors.white,
                    width: isHighContrast ? 1.6 : 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(0, 1.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '×$count',
                  style: TextStyle(
                    color: isHighContrast ? const Color(0xFFFFEA00) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),

          // Notes mode pencil indicator badge on candidate tiles
          if (isNotes)
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.black : null,
                  gradient: isHighContrast
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFD97706),
                          ],
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHighContrast ? const Color(0xFFFFEA00) : const Color(0xFFFFFBEB),
                    width: isHighContrast ? 1.6 : 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: isHighContrast ? const Color(0xFFFFEA00) : Colors.white,
                  size: 9.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
