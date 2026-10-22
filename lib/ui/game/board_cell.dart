import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../engine/math/models.dart';

class BoardCellWidget extends StatelessWidget {
  final MathCell cell;
  final int? currentValue;
  final bool isSelected;
  final bool isHighlightedInHint;
  final bool isInActiveEquation;
  final bool isInViolatedEquation;
  final bool isInSatisfiedEquation;
  final Set<int>? notes;
  final bool isNotesMode;
  final bool isTutorialTarget;
  final VoidCallback? onTap;
  final double size;

  const BoardCellWidget({
    super.key,
    required this.cell,
    required this.currentValue,
    this.isSelected = false,
    this.isHighlightedInHint = false,
    this.isTutorialTarget = false,
    this.isInActiveEquation = false,
    this.isInViolatedEquation = false,
    this.isInSatisfiedEquation = false,
    this.notes,
    this.isNotesMode = false,
    this.onTap,
    this.size = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    if (cell.kind == CellKind.block) {
      return SizedBox(width: size, height: size);
    }

    if (cell.kind == CellKind.op) {
      return _buildOpCell();
    }

    if (cell.kind == CellKind.equals) {
      return _buildEqualsCell();
    }

    // Number cell (Given or Blank Slot)
    return _buildNumberCell(context);
  }

  // --- Operator Cell (+, -, x, /) ---
  Widget _buildOpCell() {
    Color opColor;
    Color glowColor;
    switch (cell.op) {
      case Op.add:
        opColor = const Color(0xFF34D399); // Emerald Mint
        glowColor = const Color(0xFF10B981);
        break;
      case Op.sub:
        opColor = const Color(0xFFFF8A65); // Warm Sunset Coral
        glowColor = const Color(0xFFF4511E);
        break;
      case Op.mul:
        opColor = const Color(0xFFFFD54F); // Golden Amber
        glowColor = const Color(0xFFFFB300);
        break;
      case Op.div:
        opColor = const Color(0xFF4DD0E1); // Bright Cyan
        glowColor = const Color(0xFF00ACC1);
        break;
      default:
        opColor = const Color(0xFFE2E8F0);
        glowColor = Colors.white30;
    }

    final isLit = isInSatisfiedEquation || isInActiveEquation;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLit
              ? [
                  glowColor.withValues(alpha: 0.35),
                  const Color(0xFF1E1712).withValues(alpha: 0.9),
                ]
              : [
                  const Color(0xFF231B15).withValues(alpha: 0.85),
                  const Color(0xFF18120E).withValues(alpha: 0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: isLit
              ? opColor.withValues(alpha: 0.8)
              : opColor.withValues(alpha: 0.3),
          width: isLit ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isLit)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        cell.op?.symbol ?? '',
        style: TextStyle(
          color: isLit ? Colors.white : opColor,
          fontFamily: GoogleFonts.lilitaOne().fontFamily,
          fontSize: size * 0.52,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: isLit ? glowColor : Colors.black87,
              blurRadius: isLit ? 6 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  // --- Equals Cell (=) ---
  Widget _buildEqualsCell() {
    final isLit = isInSatisfiedEquation || isInActiveEquation;
    const eqColor = Color(0xFFE0E7FF);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLit
              ? [
                  const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  const Color(0xFF1E1712).withValues(alpha: 0.9),
                ]
              : [
                  const Color(0xFF231B15).withValues(alpha: 0.85),
                  const Color(0xFF18120E).withValues(alpha: 0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: isLit
              ? const Color(0xFF60A5FA).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.2),
          width: isLit ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isLit)
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        '=',
        style: TextStyle(
          color: isLit ? Colors.white : eqColor,
          fontFamily: GoogleFonts.lilitaOne().fontFamily,
          fontSize: size * 0.50,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.black87,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  // --- Number Cell (Given Clue or Interactive Slot) ---
  Widget _buildNumberCell(BuildContext context) {
    // 1. Given Number (Pre-filled Oak Carved Tile)
    if (cell.isGiven) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A3425), // Rich warm oak
              Color(0xFF332216), // Deep aged cedar
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(
            color: isInSatisfiedEquation
                ? const Color(0xFF10B981)
                : (isInActiveEquation
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF8B6B4C)),
            width: isInSatisfiedEquation || isInActiveEquation ? 2.2 : 1.5,
          ),
          boxShadow: [
            if (isInSatisfiedEquation)
              const BoxShadow(
                color: Color(0x6610B981),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          '${cell.solutionValue ?? ''}',
          style: TextStyle(
            color: const Color(0xFFFFF7ED), // Warm ivory
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            fontSize: size * 0.44,
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
      );
    }

    // 2. Interactive Blank Slot
    final hasValue = currentValue != null;
    Color borderColor;
    double borderWidth = 2.0;
    List<BoxShadow> shadows = [];

    if (isTutorialTarget && !hasValue) {
      // Tutorial target focus: radiant golden amber pulse
      borderColor = const Color(0xFFFBBF24);
      borderWidth = 3.2;
      shadows.add(const BoxShadow(
        color: Color(0xCCF59E0B),
        blurRadius: 16,
        spreadRadius: 3,
      ));
    } else if (isHighlightedInHint) {
      // Smart hint focus target: radiant emerald glow
      borderColor = const Color(0xFF10B981);
      borderWidth = 3.0;
      shadows.add(const BoxShadow(
        color: Color(0x9910B981),
        blurRadius: 12,
        spreadRadius: 2,
      ));
    } else if (isSelected) {
      // Active player selection: warm amber gold glow
      borderColor = const Color(0xFFFFD54F);
      borderWidth = 3.0;
      shadows.add(const BoxShadow(
        color: Color(0x88FFB74D),
        blurRadius: 10,
        spreadRadius: 2,
      ));
    } else if (isInViolatedEquation && hasValue) {
      // Violated equation error: warm coral alert
      borderColor = const Color(0xFFEF4444);
      borderWidth = 2.5;
      shadows.add(const BoxShadow(
        color: Color(0x66EF4444),
        blurRadius: 6,
      ));
    } else if (isInSatisfiedEquation && hasValue) {
      // Satisfied equation success: emerald leaf rim
      borderColor = const Color(0xFF10B981);
      borderWidth = 2.2;
      shadows.add(const BoxShadow(
        color: Color(0x5510B981),
        blurRadius: 6,
      ));
    } else if (isInActiveEquation) {
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.7);
      borderWidth = 1.8;
    } else {
      borderColor = hasValue
          ? const Color(0xFFD97706).withValues(alpha: 0.8)
          : const Color(0xFF4A3728).withValues(alpha: 0.7);
      borderWidth = 1.5;
    }

    // Tile fill gradient
    final Gradient tileGradient;
    if (hasValue) {
      // Placed number: polished golden teak / honey maple tile
      tileGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD97706), // Warm golden maple
          Color(0xFF92400E), // Deep amber wood
        ],
      );
    } else {
      // Empty recessed wooden socket
      tileGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isSelected
            ? [
                const Color(0xFF332014),
                const Color(0xFF24150C),
              ]
            : [
                const Color(0xFF1A120B),
                const Color(0xFF120C07),
              ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: tileGradient,
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            ...shadows,
            BoxShadow(
              color: Colors.black.withValues(alpha: hasValue ? 0.4 : 0.25),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: hasValue
            ? Text(
                '$currentValue',
                style: TextStyle(
                  color: const Color(0xFFFFFBEB), // Bright warm ivory
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: size * 0.46,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 1.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              )
            : _buildNotesGrid(),
      ),
    );
  }

  // --- Candidate Notes Grid ---
  Widget _buildNotesGrid() {
    if (notes == null || notes!.isEmpty) {
      if (isSelected) {
        if (isNotesMode) {
          // Distinct glowing pencil indicator when focused in Notes mode!
          return Center(
            child: Icon(
              Icons.edit_rounded,
              color: const Color(0xFFFFD54F),
              size: size * 0.40,
            ),
          );
        }
        // Subtle dotted target indicator when focused in normal placement mode
        return Center(
          child: Container(
            width: size * 0.22,
            height: size * 0.22,
            decoration: const BoxDecoration(
              color: Color(0x66FFD54F),
              shape: BoxShape.circle,
            ),
          ),
        );
      }
      if (isTutorialTarget && !isSelected) {
        // Distinct golden touch beacon to invite the player's tap
        return Center(
          child: Icon(
            Icons.touch_app_rounded,
            color: const Color(0xFFFBBF24),
            size: size * 0.46,
          ),
        );
      }
      return SizedBox(width: size, height: size);
    }

    final sortedNotes = notes!.toList()..sort();
    return Container(
      padding: EdgeInsets.all(size * 0.06),
      alignment: Alignment.center,
      child: Wrap(
        spacing: 3,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: sortedNotes.take(4).map((n) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF452B14).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                width: 0.8,
              ),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                color: const Color(0xFFFFFBEB),
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
