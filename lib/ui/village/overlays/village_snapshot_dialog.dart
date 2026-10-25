import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/village_data.dart';
import '../../../engine/math/models.dart';
import '../../../engine/math/puzzle_codec.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/sound_service.dart';
import '../../game_screen.dart';

/// Village Snapshot & Community Hub Dialog.
/// Allows players to create high-resolution shareable postcards of their village,
/// exchange friend challenge puzzle codes, and view community milestone achievements.
class VillageSnapshotDialog extends StatefulWidget {
  final UserProvider user;

  const VillageSnapshotDialog({super.key, required this.user});

  @override
  State<VillageSnapshotDialog> createState() => _VillageSnapshotDialogState();
}

class _VillageSnapshotDialogState extends State<VillageSnapshotDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _postcardKey = GlobalKey();
  bool _isSharing = false;

  // Community Challenge Tab State
  Difficulty _selectedDifficulty = Difficulty.medium;
  late int _challengeSeed;
  final TextEditingController _friendCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _challengeSeed = DateTime.now().millisecondsSinceEpoch % 100000;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendCodeController.dispose();
    super.dispose();
  }

  String _getShareMessage() {
    final user = widget.user;
    final prosperity = user.villageCompletionPercent;
    final title = user.villageArchitectTitle;
    return '🏡 Check out my Cozy Math Village in Number Haven! ✨\n'
        'Village: Oakheart Meadow ($prosperity% Complete)\n'
        'Title: $title | Brain: ${user.brainSize}cc | Level: ${user.currentLevel}\n'
        'Can you build a cozier math village? Play with me! 🌿\n'
        'Download free on Google Play: https://play.google.com/store/apps/details?id=com.creatorboxstudios.numberhaven';
  }

  String _getVillagePassportCode() {
    final user = widget.user;
    return 'VILLAGE-OAK-L${user.currentLevel}-B${user.brainSize}-P${user.villageCompletionPercent}';
  }

  Future<void> _sharePostcard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    SoundService.playClick();
    HapticFeedback.mediumImpact();

    try {
      final boundary =
          _postcardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RepaintBoundary context not ready');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/oakheart_village_postcard.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        SoundService.playBonus();
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          text: _getShareMessage(),
        ));
      }
    } catch (e) {
      debugPrint('Error sharing village snapshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not capture snapshot: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _copyVillagePassport() {
    SoundService.playClick();
    HapticFeedback.lightImpact();
    final passport =
        '🏡 Number Haven Village Passport 🌿\n'
        'Mayor Level: ${widget.user.currentLevel} | Brain: ${widget.user.brainSize}cc\n'
        'Village: Oakheart Meadow (${widget.user.villageCompletionPercent}% Complete - ${widget.user.villageArchitectTitle})\n'
        'Buildings: ${widget.user.villageTotalBuildingStages}/15 Stages Built\n'
        'Passport Code: ${_getVillagePassportCode()}\n'
        'Play Number Haven: https://play.google.com/store/apps/details?id=com.creatorboxstudios.numberhaven';

    Clipboard.setData(ClipboardData(text: passport));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
            SizedBox(width: 8),
            Text('Village Passport copied to clipboard! 📜'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareChallengeCode() {
    SoundService.playClick();
    HapticFeedback.lightImpact();

    final code = MathPuzzleCodec.encodeSeed(
      difficulty: _selectedDifficulty,
      seed: _challengeSeed,
      id: widget.user.currentLevel,
    );

    final msg = '🧩 Math Puzzle Challenge from Number Haven! 🌿\n'
        'I challenge you to beat my time on this ${_selectedDifficulty.displayName.toUpperCase()} puzzle!\n'
        'Challenge Code: $code\n'
        'Paste this code in Number Haven Community tab to play the exact same puzzle! 🚀\n'
        'Download: https://play.google.com/store/apps/details?id=com.creatorboxstudios.numberhaven';

    SharePlus.instance.share(ShareParams(text: msg));
  }

  void _playFriendChallenge() {
    final rawInput = _friendCodeController.text.trim();
    final parsed = MathPuzzleCodec.decodeSeed(rawInput);

    if (parsed != null) {
      Navigator.pop(context);
      final provider = Provider.of<GameProvider>(context, listen: false);
      final success = provider.startCustomSeed(rawInput);
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate puzzle with this code.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code format! Example: NH1-M-12-84920'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = user.darkModeEnabled;
    final isHighContrast = user.highContrastEnabled;

    final dialogBg = isHighContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFF1E1712) : const Color(0xFFFFFDF5));

    final borderColor = isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFF8D6E63) : const Color(0xFF7A451A));

    final textColor = isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFFFFE0B2) : const Color(0xFF4A2810));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 660),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: isHighContrast ? 3.5 : 3.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0))
                    : (isDark ? const Color(0xFF2D1E16) : const Color(0xFFF5E6CC)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'VILLAGE SHOWCASE 📸',
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              color: textColor,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          'Snapshots & Community Hub',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF8D6E63),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      SoundService.playClick();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close_rounded, color: textColor, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF18120D) : const Color(0xFFEFE2CA),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF59E0B),
                indicatorWeight: 3.5,
                labelColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF7A451A),
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                labelStyle: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.photo_camera_rounded, size: 18), text: 'POSTCARD'),
                  Tab(icon: Icon(Icons.group_rounded, size: 18), text: 'CHALLENGES'),
                  Tab(icon: Icon(Icons.military_tech_rounded, size: 18), text: 'MILESTONES'),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostcardTab(isDark, isHighContrast),
                  _buildCommunityChallengesTab(isDark, isHighContrast),
                  _buildMilestonesTab(isDark, isHighContrast),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, curve: Curves.easeOutBack);
  }

  // ==========================================
  // TAB 1: VILLAGE POSTCARD & SNAPSHOT
  // ==========================================
  Widget _buildPostcardTab(bool isDark, bool isHighContrast) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // RepaintBoundary wrapping the Postcard for crisp PNG generation
          RepaintBoundary(
            key: _postcardKey,
            child: _buildPostcardCard(isDark, isHighContrast),
          ),
          const SizedBox(height: 14),

          // Primary Sharing Actions
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _isSharing ? null : _sharePostcard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHighContrast ? Colors.white : const Color(0xFF38BDF8),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSharing)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          else
                            const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isSharing ? 'GENERATING...' : 'SHARE POSTCARD 📸',
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _copyVillagePassport,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF332318) : const Color(0xFFE2D1BC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF6D4C41) : const Color(0xFF8B5A2B),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Share with friends on WhatsApp, Discord, or Instagram Stories!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF9E8E85) : const Color(0xFF755E4E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostcardCard(bool isDark, bool isHighContrast) {
    final user = widget.user;
    final prosperity = user.villageCompletionPercent;
    final architectTitle = user.villageArchitectTitle;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vintage Postal Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF7A451A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_rounded, color: Color(0xFFFFD54F), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'NUMBER HAVEN POSTCARD',
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: const Color(0xFFFFD54F),
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white70, width: 1),
                    ),
                    child: const Text(
                      'AIR MAIL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scenic Village Window
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Village Island Background Art
                  SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/village/meadow/island_bg.webp',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Cozy Ambient Vignette
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Biome Title and Stars
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                VillageData.meadow.biomeName.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                  color: Colors.white,
                                  fontSize: 17,
                                  letterSpacing: 1.2,
                                  shadows: const [
                                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7CB342),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$prosperity% PROSPERITY',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                        // Official Mayor Seal Badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DB),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF7A451A), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFFD97706), size: 22),
                        ),
                      ],
                    ),
                  ),

                  // Building Stages Showcase Row
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBuildingStageChip('🏠', 'Cottage', user.villageBuildings['cottage'] ?? 0),
                          _buildBuildingStageChip('🍞', 'Bakery', user.villageBuildings['bakery'] ?? 0),
                          _buildBuildingStageChip('🌾', 'Mill', user.villageBuildings['windmill'] ?? 0),
                          _buildBuildingStageChip('📚', 'Library', user.villageBuildings['library'] ?? 0),
                          _buildBuildingStageChip('🗼', 'Tower', user.villageBuildings['tower'] ?? 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Postcard Stats & Architecture Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        architectTitle,
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: const Color(0xFF7A451A),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Level ${user.currentLevel} • ${user.brainSize}cc',
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: const Color(0xFF8B5A2B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Postcard stats badge strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EEDD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPostcardStatItem(Icons.monetization_on_rounded, '${user.coins}', 'Coins', const Color(0xFFD97706)),
                        const SizedBox(width: 10),
                        _buildPostcardStatItem(Icons.psychology_rounded, '${user.levelsCompleted}', 'Solved', const Color(0xFF16A34A)),
                        const SizedBox(width: 10),
                        _buildPostcardStatItem(Icons.domain_rounded, '${user.villageTotalBuildingStages}/15', 'Stages', const Color(0xFF0284C7)),
                        const SizedBox(width: 10),
                        _buildPostcardStatItem(Icons.savings_rounded, '${user.acornVaultCoins}', 'Acorns', const Color(0xFF7A451A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Postcard footer signature
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📬 Mayor Bramble\'s Registry',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8D6E63),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'NUMBER HAVEN VILLAGE',
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          fontSize: 10,
                          color: const Color(0xFFB71C1C),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingStageChip(String emoji, String name, int stage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isStar = index < stage;
            return Icon(
              Icons.star_rounded,
              size: 10,
              color: isStar ? const Color(0xFFFBBF24) : Colors.white24,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPostcardStatItem(IconData icon, String val, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val,
              style: TextStyle(
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                fontSize: 12,
                color: const Color(0xFF4A2810),
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF8D6E63),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: COMMUNITY CHALLENGES & LEVEL CODES
  // ==========================================
  Widget _buildCommunityChallengesTab(bool isDark, bool isHighContrast) {
    final challengeCode = MathPuzzleCodec.encodeSeed(
      difficulty: _selectedDifficulty,
      seed: _challengeSeed,
      id: widget.user.currentLevel,
    );

    final rawFriendCode = _friendCodeController.text.trim();
    final parsedFriendCode = MathPuzzleCodec.decodeSeed(rawFriendCode);
    final isFriendCodeValid = parsedFriendCode != null;

    final cardBg = isHighContrast
        ? (isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9))
        : (isDark ? const Color(0xFF241A14) : const Color(0xFFFFFDF7));

    final cardBorder = isHighContrast
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? const Color(0xFF5D4037) : const Color(0xFFD7CCC8));

    final titleColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFF7A451A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Create a Friend Challenge Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.send_rounded, color: Color(0xFF0284C7), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'CREATE FRIEND CHALLENGE',
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: titleColor,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a difficulty to generate a unique level code. Friends who enter this code play the exact same puzzle!',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(height: 10),

                // Difficulty Selector Pills
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: Difficulty.values.map((d) {
                      final isSelected = d == _selectedDifficulty;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: GestureDetector(
                          onTap: () {
                            SoundService.playClick();
                            setState(() {
                              _selectedDifficulty = d;
                              _challengeSeed = DateTime.now().millisecondsSinceEpoch % 100000;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF332318) : const Color(0xFFEFE2CA)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF8B5A2B),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              d.displayName.toUpperCase(),
                              style: TextStyle(
                                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF5D4037)),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Challenge Code Preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, color: Color(0xFF0284C7), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challengeCode,
                          style: TextStyle(
                            fontFamily: GoogleFonts.firaCode().fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: challengeCode));
                          SoundService.playClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Challenge code copied! 📋'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Share Button
                GestureDetector(
                  onTap: _shareChallengeCode,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CB342),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF33691E), width: 2),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'SEND TO FRIENDS 🚀',
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Enter Friend's Challenge Code Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'PLAY A FRIEND\'S CODE',
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: titleColor,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste a code or message from a friend to play their exact puzzle challenge:',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(height: 10),

                // Text Field Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFriendCodeValid
                          ? const Color(0xFF10B981)
                          : (rawFriendCode.isEmpty
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                              : const Color(0xFFEF4444)),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _friendCodeController,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. NH1-M-12-84920',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste_rounded, color: Color(0xFF0284C7), size: 20),
                        tooltip: 'Paste from Clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            setState(() {
                              _friendCodeController.text = data!.text!;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Play Button
                GestureDetector(
                  onTap: isFriendCodeValid ? _playFriendChallenge : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isFriendCodeValid
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFriendCodeValid ? const Color(0xFF047857) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            isFriendCodeValid ? 'PLAY THIS PUZZLE ⚔️' : 'ENTER VALID CODE TO PLAY',
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: COMMUNITY MILESTONES & GUESTBOOK
  // ==========================================
  Widget _buildMilestonesTab(bool isDark, bool isHighContrast) {
    final user = widget.user;
    final buildings = user.villageBuildings;

    final milestones = [
      _MilestoneItem(
        emoji: '🏡',
        title: 'Founding Settler',
        req: 'Build Meadow Cottage (Stage 1+)',
        quote: 'Bramble the Bunny: "Welcome to Number Haven! The tea is hot and carrots are sweet."',
        unlocked: (buildings['cottage'] ?? 0) >= 1,
      ),
      _MilestoneItem(
        emoji: '🍞',
        title: 'Master Baker',
        req: 'Restore Oakheart Bakery (Stage 1+)',
        quote: 'Fern the Fox: "Fresh cinnamon rolls and bread for all mathematicians!"',
        unlocked: (buildings['bakery'] ?? 0) >= 1,
      ),
      _MilestoneItem(
        emoji: '🌾',
        title: 'Breeze Keeper',
        req: 'Spin the Windmill (Stage 1+)',
        quote: 'Miller: "The sweet wind carries equations across the entire valley."',
        unlocked: (buildings['windmill'] ?? 0) >= 1,
      ),
      _MilestoneItem(
        emoji: '📚',
        title: 'Ancient Archives',
        req: 'Unlock Scholarly Library (Stage 1+)',
        quote: 'Professor Hoot: "Equations are the poetry of the universe. Read deeply!"',
        unlocked: (buildings['library'] ?? 0) >= 1,
      ),
      _MilestoneItem(
        emoji: '🗼',
        title: 'Apex Beacon',
        req: 'Construct the Grand Tower (Stage 1+)',
        quote: 'Archon: "Our beacon lights up the realm, guiding curious minds forever."',
        unlocked: (buildings['tower'] ?? 0) >= 1,
      ),
      _MilestoneItem(
        emoji: '🌟',
        title: 'Village Renowned',
        req: 'Reach 50% Village Completion',
        quote: 'Mayor Bramble: "Travelers from far biomes come to admire our math paradise!"',
        unlocked: user.villageCompletionPercent >= 50,
      ),
      _MilestoneItem(
        emoji: '👑',
        title: 'Cozy Utopia',
        req: 'Upgrade all 5 buildings to 3 stars (15/15)',
        quote: 'The Community: "Awarded the Golden Monument of the Legendary Mayor!"',
        unlocked: user.villageTotalBuildingStages >= 15,
      ),
    ];

    final cardBg = isHighContrast
        ? (isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9))
        : (isDark ? const Color(0xFF241A14) : const Color(0xFFFFFDF7));

    final cardBorder = isHighContrast
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? const Color(0xFF5D4037) : const Color(0xFFD7CCC8));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final m = milestones[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: m.unlocked ? const Color(0xFF7CB342) : cardBorder,
              width: m.unlocked ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: m.unlocked
                      ? const Color(0xFF7CB342).withValues(alpha: 0.15)
                      : Colors.black12,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: m.unlocked ? const Color(0xFF7CB342) : Colors.grey,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: m.unlocked ? null : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            style: TextStyle(
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              fontSize: 14,
                              color: m.unlocked
                                  ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF7A451A))
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: m.unlocked ? const Color(0xFF7CB342) : Colors.grey[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            m.unlocked ? 'UNLOCKED' : 'LOCKED',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.req,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.quote,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneItem {
  final String emoji;
  final String title;
  final String req;
  final String quote;
  final bool unlocked;

  const _MilestoneItem({
    required this.emoji,
    required this.title,
    required this.req,
    required this.quote,
    required this.unlocked,
  });
}
