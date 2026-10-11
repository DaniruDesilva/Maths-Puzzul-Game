import 'package:flutter/material.dart';
import '../../engine/math/models.dart';

class BoardCellWidget extends StatelessWidget {
  final MathCell cell;
  final int? currentValue;
  final bool isSelected;
  final bool isHighlightedInHint;
  final bool isInViolatedEquation;
  final bool isInSatisfiedEquation;
  final Set<int>? notes;
  final VoidCallback? onTap;
  final double size;

  const BoardCellWidget({
    super.key,
    required this.cell,
    required this.currentValue,
    this.isSelected = false,
    this.isHighlightedInHint = false,
    this.isInViolatedEquation = false,
    this.isInSatisfiedEquation = false,
    this.notes,
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

    // Number cell (Given or Blank)
    return _buildNumberCell(context);
  }

  Widget _buildOpCell() {
    Color opColor;
    switch (cell.op) {
      case Op.add:
        opColor = const Color(0xFF4ECDC4);
        break;
      case Op.sub:
        opColor = const Color(0xFFFF8E72);
        break;
      case Op.mul:
        opColor = const Color(0xFFFFD166);
        break;
      case Op.div:
        opColor = const Color(0xFF38EF7D);
        break;
      default:
        opColor = Colors.white70;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: opColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        cell.op?.symbol ?? '',
        style: TextStyle(
          color: opColor,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEqualsCell() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        '=',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: size * 0.48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNumberCell(BuildContext context) {
    // 1. Given Number (Pre-filled by puzzle)
    if (cell.isGiven) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2C394B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInSatisfiedEquation
                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                : const Color(0xFF475569),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          '${cell.solutionValue ?? ''}',
          style: TextStyle(
            color: const Color(0xFFF1F5F9),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    // 2. Blank Slot (Interactive)
    final hasValue = currentValue != null;
    Color borderColor;
    double borderWidth = 2.0;
    List<BoxShadow> shadows = [];

    if (isHighlightedInHint) {
      borderColor = const Color(0xFF10B981);
      borderWidth = 3.0;
      shadows.add(const BoxShadow(
        color: Color(0x8810B981),
        blurRadius: 10,
        spreadRadius: 2,
      ));
    } else if (isSelected) {
      borderColor = const Color(0xFFFFD700);
      borderWidth = 3.0;
      shadows.add(const BoxShadow(
        color: Color(0x66FFD700),
        blurRadius: 8,
        spreadRadius: 2,
      ));
    } else if (isInViolatedEquation && hasValue) {
      borderColor = const Color(0xFFEF4444);
      borderWidth = 2.5;
    } else if (isInSatisfiedEquation && hasValue) {
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.8);
      borderWidth = 2.0;
    } else {
      borderColor = hasValue ? const Color(0xFF60A5FA) : const Color(0xFF334155);
    }

    final tileColor = hasValue
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.85)
        : const Color(0xFF0F172A).withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: hasValue
            ? Text(
                '$currentValue',
                style: TextStyle(
                  color: const Color(0xFF93C5FD),
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w900,
                ),
              )
            : _buildNotesGrid(),
      ),
    );
  }

  Widget _buildNotesGrid() {
    if (notes == null || notes!.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
      );
    }

    final sortedNotes = notes!.toList()..sort();
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        children: sortedNotes
            .take(6)
            .map(
              (n) => Text(
                '$n',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
