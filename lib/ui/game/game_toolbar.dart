import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';

class MathGameToolbar extends StatelessWidget {
  final GameProvider provider;

  const MathGameToolbar({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Undo Button
          _buildToolButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            isEnabled: provider.moveHistory.isNotEmpty && !provider.isLevelComplete,
            onTap: () => provider.undo(),
          ),

          // 2. Erase Button
          _buildToolButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            isEnabled: provider.selectedCell != null && !provider.isLevelComplete,
            onTap: () => provider.clearSelectedCell(),
          ),

          // 3. Notes Toggle
          _buildToolButton(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            isActive: provider.isNotesMode,
            isEnabled: !provider.isLevelComplete,
            badge: provider.isNotesMode ? 'ON' : 'OFF',
            onTap: () => provider.toggleNotesMode(),
          ),

          // 4. Smart Hint
          _buildToolButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Smart Hint',
            isEnabled: !provider.isLevelComplete,
            badge: '${user.hintsRegular}',
            highlightColor: const Color(0xFF10B981),
            onTap: () => _handleHintTap(context, user),
          ),
        ],
      ),
    );
  }

  void _handleHintTap(BuildContext context, UserProvider user) {
    if (provider.isLevelComplete) return;

    if (user.hintsRegular > 0) {
      user.useHint();
      final hint = provider.requestSmartHint();
      if (hint == null) {
        provider.showFeedback('Board is already completely solved!');
      }
    } else if (user.coins >= 25) {
      user.spendCoins(25);
      final hint = provider.requestSmartHint();
      if (hint == null) {
        provider.showFeedback('Board is already completely solved!');
      }
    } else {
      provider.showFeedback('Need 25 coins for Smart Hint!');
    }
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
    bool isActive = false,
    String? badge,
    Color? highlightColor,
  }) {
    final activeColor = highlightColor ?? const Color(0xFF60A5FA);

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withValues(alpha: 0.25)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? activeColor
                          : const Color(0xFF334155).withValues(alpha: 0.6),
                      width: isActive ? 2.0 : 1.2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? activeColor : const Color(0xFFE2E8F0),
                    size: 24,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor
                            : const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 0.8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
