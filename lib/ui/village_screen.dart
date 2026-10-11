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

import 'village/overlays/build_sheet.dart';
import 'village/overlays/starter_gift_dialog.dart';

class VillageScreen extends StatefulWidget {
  final VillageDef village;
  final bool isRoot;
  const VillageScreen({super.key, required this.village, this.isRoot = false});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  late VillageGame _game;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    
    if (user.musicEnabled && SoundService.isMusicEnabled) {
      SoundService.playVillageMusic();
    }
    
    _game = VillageGame(
      village: widget.village, 
      userProvider: user,
      onBuildingTapped: (def) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => BuildSheet(buildingDef: def),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStarterGiftBonus();
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Left: Back Button (if !isRoot) OR Player Stats / Settings (if isRoot)
                  if (!widget.isRoot)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7CCC8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5D4037), width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5D4037)),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<UserProvider>(
                          builder: (context, user, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF5E6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7CB342),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 1.seconds),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.isLoading ? '...' : '${user.brainSize}cc',
                                        style: TextStyle(
                                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                          color: const Color(0xFF5D4037),
                                          fontSize: 22,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.isLoading ? '...' : 'Level ${user.currentLevel}',
                                        style: TextStyle(
                                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                          color: const Color(0xFF8B5A2B),
                                          fontSize: 14,
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
                        
                        // Settings Button
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showSettingsDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D4037),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.settings_rounded, color: Color(0xFFFFD54F), size: 22),
                          ),
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
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              // Create Button
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.customPuzzle),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5D4037), // Dark brown background
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
                                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.brush_rounded, color: Color(0xFFFFD54F), size: 22), // Gold icon
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Achievements Button
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.achievements),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5D4037), // Dark brown background
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
                                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 22), // Gold icon
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Store / Hints Button
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.store),
                                child: _buildTopBadge(
                                  Icons.lightbulb_rounded,
                                  user.isLoading ? '...' : '${user.hintsRegular}',
                                  const Color(0xFFF2C94C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Coins Badge
                              _buildTopBadge(
                                Icons.monetization_on_rounded,
                                user.isLoading ? '...' : '${user.coins}',
                                const Color(0xFFFFD54F),
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
          
          // Bottom Play Area (Main Home Screen only)
          if (widget.isRoot)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Consumer<UserProvider>(
              builder: (context, user, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Map Button
                        _buildSideButton(
                          icon: Icons.map_rounded, 
                          color: const Color(0xFF8B5A2B), 
                          onTap: () => Navigator.pushNamed(context, AppRouter.biomeMap)
                        ),
                        
                        // Massive Center Play Button
                        GestureDetector(
                          onTap: () {
                            var provider = Provider.of<GameProvider>(context, listen: false);
                            provider.startSpecificLevel(user.levelsCompleted + 1);
                            Navigator.pushNamed(context, AppRouter.game);
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
                        
                        // Daily Challenge Button
                        _buildSideButton(
                          icon: Icons.calendar_month_rounded, 
                          color: const Color(0xFF8B5A2B), 
                          onTap: user.canPlayDailyChallenge() ? () {
                            var provider = Provider.of<GameProvider>(context, listen: false);
                            provider.startDailyChallenge();
                            Navigator.pushNamed(context, AppRouter.game);
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
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge(IconData icon, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              color: const Color(0xFF5D4037), 
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF5E6), // Parchment
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 10))],
          ),
          child: Consumer<UserProvider>(
            builder: (context, user, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 28,
                      color: const Color(0xFF5D4037),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSettingRow('Sound Effects', Icons.volume_up_rounded, user.soundEnabled, user.toggleSound),
                  const SizedBox(height: 16),
                  _buildSettingRow('Music', Icons.music_note_rounded, user.musicEnabled, user.toggleMusic),
                  const SizedBox(height: 16),
                  _buildSettingRow('Haptics', Icons.vibration_rounded, user.hapticsEnabled, user.toggleHaptics),
                  
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.tutorial);
                    },
                    icon: const Icon(Icons.school_rounded, color: Color(0xFFFFD54F)),
                    label: Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8B5A2B), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Purchases Restored', style: TextStyle(fontFamily: GoogleFonts.lilitaOne().fontFamily)),
                        backgroundColor: const Color(0xFF7CB342),
                      ));
                    },
                    icon: const Icon(Icons.restore_rounded),
                    label: Text('RESTORE PURCHASES', style: TextStyle(fontFamily: GoogleFonts.lilitaOne().fontFamily)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7CB342),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text('CLOSE', style: TextStyle(fontFamily: GoogleFonts.lilitaOne().fontFamily, fontSize: 18)),
                  ),
                ],
              );
            },
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildSettingRow(String title, IconData icon, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E3D2), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5A2B), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  color: const Color(0xFF5D4037),
                  fontSize: 18,
                ),
              ),
            ),
            Icon(
              value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: value ? const Color(0xFF7CB342) : Colors.grey,
              size: 40,
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

  void _showStarterGiftDialog(BuildContext context, UserProvider user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StarterGiftDialog(user: user),
    );
  }
}
