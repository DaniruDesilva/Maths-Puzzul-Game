import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';

class MathNumberTray extends StatelessWidget {
  final GameProvider provider;

  const MathNumberTray({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final available = provider.availableTray;

    if (available.isEmpty) {
      return Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF26190F),
              Color(0xFF1A1009),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
            width: 1.5,
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
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFBBF24),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'All numbers placed!',
              style: TextStyle(
                color: const Color(0xFFFDE68A),
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

    return Container(
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1B10), // Warm workbench oak
            Color(0xFF191008), // Shadowed cedar
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF5A3C23), // Carved wood border
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Color(0x22F59E0B),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: sortedUniqueNumbers.map((number) {
              final count = counts[number]!;
              final isHintNumber = provider.activeHint != null &&
                  provider.activeHint!.solutionValue == number;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: _buildTile(context, number, count, isHintNumber),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    int number,
    int count,
    bool isHintNumber,
  ) {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isHintNumber
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
                color: isHintNumber
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFA07248),
                width: isHintNumber ? 2.2 : 1.5,
              ),
              boxShadow: [
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
                color: const Color(0xFFFFFBEB), // Warm glowing ivory
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    color: Color(0xAA000000),
                    offset: Offset(0, 1.5),
                    blurRadius: 2,
                  ),
                ],
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFD97706),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
