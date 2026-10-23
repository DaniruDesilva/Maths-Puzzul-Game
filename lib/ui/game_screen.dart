import 'package:flutter/material.dart';
import 'dart:ui' as import_ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/math/models.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import '../services/app_review_service.dart';
import 'game/board_view.dart';
import 'game/number_tray.dart';
import 'game/game_toolbar.dart';
import 'game/hint_bubble.dart';
import 'game/interactive_onboarding_overlay.dart';
import '../services/onboarding_service.dart';
import 'tutorial_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;
  int? _lastLevelDoubled;

  @override
  void initState() {
    super.initState();
    SoundService.stopAmbience();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<GameProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    _setupCallbacks(provider, user);
  }

  void _saveCurrentLevelProgress(GameProvider provider, UserProvider user) {
    if (provider.levelProgressSaved) return;
    provider.levelProgressSaved = true;

    int stars = provider.calculateStars();
    int earnedScore = provider.score;
    final eqCount = provider.currentPuzzle?.equations.length ?? 4;

    final rewards = user.recordLevelComplete(
      levelIndex: provider.currentLevel,
      scoreEarned: earnedScore,
      starsEarned: stars,
      hintsUsed: provider.hintsUsedInLevel,
      isDaily: provider.isDailyChallenge,
      isCustom: provider.isCustomPuzzle,
      equationsSolved: eqCount,
    );
    provider.lastRewards = rewards;

    user.addEquationSolved(eqCount);

    if (provider.isDailyChallenge) {
      user.completeDailyChallenge();
    }

    if (provider.currentLevel == 1 && !provider.isDailyChallenge && !provider.isCustomPuzzle) {
      user.completeInteractiveOnboarding();
      provider.forceInteractiveOnboarding = false;
    }
  }

  void _setupCallbacks(GameProvider provider, UserProvider user) {
    provider.onLevelCompleteCallback = () {
      _saveCurrentLevelProgress(provider, user);
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (SoundService.isMusicEnabled) {
      SoundService.playVillageMusic();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Deep Woodland / Twilight Village Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0C1912), // Deep woodland dusk
                  Color(0xFF16281E), // Cozy twilight pine
                  Color(0xFF0E1610), // Grounded shadow
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Custom Ambient Lantern Firefly Particles
          const Positioned.fill(
            child: FireflyParticles(),
          ),

          // Ambient Background Glows
          Positioned(
            top: 80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.25, duration: 4.seconds),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.15, duration: 5.seconds),
          ),

          Consumer<GameProvider>(
            builder: (context, provider, child) => BackdropFilter(
              filter: import_ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                color: Colors.black.withValues(alpha: provider.isLevelComplete ? 0.80 : 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Consumer<GameProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading || provider.currentPuzzle == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        Text(
                          'Loading puzzle...',
                          style: TextStyle(
                            color: const Color(0xFFD1FAE5),
                            fontFamily: GoogleFonts.baloo2().fontFamily,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.isLevelComplete) {
                  return _buildLevelComplete(provider);
                }

                return _buildGameUI(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameUI(GameProvider provider) {
    final user = Provider.of<UserProvider>(context);
    final onboardingInfo = OnboardingService.evaluateStep(
      levelNumber: provider.currentLevel,
      isDailyChallenge: provider.isDailyChallenge,
      isCustomPuzzle: provider.isCustomPuzzle,
      hasCompletedInteractiveOnboarding: user.hasCompletedInteractiveOnboarding,
      forceReplay: provider.forceInteractiveOnboarding,
      selectedCell: provider.selectedCell,
      currentValues: provider.currentValues,
      availableTray: provider.availableTray,
    );

    return Column(
      children: [
        // 1. Top Bar with Level Badge, Progress & Score
        _buildTopBar(provider, context),

        // 2. Equation Progress Bar
        _buildEquationProgressBar(provider),

        // 3. Interactive Level 1 Onboarding Card
        if (onboardingInfo != null && onboardingInfo.step != OnboardingStep.completed)
          InteractiveOnboardingCard(
            info: onboardingInfo,
            onSkip: () => user.completeInteractiveOnboarding(),
          )
        // 4. In-Game Contextual Tooltips (Notes, Hint, Mistakes)
        else if (provider.isNotesMode && !user.hasSeenNotesTooltip)
          InGameContextualTooltip(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFFFFD54F),
            title: 'PENCIL NOTES ACTIVE',
            message: 'Tap numbers in the tray to jot down candidate notes into the slot without making a final move.',
            onDismiss: () => user.markNotesTooltipSeen(),
          )
        else if (provider.currentLevel == 2 && !user.hasSeenHintTooltip)
          InGameContextualTooltip(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFF34D399),
            title: 'SMART HINT AVAILABLE',
            message: 'Stuck on tricky intersections? Tap the Smart Hint button anytime for free logical guidance!',
            onDismiss: () => user.markHintTooltipSeen(),
          )
        else if (provider.violatedEquationIds.isNotEmpty && !user.hasSeenMistakeTooltip)
          InGameContextualTooltip(
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFFB7185),
            title: 'EQUATION MISMATCH',
            message: 'The line turned red because numbers don\'t add up. Tap Erase or Undo to fix it!',
            onDismiss: () => user.markMistakeTooltipSeen(),
          )
        // 5. Feedback Pill (if any alert active)
        else if (provider.feedbackMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: _buildFeedbackPill(provider.feedbackMessage!),
          ),

        // 6. Central Interactive Crossword Board (Zero Overflow Guaranteed)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: MathBoardView(
              provider: provider,
              tutorialTargetCell: onboardingInfo?.targetCell,
            ),
          ),
        ),

        // 7. Floating Smart Hint bubble (if active)
        MathHintBubble(provider: provider),

        // 8. Tactile 3D Candidate Number Tray
        MathNumberTray(
          provider: provider,
          tutorialTargetNumber: onboardingInfo?.targetTrayNumber,
        ),

        // 9. Wood & Brass Action Toolbar (Undo, Erase, Notes, Hint)
        MathGameToolbar(provider: provider),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildTopBar(GameProvider provider, BuildContext context) {
    final puzzle = provider.currentPuzzle;
    final diff = puzzle?.difficulty ?? Difficulty.easy;

    // Difficulty badge styling
    Color diffBg;
    Color diffText;
    switch (diff) {
      case Difficulty.easy:
        diffBg = const Color(0xFF064E3B);
        diffText = const Color(0xFF34D399);
        break;
      case Difficulty.medium:
        diffBg = const Color(0xFF78350F);
        diffText = const Color(0xFFFBBF24);
        break;
      case Difficulty.hard:
        diffBg = const Color(0xFF7C2D12);
        diffText = const Color(0xFFFF8A65);
        break;
      case Difficulty.expert:
        diffBg = const Color(0xFF4C1D95);
        diffText = const Color(0xFFA78BFA);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Left: Back button + Level Info (flexibly constrained)
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26190F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5A3C23), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFDE68A),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              provider.isDailyChallenge
                                  ? 'DAILY'
                                  : (provider.isCustomPuzzle
                                      ? 'CUSTOM'
                                      : 'LVL ${provider.currentLevel}'),
                              style: TextStyle(
                                color: const Color(0xFFFFFBEB),
                                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                fontSize: 16.5,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Difficulty Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: diffBg,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: diffText.withValues(alpha: 0.6), width: 1.0),
                            ),
                            child: Text(
                              diff.displayName.toUpperCase(),
                              style: TextStyle(
                                color: diffText,
                                fontFamily: GoogleFonts.baloo2().fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Cozy Math Village',
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontFamily: GoogleFonts.baloo2().fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Right: Score Pill + Settings Gear
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score badge with golden star
              Consumer<UserProvider>(
                builder: (context, user, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E1C0F), Color(0xFF1E130A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                      const SizedBox(width: 3),
                      Text(
                        '${user.totalScore}',
                        style: TextStyle(
                          color: const Color(0xFFFFFBEB),
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Help / Tutorial Quick Guide button
              GestureDetector(
                onTap: () => _showHelpGuide(provider),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26190F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5A3C23), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFFFDE68A),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showPauseMenu(provider),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26190F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5A3C23), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Color(0xFFE2E8F0),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Live Equation Completion Progress Tracker ---
  Widget _buildEquationProgressBar(GameProvider provider) {
    final puzzle = provider.currentPuzzle;
    if (puzzle == null) return const SizedBox.shrink();

    final totalEquations = puzzle.equations.length;
    final satisfiedCount = provider.satisfiedEquationIds.length;
    final progress = totalEquations > 0 ? (satisfiedCount / totalEquations).clamp(0.0, 1.0) : 0.0;
    final isAllSolved = satisfiedCount == totalEquations;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E140C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllSolved
              ? const Color(0xFF10B981)
              : const Color(0xFF4A3320),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllSolved ? Icons.check_circle_rounded : Icons.calculate_outlined,
            color: isAllSolved ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Equations: $satisfiedCount / $totalEquations',
            style: TextStyle(
              color: isAllSolved ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF2E1F14),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAllSolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPill(String message) {
    final isNoteOrInfo = message.contains('✏️') || message.contains('✍️') || message.contains('Notes') || message.contains('notes');
    final gradientColors = isNoteOrInfo
        ? [const Color(0xFFB45309), const Color(0xFF78350F)]
        : [const Color(0xFFDC2626), const Color(0xFFB91C1C)];
    final borderColor = isNoteOrInfo ? const Color(0xFFFDE68A) : const Color(0xFFFCA5A5);
    final glowColor = isNoteOrInfo ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final iconData = isNoteOrInfo ? Icons.edit_note_rounded : Icons.info_outline_rounded;

    return Container(
      key: ValueKey('feedback_$message'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: isNoteOrInfo ? const Color(0xFFFDE68A) : Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: isNoteOrInfo ? const Color(0xFFFFFBEB) : Colors.white,
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('feedback_$message'))
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut, duration: 400.ms)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildLevelComplete(GameProvider provider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!provider.levelProgressSaved) {
      _saveCurrentLevelProgress(provider, userProvider);
    }

    int stars = provider.calculateStars();
    int totalScore = provider.score;
    int starBonus = 100 * stars;
    int baseScore = (totalScore - starBonus).clamp(0, totalScore);

    final rewards = provider.lastRewards;
    int totalCoins = rewards?['totalCoins'] ?? (50 + 10 * stars);
    int brainEarned = rewards?['brainEarned'] ?? (50 * stars);
    int libraryCoins = rewards?['libraryCoins'] ?? 0;
    bool isReplay = rewards != null &&
        (rewards['isNewLevel'] == 0 &&
            rewards['newStars'] == 0 &&
            !provider.isDailyChallenge &&
            !provider.isCustomPuzzle);

    return Center(
      child: RepaintBoundary(
        key: _shareKey,
        child: Container(
          color: const Color(0xFF0F1E16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Stars Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 20.0 : 0.0),
                        child: Icon(
                          Icons.star_rounded,
                          color: i < stars ? const Color(0xFFFFD54F) : const Color(0xFF334155),
                          size: i == 1 ? 76 : 60,
                          shadows: [
                            if (i < stars) const Shadow(color: Color(0xFFFFB74D), blurRadius: 20),
                            const Shadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 4),
                          ],
                        )
                            .animate(delay: (200 + i * 200).ms)
                            .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                            .rotate(begin: -0.2, end: 0, curve: Curves.easeOut),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  provider.isDailyChallenge ? 'DAILY CHALLENGE' : 'LEVEL ${provider.currentLevel}',
                  style: TextStyle(
                    color: const Color(0xFFFFD54F),
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                ).animate().slideY(begin: 1.0).fadeIn(delay: 200.ms),

                Text(
                  'SOLVED!',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 44,
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Color(0xFF10B981), blurRadius: 20),
                      Shadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms, delay: 400.ms),

                const SizedBox(height: 24),

                // Score Breakdown Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF26190F), Color(0xFF191008)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF5A3C23), width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow(
                        'Equations Solved',
                        '${provider.currentPuzzle?.equations.length ?? 0}',
                        Icons.calculate_rounded,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreRow(
                        'Base Score',
                        '+$baseScore',
                        Icons.score_rounded,
                        const Color(0xFF60A5FA),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreRow(
                        'Star Bonus',
                        '+$starBonus',
                        Icons.star_rounded,
                        const Color(0xFFFFD54F),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreRow(
                        'Brain Growth',
                        isReplay ? '+0cc (Earned)' : '+${brainEarned}cc',
                        Icons.psychology_rounded,
                        const Color(0xFFA78BFA),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreRow(
                        'Coins Earned',
                        isReplay ? '+0 (Earned)' : '+$totalCoins',
                        Icons.monetization_on_rounded,
                        const Color(0xFFF59E0B),
                      ),
                      if (libraryCoins > 0) ...[
                        const SizedBox(height: 10),
                        _buildScoreRow(
                          'Library Perk',
                          '+$libraryCoins coins',
                          Icons.menu_book_rounded,
                          const Color(0xFF34D399),
                        ),
                      ],
                      if (provider.isDailyChallenge) ...[
                        const SizedBox(height: 10),
                        _buildScoreRow(
                          'Streak Reward',
                          '+3 Hints',
                          Icons.tips_and_updates_rounded,
                          const Color(0xFFFBBF24),
                        ),
                      ],
                      if (provider.hintsUsedInLevel > 0) ...[
                        const SizedBox(height: 10),
                        _buildScoreRow(
                          'Hints Used',
                          '${provider.hintsUsedInLevel}',
                          Icons.lightbulb_outline_rounded,
                          const Color(0xFF94A3B8),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: Color(0xFF4A3320), thickness: 1.5),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              color: const Color(0xFFD4C5B9),
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '+$totalScore',
                            style: TextStyle(
                              color: const Color(0xFFFFFBEB),
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOut),

                // 2x Coin Multiplier (Rewarded Ad)
                if (!isReplay && totalCoins > 0) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _buildDoubleCoinsButton(
                      coinsToDouble: totalCoins,
                      isDoubled: _lastLevelDoubled == provider.currentLevel,
                      onTap: () {
                        if (_lastLevelDoubled == provider.currentLevel) return;
                        AdService.showRewardedAd(
                          userProvider,
                          onReward: () {
                            userProvider.addCoins(totalCoins);
                            setState(() {
                              _lastLevelDoubled = provider.currentLevel;
                            });
                            SoundService.playSuccess();
                          },
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildControlButton(
                          icon: Icons.play_arrow_rounded,
                          label: provider.isCustomPuzzle
                              ? 'FINISH'
                              : (provider.isDailyChallenge ? 'CLAIM REWARD' : 'NEXT LEVEL'),
                          highlight: true,
                          onTap: () async {
                            var user = Provider.of<UserProvider>(context, listen: false);

                            void proceed() {
                              if (provider.isDailyChallenge || provider.isCustomPuzzle) {
                                Navigator.pop(context);
                              } else {
                                provider.nextLevel();
                              }
                            }

                            // Milestone Review Prompt (Level 5, 15, 30)
                            if (!provider.isDailyChallenge && !provider.isCustomPuzzle) {
                              bool shouldPrompt = await AppReviewService.shouldPromptMilestoneReview(provider.currentLevel);
                              if (shouldPrompt && mounted) {
                                await AppReviewService.showMilestoneRatingDialog(
                                  context,
                                  level: provider.currentLevel,
                                );
                              }
                            }

                            if (!user.adsRemoved &&
                                !provider.isDailyChallenge &&
                                !provider.isCustomPuzzle &&
                                provider.currentLevel % 3 == 0) {
                              AdService.showInterstitialAd(proceed, currentLevel: provider.currentLevel);
                            } else {
                              proceed();
                            }
                          },
                        ).animate(delay: 1000.ms).scale(curve: Curves.elasticOut, duration: 600.ms),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildControlButton(
                          icon: Icons.share_rounded,
                          label: 'SHARE',
                          color: const Color(0xFF0F766E),
                          onTap: () async {
                            if (_isSharing) return;
                            setState(() => _isSharing = true);
                            try {
                              RenderRepaintBoundary boundary =
                                  _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                              import_ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                              var byteData = await image.toByteData(format: import_ui.ImageByteFormat.png);
                              if (byteData != null) {
                                final directory = await getTemporaryDirectory();
                                final file = File('${directory.path}/score_share.png');
                                await file.writeAsBytes(byteData.buffer.asUint8List());

                                String title = provider.isDailyChallenge
                                    ? 'Number Haven Daily Challenge'
                                    : (provider.isCustomPuzzle
                                        ? 'Custom Puzzle'
                                        : 'Level ${provider.currentLevel}');
                                await SharePlus.instance.share(ShareParams(
                                  files: [XFile(file.path)],
                                  text:
                                      'I just solved $title with $stars/3 stars in Number Haven: Cozy Math Village!',
                                ));
                              }
                            } catch (e) {
                              debugPrint('Error sharing image: $e');
                            } finally {
                              if (mounted) setState(() => _isSharing = false);
                            }
                          },
                        ).animate(delay: 1100.ms).scale(curve: Curves.elasticOut, duration: 600.ms),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFCBD5E1),
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFFF8FAFC),
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleCoinsButton({
    required int coinsToDouble,
    required bool isDoubled,
    required VoidCallback onTap,
  }) {
    if (isDoubled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF14532D).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF22C55E), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD54F), size: 24),
              const SizedBox(width: 10),
              Text(
                'COINS DOUBLED! (+$coinsToDouble)',
                style: TextStyle(
                  color: const Color(0xFFFFFBEB),
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1B5E20), blurRadius: 12, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_rounded, color: Color(0xFFFFE082), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'WATCH AD FOR BONUS',
                            style: TextStyle(
                              color: const Color(0xFFFFE082),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontFamily: GoogleFonts.baloo2().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DOUBLE COINS (+$coinsToDouble)',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          fontSize: 17,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '2X',
                  style: TextStyle(
                    color: const Color(0xFF1B5E20),
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().shimmer(duration: 2.seconds, color: Colors.white24);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
    Color? color,
  }) {
    final btnColor = highlight ? const Color(0xFF10B981) : (color ?? const Color(0xFF4A3320));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: btnColor.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPauseMenu(GameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF26190F), Color(0xFF191008)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF5A3C23), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAUSED',
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 32,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 22),
                _buildMenuButton('RESUME', const Color(0xFF10B981), () {
                  Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _buildMenuButton('RESTART', const Color(0xFFF59E0B), () {
                  provider.restartLevel();
                  Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _buildMenuButton('QUIT TO VILLAGE', const Color(0xFFEF4444), () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close GameScreen
                }),
              ],
            ),
          ),
        ).animate().scaleXY(begin: 0.85, end: 1.0, duration: 250.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildMenuButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 4)
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpGuide(GameProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            color: Color(0xFF1E140C),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFFBBF24),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOW TO PLAY',
                            style: TextStyle(
                              color: const Color(0xFFFFFBEB),
                              fontFamily: GoogleFonts.lilitaOne().fontFamily,
                              fontSize: 19,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Number Haven Crossword Guide',
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontFamily: GoogleFonts.baloo2().fontFamily,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  icon: Icons.shuffle_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Crossword Math Equations',
                  desc: 'Every row and column equation must calculate correctly. When solved, lines light up emerald green!',
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.touch_app_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  title: 'Select Cell & Place Tile',
                  desc: 'Tap an empty wooden slot on the board, then tap a candidate number tile from your tray below.',
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFF34D399),
                  title: 'Smart Hints & Boosters',
                  desc: 'Stuck? Smart Hint calculates the next logical deduction with zero score penalty.',
                ),
                const SizedBox(height: 10),
                _buildHelpItem(
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFFFB7185),
                  title: 'Pencil Notes Mode',
                  desc: 'Turn on Notes to jot down possible candidates in any slot without committing a move.',
                ),
                const SizedBox(height: 20),
                // Replay Level 1 Interactive Tutorial button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7CB342),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      'Replay Interactive Tutorial (Level 1)',
                      style: TextStyle(
                        fontFamily: GoogleFonts.baloo2().fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final user = Provider.of<UserProvider>(context, listen: false);
                      user.resetInteractiveOnboarding();
                      await provider.replayInteractiveTutorial();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Open Full Slides Tutorial
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE2E8F0),
                      side: const BorderSide(color: Color(0xFF5D3E24), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.auto_stories_rounded, size: 18),
                    label: Text(
                      'View Visual Rulebook Slides',
                      style: TextStyle(
                        fontFamily: GoogleFonts.baloo2().fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TutorialScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF52361F), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFFFFBEB),
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: const Color(0xFFCBD5E1),
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Ambient Firefly Particles
class FireflyParticles extends StatefulWidget {
  const FireflyParticles({super.key});

  @override
  State<FireflyParticles> createState() => _FireflyParticlesState();
}

class _FireflyParticlesState extends State<FireflyParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firefly> _fireflies = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 35; i++) {
      _fireflies.add(Firefly(_random));
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        for (var f in _fireflies) {
          f.update();
        }
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: FireflyPainter(_fireflies),
        size: Size.infinite,
      ),
    );
  }
}

class Firefly {
  double x, y;
  double speedX, speedY;
  double size;
  double phase;
  final Random random;

  Firefly(this.random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        speedX = (random.nextDouble() - 0.5) * 0.002,
        speedY = -random.nextDouble() * 0.004 - 0.001,
        size = random.nextDouble() * 3 + 1,
        phase = random.nextDouble() * pi * 2;

  void update() {
    x += speedX;
    y += speedY;
    phase += 0.05;

    x += sin(phase) * 0.0005;

    if (y < -0.1) {
      y = 1.1;
      x = random.nextDouble();
    }
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;
  }
}

class FireflyPainter extends CustomPainter {
  final List<Firefly> fireflies;

  FireflyPainter(this.fireflies);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (var f in fireflies) {
      double opacity = (sin(f.phase) + 1) / 2 * 0.6 + 0.1;
      paint.color = const Color(0xFFFFD54F).withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(f.x * size.width, f.y * size.height),
        f.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
