import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF34D399),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: Color(0xFF6EE7B7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Smart Deduction',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => provider.dismissActiveHint(),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFA7F3D0),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint.explanation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
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
                child: const Text('I will solve it'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => provider.applyActiveHint(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text('Place ${hint.solutionValue}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
