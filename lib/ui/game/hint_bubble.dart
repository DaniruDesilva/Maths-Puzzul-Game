import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';

class MathHintBubble extends StatelessWidget {
  final GameProvider provider;

  const MathHintBubble({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final hint = provider.activeHint;
    if (hint == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF143022), // Deep emerald woodland
            Color(0xFF0D1F16),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF34D399),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SMART DEDUCTION',
                  style: TextStyle(
                    color: const Color(0xFF6EE7B7),
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => provider.dismissActiveHint(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFA7F3D0),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint.explanation,
            style: TextStyle(
              color: const Color(0xFFF1F5F9),
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => provider.dismissActiveHint(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA7F3D0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'I will solve it',
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => provider.applyActiveHint(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 17),
                label: Text(
                  'Place ${hint.solutionValue}',
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    letterSpacing: 0.8,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
