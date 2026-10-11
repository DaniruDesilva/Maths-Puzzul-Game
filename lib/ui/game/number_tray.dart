import 'package:flutter/material.dart';
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
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF131D2A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'All numbers placed! Checking equations...',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Group available numbers by count
    final counts = <int, int>{};
    for (final num in available) {
      counts[num] = (counts[num] ?? 0) + 1;
    }
    final sortedUniqueNumbers = counts.keys.toList()..sort();

    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isHintNumber
                    ? [const Color(0xFF10B981), const Color(0xFF047857)]
                    : [const Color(0xFF2E3D52), const Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHintNumber
                    ? const Color(0xFF34D399)
                    : const Color(0xFF64748B).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHintNumber
                      ? const Color(0x6610B981)
                      : Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (count > 1)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  '×$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
