import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../data/village_data.dart';
import '../game/village/village_game.dart';
import '../app_router.dart';
import '../services/sound_service.dart';
import '../services/purchase_service.dart';
import '../services/app_review_service.dart';

import 'village/overlays/build_sheet.dart';
import 'village/overlays/starter_gift_dialog.dart';
import 'village/overlays/fortune_wheel_dialog.dart';
import 'village/overlays/acorn_vault_dialog.dart';
import 'game/interactive_onboarding_overlay.dart';

class VillageScreen extends StatefulWidget {
  final VillageDef village;
  final bool isRoot;
  const VillageScreen({super.key, required this.village, this.isRoot = false});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> with WidgetsBindingObserver {
  late VillageGame _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = Provider.of<UserProvider>(context, listen: false);
    
    if (user.musicEnabled && SoundService.isMusicEnabled) {
      SoundService.playVillageMusic();
    }
    
    _game = VillageGame(
      village: widget.village, 
      userProvider: user,
      onBuildingTapped: (def) async {
        _game.pauseEngine();
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) => BuildSheet(buildingDef: def),
        );
        if (mounted) {
          _game.resumeEngine();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStarterGiftBonus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _game.pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      _game.resumeEngine();
    }
  }

  Future<T?> _navigate<T>(String routeName, {Object? arguments}) async {
    _game.pauseEngine();
    try {
      return await Navigator.pushNamed<T>(context, routeName, arguments: arguments);
    } finally {
      if (mounted) {
        _game.resumeEngine();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E8FE),
      body: Stack(
        children: [
          // 0. Base Island Background (prevents any blank/white flashes while Flame initializes)
          Positioned.fill(
            child: Image.asset(
              'assets/images/village/meadow/island_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // The Flame Game Canvas (The Village)
          GameWidget(
            game: _game,
            loadingBuilder: (context) => Image.asset(
              'assets/images/village/meadow/island_bg.webp',
              fit: BoxFit.cover,
            ),
          ),
          
          // Subtle top/bottom gradients to ensure text is readable over any village area
          IgnorePointer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                    ),
                  ),
                ),
                if (widget.isRoot)
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Flutter Top UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: math.max(MediaQuery.of(context).size.width - 20, 360),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Left: Back Button (if !isRoot) OR Player Stats / Settings (if isRoot)
                      if (!widget.isRoot)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7CCC8),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF5D4037), width: 2.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5D4037), size: 22),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<UserProvider>(
                              builder: (context, user, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF5E6),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFF8B5A2B), width: 2.5),
                                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF7CB342),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.psychology, color: Colors.white, size: 22),
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 1.seconds),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.isLoading ? '...' : '${user.brainSize}cc',
                                            style: TextStyle(
                                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                              color: const Color(0xFF5D4037),
                                              fontSize: 20,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.isLoading ? '...' : 'Level ${user.currentLevel}',
                                            style: TextStyle(
                                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                              color: const Color(0xFF8B5A2B),
                                              fontSize: 13,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            
                            // Quick Action Buttons Row (Settings, Fortune Wheel, Acorn Vault)
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Settings Button
                                GestureDetector(
                                  onTap: () => _showSettingsDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5D4037),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF8B5A2B), width: 2.5),
                                      boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                    ),
                                    child: const Icon(Icons.settings_rounded, color: Color(0xFFFFD54F), size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Daily Fortune Wheel Button
                                Consumer<UserProvider>(
                                  builder: (context, user, _) {
                                    final canSpin = user.canClaimFreeSpin;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showFortuneWheel(context, user),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5D4037),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: canSpin ? const Color(0xFFFFD54F) : const Color(0xFF8B5A2B),
                                                width: 2.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4),
                                              ],
                                            ),
                                            child: const _FortuneWheelMiniIcon(size: 20),
                                          ),
                                        ),
                                        if (canSpin)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Acorn Piggy Bank Button
                                Consumer<UserProvider>(
                                  builder: (context, user, _) {
                                    final canCrack = user.canCrackAcornVault;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showAcornVault(context, user),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5D4037),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: canCrack ? const Color(0xFF7CB342) : const Color(0xFF8B5A2B),
                                                width: 2.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4),
                                              ],
                                            ),
                                            child: const Icon(Icons.savings_rounded, color: Color(0xFFFFD54F), size: 20),
                                          ),
                                        ),
                                        if (canCrack)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7CB342),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      
                      // Top Right: Currency & Helpers (Coins ONLY if !isRoot)
                      Consumer<UserProvider>(
                        builder: (context, user, child) {
                          if (!widget.isRoot) {
                            return _buildTopBadge(
                              Icons.monetization_on_rounded,
                              '${user.coins}',
                              const Color(0xFFFFD54F),
                              showAddIcon: true,
                              onTap: () => _navigate(AppRouter.store, arguments: 'coins'),
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  // Create Button
                                  GestureDetector(
                                    onTap: () => _navigate(AppRouter.customPuzzle),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5D4037),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF8B5A2B), width: 2.5),
                                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.brush_rounded, color: Color(0xFFFFD54F), size: 20),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Achievements Button
                                  GestureDetector(
                                    onTap: () => _navigate(AppRouter.achievements),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5D4037),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF8B5A2B), width: 2.5),
                                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Store / Hints Button
                                  _buildTopBadge(
                                    Icons.lightbulb_rounded,
                                    user.isLoading ? '...' : '${user.hintsRegular}',
                                    const Color(0xFFF2C94C),
                                    showAddIcon: true,
                                    onTap: () => _navigate(AppRouter.store, arguments: 'hints'),
                                  ),
                                  const SizedBox(height: 8),
                                  // Coins Badge - Now directly opens Store on Coins tab!
                                  _buildTopBadge(
                                    Icons.monetization_on_rounded,
                                    user.isLoading ? '...' : '${user.coins}',
                                    const Color(0xFFFFD54F),
                                    showAddIcon: true,
                                    onTap: () => _navigate(AppRouter.store, arguments: 'coins'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Play Area (Main Home Screen only)
          if (widget.isRoot)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Consumer<UserProvider>(
              builder: (context, user, _) {
                final showVillageTutorial = !user.hasCompletedVillageTutorial;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Village Tutorial Card with animated hand gesture pointing at PLAY
                    if (showVillageTutorial)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: VillageTutorialCard(
                          onPlay: () async {
                            user.completeVillageTutorial();
                            var provider = Provider.of<GameProvider>(context, listen: false);
                            await provider.startSpecificLevel(user.levelsCompleted + 1);
                            if (context.mounted) {
                              _navigate(AppRouter.game);
                            }
                          },
                          onSkip: () => user.completeVillageTutorial(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Map Button
                            _buildSideButton(
                              icon: Icons.map_rounded, 
                              color: const Color(0xFF8B5A2B), 
                              onTap: () => _navigate(AppRouter.biomeMap),
                            ),
                            const SizedBox(width: 14),
                            
                            // Massive Center Play Button
                            GestureDetector(
                              onTap: () async {
                                if (showVillageTutorial) {
                                  user.completeVillageTutorial();
                                }
                                var provider = Provider.of<GameProvider>(context, listen: false);
                                await provider.startSpecificLevel(user.levelsCompleted + 1);
                                if (context.mounted) {
                                  _navigate(AppRouter.game);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7CB342),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: const Color(0xFF33691E), width: 4),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 10)),
                                    BoxShadow(color: Color(0xFFAED581), spreadRadius: -4), // Inner highlight
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PLAY',
                                      style: TextStyle(
                                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                        fontSize: 28, 
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: const [
                                          Shadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 3),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 1.5.seconds, curve: Curves.easeInOut),
                            ),
                            const SizedBox(width: 14),
                            
                            // Daily Challenge Button
                            _buildSideButton(
                              icon: Icons.calendar_month_rounded, 
                              color: const Color(0xFF8B5A2B), 
                              onTap: user.canPlayDailyChallenge() ? () async {
                                var provider = Provider.of<GameProvider>(context, listen: false);
                                await provider.startDailyChallenge();
                                if (context.mounted) {
                                  _navigate(AppRouter.game);
                                }
                              } : () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: const Text('Come back tomorrow for a new Daily Challenge!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF8B5A2B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ));
                              },
                              hasNotification: user.canPlayDailyChallenge(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge(
    IconData icon, 
    String value, 
    Color iconColor, {
    bool showAddIcon = false,
    VoidCallback? onTap,
  }) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              color: const Color(0xFF5D4037), 
              fontSize: 16,
            ),
          ),
          if (showAddIcon) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF7CB342),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 13),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    return badge;
  }

  Widget _buildSideButton({required IconData icon, required Color color, required VoidCallback? onTap, bool hasNotification = false}) {
    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF5D4037), width: 4),
          boxShadow: [
            const BoxShadow(color: Colors.black45, offset: Offset(0, 8), blurRadius: 10),
            BoxShadow(color: Colors.white.withValues(alpha: 0.2), spreadRadius: -2, offset: const Offset(0, -2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
    
    if (hasNotification) {
      btn = Stack(
        clipBehavior: Clip.none,
        children: [
          btn,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
          ),
        ],
      );
    }
    
    return btn;
  }

  void _showSettingsDialog(BuildContext context) async {
    _game.pauseEngine();
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390, maxHeight: 660),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF5E6), // Parchment
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 10))],
          ),
          child: Consumer<UserProvider>(
            builder: (context, user, child) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                        fontSize: 26,
                        color: const Color(0xFF5D4037),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    _buildSettingRow('Sound Effects', Icons.volume_up_rounded, user.soundEnabled, user.toggleSound),
                    const SizedBox(height: 8),
                    _buildSettingRow('Music', Icons.music_note_rounded, user.musicEnabled, user.toggleMusic),
                    const SizedBox(height: 8),
                    _buildSettingRow('Haptics', Icons.vibration_rounded, user.hapticsEnabled, user.toggleHaptics),
                    const SizedBox(height: 8),
                    _buildSettingRow('Daily Reminder', Icons.notifications_active_rounded, user.notificationsEnabled, user.toggleNotifications),
                    
                    const SizedBox(height: 14),

                    // Rate App Button (Guaranteed single line with FittedBox)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppReviewService.openPlayStore();
                        },
                        icon: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'RATE NUMBER HAVEN',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              letterSpacing: 0.8,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B), // Golden amber
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Send Feedback Button (Guaranteed single line)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppReviewService.sendFeedback();
                        },
                        icon: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF81C784), size: 19),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'SEND FEEDBACK',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              letterSpacing: 0.8,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // How to play button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _showHowToPlayChoice(context);
                        },
                        icon: const Icon(Icons.school_rounded, color: Color(0xFFFFD54F), size: 19),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'HOW TO PLAY',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              letterSpacing: 0.8,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF8B5A2B), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),

                    // Restore Purchases
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PurchaseService.restorePurchases(context: context, user: user);
                        },
                        icon: const Icon(Icons.restore_rounded, size: 19),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'RESTORE PURCHASES',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              letterSpacing: 0.8,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00ACC1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7CB342),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 9),
                      ),
                      child: Text('CLOSE', style: TextStyle(fontFamily: GoogleFonts.lilitaOne().fontFamily, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
    if (mounted) {
      _game.resumeEngine();
    }
  }

  void _showHowToPlayChoice(BuildContext context) {
    showDialog(
      context: context,
      builder: (choiceCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF231710),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOW TO PLAY',
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 22,
                  color: const Color(0xFFFFD54F),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you would like to learn:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GoogleFonts.baloo2().fontFamily,
                  fontSize: 13,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 18),
              // 1. Interactive Gameplay option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(choiceCtx);
                    final user = Provider.of<UserProvider>(context, listen: false);
                    user.resetInteractiveOnboarding();
                    var provider = Provider.of<GameProvider>(context, listen: false);
                    await provider.replayInteractiveTutorial();
                    if (context.mounted) {
                      _navigate(AppRouter.game);
                    }
                  },
                  icon: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'PLAY GAMEPLAY TUTORIAL',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7CB342),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 2. Village tutorial option
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(choiceCtx);
                    final user = Provider.of<UserProvider>(context, listen: false);
                    user.resetVillageTutorial();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Village Tutorial activated! Tap the PLAY button to start.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF5D4037),
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.explore_rounded, color: Color(0xFF81C784), size: 19),
                  label: Text(
                    'REPLAY VILLAGE TUTORIAL',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: const Color(0xFFDCEDC8),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7CB342), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 3. Slides option
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(choiceCtx);
                    _navigate(AppRouter.tutorial);
                  },
                  icon: const Icon(Icons.menu_book_rounded, color: Color(0xFFFFD54F), size: 19),
                  label: Text(
                    'VIEW VISUAL RULEBOOK',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: const Color(0xFFFFFBEB),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B5A2B), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(choiceCtx),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFortuneWheel(BuildContext context, UserProvider user) async {
    _game.pauseEngine();
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => FortuneWheelDialog(user: user),
    );
    if (mounted) {
      _game.resumeEngine();
    }
  }

  void _showAcornVault(BuildContext context, UserProvider user) async {
    _game.pauseEngine();
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AcornVaultDialog(user: user),
    );
    if (mounted) {
      _game.resumeEngine();
    }
  }

  Widget _buildSettingRow(String title, IconData icon, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E3D2), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5A2B), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  color: const Color(0xFF5D4037),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: value ? const Color(0xFF7CB342) : Colors.grey,
              size: 38,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WELCOME STARTER GIFT POPUP (Appears immediately after onboarding)
  // -------------------------------------------------------------
  void _checkStarterGiftBonus() async {
    if (!widget.isRoot || !mounted) return;
    
    final user = Provider.of<UserProvider>(context, listen: false);
    await user.initialized;
    if (!mounted) return;

    if (!user.hasClaimedStarterGift) {
      // Gentle pause to allow village island animations to settle into view
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _showStarterGiftDialog(context, user);
    }
  }

  void _showStarterGiftDialog(BuildContext context, UserProvider user) async {
    _game.pauseEngine();
    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => StarterGiftDialog(user: user),
    );
    if (mounted) {
      _game.resumeEngine();
    }
  }
}

class _FortuneWheelMiniIcon extends StatelessWidget {
  final double size;
  const _FortuneWheelMiniIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _MiniWheelPainter(),
      ),
    );
  }
}

class _MiniWheelPainter extends CustomPainter {
  static const List<Color> _sectorColors = [
    Color(0xFFFFB300), // Amber Gold
    Color(0xFF2E7D32), // Forest Green
    Color(0xFF0288D1), // Cyan/Blue
    Color(0xFFE65100), // Deep Orange
    Color(0xFF7B1FA2), // Royal Purple
    Color(0xFFD32F2F), // Bright Red
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / _sectorColors.length;

    final wedgePaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Draw 6 colorful wheel sectors
    for (int i = 0; i < _sectorColors.length; i++) {
      wedgePaint.color = _sectorColors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        wedgePaint,
      );
      final x = center.dx + radius * math.cos(i * sweepAngle);
      final y = center.dy + radius * math.sin(i * sweepAngle);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }

    // Outer golden rim
    final rimPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 0.75, rimPaint);

    // Center golden pin / hub
    final hubPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, hubPaint);
    final hubBorderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, radius * 0.28, hubBorderPaint);

    // Top pointer needle at 12 o'clock
    final pointerPath = Path()
      ..moveTo(center.dx, radius * 0.42) // Needle tip points down toward center
      ..lineTo(center.dx - radius * 0.24, 0)
      ..lineTo(center.dx + radius * 0.24, 0)
      ..close();
    final pointerPaint = Paint()
      ..color = const Color(0xFFFFF59D)
      ..style = PaintingStyle.fill;
    final pointerBorder = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawPath(pointerPath, pointerPaint);
    canvas.drawPath(pointerPath, pointerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

