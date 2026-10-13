import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../store_screen.dart';

class MathGameToolbar extends StatelessWidget {
  final GameProvider provider;

  const MathGameToolbar({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    // Compute hint badge text and styling
    final bool hasSpecialHints = user.hintsMega > 0 || user.hintsUltra > 0;
    final String hintBadge;
    final Color hintBadgeColor;

    if (user.hintsRegular > 0) {
      hintBadge = '${user.hintsRegular}';
      hintBadgeColor = const Color(0xFF10B981);
    } else if (hasSpecialHints) {
      hintBadge = '★';
      hintBadgeColor = const Color(0xFFF59E0B);
    } else {
      hintBadge = '0';
      hintBadgeColor = const Color(0xFF64748B);
    }

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
              onLongPress: () => _showNotesHelpSheet(context),
            ),
          ),

          // 4. Hints & Boosters
          Expanded(
            child: _buildToolButton(
              icon: hasSpecialHints ? Icons.auto_awesome_rounded : Icons.lightbulb_rounded,
              label: hasSpecialHints ? 'Boosters' : 'Smart Hint',
              isEnabled: !provider.isLevelComplete,
              badge: hintBadge,
              badgeColor: hintBadgeColor,
              accentColor: const Color(0xFF10B981),
              isSuperHighlight: true,
              onTap: () => _handleHintTap(context, user),
              onLongPress: () => _showHintPowerUpSheet(context, user),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            color: Color(0xFF1C130B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 25,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Color(0xFFFBBF24), size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'HOW NOTES (PENCIL) MODE WORKS',
                            style: GoogleFonts.lilitaOne(
                              fontSize: 18,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Notes Mode lets you pencil in temporary candidate numbers on blank tiles when testing possibilities!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.baloo2(
                      color: const Color(0xFFD1D5DB),
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildNotesStepCard(
                    '1',
                    'Turn Notes ON',
                    'Tap the "Notes" button on the toolbar to activate pencil mode (badge switches to ON).',
                    Icons.toggle_on_rounded,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 10),
                  _buildNotesStepCard(
                    '2',
                    'Pencil Candidates',
                    'Select any empty tile, then tap numbers from your tray. They appear as small notes without using up your numbers.',
                    Icons.edit_rounded,
                    const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 10),
                  _buildNotesStepCard(
                    '3',
                    'Place Final Number',
                    'When sure of your answer, toggle Notes OFF and tap your number to firmly place it onto the board!',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF3B1D00),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'GOT IT, LET\'S PLAY!',
                        style: GoogleFonts.lilitaOne(
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesStepCard(
    String stepNum,
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF26190F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.2),
            ),
            child: Text(
              stepNum,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lilitaOne(
                    color: color,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleHintTap(BuildContext context, UserProvider user) {
    if (provider.isLevelComplete) return;

    // If player has only regular hints (> 0) and no mega/ultra hints, quick-use Smart Hint
    if (user.hintsRegular > 0 && user.hintsMega == 0 && user.hintsUltra == 0) {
      user.useRegularHint();
      final hint = provider.requestSmartHint();
      if (hint == null) {
        provider.showFeedback('Board is already completely solved!');
      }
    } else {
      // If regular hints == 0 or player has Mega/Ultra hints, open the power-up selector
      _showHintPowerUpSheet(context, user);
    }
  }

  void _showHintPowerUpSheet(BuildContext context, UserProvider user) {
    if (provider.isLevelComplete) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            color: Color(0xFF1C130B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 25,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Row (Title + Coin balance)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 22),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'HINTS & POWER-UPS',
                                  style: GoogleFonts.lilitaOne(
                                    fontSize: 20,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1E11),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF6B4828)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 17),
                            const SizedBox(width: 4),
                            Text(
                              '${user.coins}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Smart Hint Card
                  _buildPowerUpCard(
                    context: sheetContext,
                    icon: Icons.lightbulb_rounded,
                    iconColor: const Color(0xFF34D399),
                    title: 'Smart Hint',
                    tag: 'Deductive Step',
                    description: 'Highlights the next logical cell and explains the mathematical deduction.',
                    countText: user.hintsRegular > 0 ? '${user.hintsRegular} available' : '0 available',
                    hasAvailable: user.hintsRegular > 0,
                    actionLabel: user.hintsRegular > 0 ? 'USE HINT' : '25 COINS',
                    actionColor: user.hintsRegular > 0 ? const Color(0xFF10B981) : const Color(0xFFD97706),
                    actionIcon: user.hintsRegular > 0 ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
                    onAction: () {
                      Navigator.pop(sheetContext);
                      if (user.hintsRegular > 0) {
                        user.useRegularHint();
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StoreScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2. Mega Hint Card
                  _buildPowerUpCard(
                    context: sheetContext,
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: 'Mega Hint',
                    tag: 'Solves 1 Equation',
                    description: 'Instantly solves an entire complete equation on the board!',
                    countText: user.hintsMega > 0 ? '${user.hintsMega} available' : '0 available',
                    hasAvailable: user.hintsMega > 0,
                    actionLabel: user.hintsMega > 0 ? 'USE MEGA' : 'STORE',
                    actionColor: user.hintsMega > 0 ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                    actionIcon: user.hintsMega > 0 ? Icons.bolt_rounded : Icons.storefront_rounded,
                    onAction: () {
                      Navigator.pop(sheetContext);
                      if (user.hintsMega > 0) {
                        user.useMegaHint();
                        final ok = provider.applyMegaHint();
                        if (!ok) {
                          provider.showFeedback('Board is already completely solved!');
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StoreScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Ultra Hint Card
                  _buildPowerUpCard(
                    context: sheetContext,
                    icon: Icons.diamond_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Ultra Hint',
                    tag: 'Solves 2 Equations',
                    description: 'Power solver! Instantly solves 2 equations across the board at once.',
                    countText: user.hintsUltra > 0 ? '${user.hintsUltra} available' : '0 available',
                    hasAvailable: user.hintsUltra > 0,
                    actionLabel: user.hintsUltra > 0 ? 'USE ULTRA' : 'STORE',
                    actionColor: user.hintsUltra > 0 ? const Color(0xFF0284C7) : const Color(0xFF0284C7),
                    actionIcon: user.hintsUltra > 0 ? Icons.auto_awesome_rounded : Icons.storefront_rounded,
                    onAction: () {
                      Navigator.pop(sheetContext);
                      if (user.hintsUltra > 0) {
                        user.useUltraHint();
                        final ok = provider.applyUltraHint();
                        if (!ok) {
                          provider.showFeedback('Board is already completely solved!');
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StoreScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPowerUpCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String tag,
    required String description,
    required String countText,
    required bool hasAvailable,
    required String actionLabel,
    required Color actionColor,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF281C12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF52361F), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. TOP HEADER: Icon + Title & Category Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Box
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: iconColor.withValues(alpha: 0.45), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),

              // Title & Tag Badge
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lilitaOne(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 0.8),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.baloo2(
                          color: iconColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. DESCRIPTION CONTAINER (Full-width, zero truncation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              description,
              style: GoogleFonts.baloo2(
                color: const Color(0xFFCBD5E1),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 3. ACTION FOOTER: Availability Status Pill + Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Availability Count Pill
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (hasAvailable ? const Color(0xFF10B981) : const Color(0xFF64748B))
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (hasAvailable ? const Color(0xFF10B981) : const Color(0xFF64748B))
                          .withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasAvailable ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 13,
                        color: hasAvailable ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          countText,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.baloo2(
                            color: hasAvailable ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action Button
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 14, color: Colors.white),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.lilitaOne(
                      fontSize: 11.5,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isEnabled = true,
    bool isActive = false,
    bool isSuperHighlight = false,
    String? badge,
    Color? badgeColor,
    Color accentColor = const Color(0xFFFBBF24),
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      onLongPress: isEnabled ? onLongPress : null,
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

                // Badge (Count, ON/OFF, etc. - NEVER with coin emojis that look like 0)
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
