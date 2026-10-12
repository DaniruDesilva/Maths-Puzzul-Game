import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF24170E),
            Color(0xFF191008),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF52361F),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Undo
          Expanded(
            child: _buildToolButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              isEnabled: provider.moveHistory.isNotEmpty && !provider.isLevelComplete,
              accentColor: const Color(0xFF38BDF8),
              onTap: () => provider.undo(),
            ),
          ),

          // 2. Erase
          Expanded(
            child: _buildToolButton(
              icon: Icons.backspace_outlined,
              label: 'Erase',
              isEnabled: provider.selectedCell != null && !provider.isLevelComplete,
              accentColor: const Color(0xFFFB7185),
              onTap: () => provider.clearSelectedCell(),
            ),
          ),

          // 3. Notes Toggle
          Expanded(
            child: _buildToolButton(
              icon: Icons.edit_note_rounded,
              label: 'Notes',
              isActive: provider.isNotesMode,
              isEnabled: !provider.isLevelComplete,
              badge: provider.isNotesMode ? 'ON' : 'OFF',
              badgeColor: provider.isNotesMode
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF64748B),
              accentColor: const Color(0xFFFBBF24),
              onTap: () => provider.toggleNotesMode(),
            ),
          ),

          // 4. Smart Hint
          Expanded(
            child: _buildToolButton(
              icon: Icons.lightbulb_rounded,
              label: 'Smart Hint',
              isEnabled: !provider.isLevelComplete,
              badge: user.hintsRegular > 0 ? '${user.hintsRegular}' : '25🪙',
              badgeColor: user.hintsRegular > 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFD97706),
              accentColor: const Color(0xFF10B981),
              isSuperHighlight: true,
              onTap: () => _handleHintTap(context, user),
            ),
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
    bool isSuperHighlight = false,
    String? badge,
    Color? badgeColor,
    Color accentColor = const Color(0xFFFBBF24),
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [
                              accentColor.withValues(alpha: 0.35),
                              const Color(0xFF3B2516),
                            ]
                          : (isSuperHighlight
                              ? [
                                  const Color(0xFF382916),
                                  const Color(0xFF26190E),
                                ]
                              : [
                                  const Color(0xFF332014),
                                  const Color(0xFF22150D),
                                ]),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isActive
                          ? accentColor
                          : (isSuperHighlight
                              ? const Color(0xFF10B981).withValues(alpha: 0.6)
                              : const Color(0xFF6B4828)),
                      width: isActive || isSuperHighlight ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      if (isActive || isSuperHighlight)
                        BoxShadow(
                          color: (isActive ? accentColor : const Color(0xFF10B981))
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 2.5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? accentColor
                        : (isSuperHighlight
                            ? const Color(0xFF34D399)
                            : Colors.white.withValues(alpha: 0.9)),
                    size: 23,
                  ),
                ),

                // Badge (Count, Cost, or ON/OFF)
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(0, 1.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? accentColor
                    : const Color(0xFFCBD5E1),
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
