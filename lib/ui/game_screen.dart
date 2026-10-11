import 'package:flutter/material.dart';
import 'dart:ui' as import_ui;
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../engine/level_engine.dart';
import '../services/ad_service.dart';
import '../app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;

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
    int earnedScore = provider.score + (100 * stars);

    user.recordLevelComplete(
      levelIndex: provider.currentLevel,
      scoreEarned: earnedScore,
      starsEarned: stars,
      hintsUsed: provider.hintsUsedInLevel,
      isDaily: provider.isDailyChallenge,
      isCustom: provider.isCustomPuzzle,
    );

    if (provider.isDailyChallenge) {
      user.completeDailyChallenge();
    }
  }

  void _setupCallbacks(GameProvider provider, UserProvider user) {
    provider.onWordFoundCallback = () {
      user.addWordFound();
    };
    provider.onBonusWordCallback = (word) {
      final rewarded = user.addBonusWord();
      if (rewarded) {
        provider.showFeedback('JAR FULL  +1 HINT', durationMs: 1800);
      }
    };
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

  HexCell? _findClosestCell(Offset local, GameProvider provider, double hexW, double hexH, double offsetX, double offsetY) {
    if (provider.engine == null) return null;

    double closestDist = double.infinity;
    HexCell? closest;

    for (int q = 0; q < provider.engine!.cols; q++) {
      for (int r = 0; r < provider.engine!.rows; r++) {
        double cx = offsetX + q * (hexW * 0.75) + hexW / 2;
        double cy = offsetY + r * hexH + (q.isOdd ? hexH / 2 : 0) + hexH / 2;
        double dist = pow(cx - local.dx, 2).toDouble() + pow(cy - local.dy, 2).toDouble();
        if (dist < closestDist) {
          closestDist = dist;
          closest = provider.engine!.grid[q][r];
        }
      }
    }

    if (closest != null && closestDist < pow(hexW * 0.45, 2)) {
      return closest;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Deep Forest / Dusk Village Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3C36), // Deep forest green
                  Color(0xFF2C4A42), // Rich woodland
                  Color(0xFF192A25), // Dark shadow green
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Custom Ambient Particles
          const Positioned.fill(
            child: FireflyParticles(),
          ),
          
          // Magic background glows
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF7CB342).withValues(alpha: 0.15), 
                shape: BoxShape.circle
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.2, duration: 4.seconds),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 5.seconds),
          ),
          
          Consumer<GameProvider>(
            builder: (context, provider, child) => BackdropFilter(
              filter: import_ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                color: Colors.black.withValues(alpha: provider.isLevelComplete ? 0.75 : 0.2),
              ),
            ),
          ),

          SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading || provider.engine == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
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

  Widget _buildLevelComplete(GameProvider provider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!provider.levelProgressSaved) {
      _saveCurrentLevelProgress(provider, userProvider);
    }

    int stars = provider.calculateStars();
    int wordScore = provider.score;
    int starBonus = 100 * stars;
    int totalScore = wordScore + starBonus;
    int brainEarned = 50 * stars;
    int coinsEarned = 10 * stars;
    
    int newStreak = 0;
    if (provider.isDailyChallenge) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String today = DateTime.now().toIso8601String().substring(0, 10);
      if (userProvider.lastPlayedDate != null) {
        DateTime lastPlayed = DateTime.parse(userProvider.lastPlayedDate!);
        DateTime current = DateTime.parse(today);
        int difference = current.difference(lastPlayed).inDays;
        
        if (difference == 1) {
          newStreak = userProvider.currentStreak + 1;
        } else if (difference > 1) {
          newStreak = 1;
        } else {
          newStreak = userProvider.currentStreak; // Already played? Should not happen
        }
      } else {
        newStreak = 1; // First time
      }

      if (newStreak > 30) {
        newStreak = 1;
      }
    }

    return Center(
      child: RepaintBoundary(
        key: _shareKey,
        child: Container(
          color: const Color(0xFF1B2620), // Dark tavern background
          child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Stars - HUGE and CHUNKY
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 24.0 : 0.0),
                    child: Icon(
                      Icons.star_rounded,
                      color: i < stars ? const Color(0xFFFFD54F) : const Color(0xFF3E2723), // Golden vs Dark Wood
                      size: i == 1 ? 80 : 64,
                      shadows: [
                        if (i < stars) const Shadow(color: Color(0xFFFFB74D), blurRadius: 20),
                        const Shadow(color: Colors.black54, offset: Offset(0, 6), blurRadius: 0), // Chunky shadow
                        const Shadow(color: Colors.white24, offset: Offset(0, 2), blurRadius: 0), // Bevel
                      ],
                    )
                    .animate(delay: (200 + i * 200).ms)
                    .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                    .rotate(begin: -0.2, end: 0, curve: Curves.easeOut),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              provider.isDailyChallenge ? 'DAILY CHALLENGE' : 'LEVEL ${provider.currentLevel}',
              style: const TextStyle(
                color: Color(0xFFFFD54F), 
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 4,
                shadows: [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]
              ),
            ).animate().slideY(begin: 1.0).fadeIn(delay: 200.ms),
            
            const Text(
              'COMPLETE!',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 44, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Color(0xFFFFB74D), blurRadius: 25), // Huge glow
                  Shadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 0), // Chunky 3D drop
                ]
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms, delay: 400.ms),

            const SizedBox(height: 32),

            // Score Breakdown Card (Warm Parchment/Wood)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // Warm Parchment
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFD4A373), width: 4),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _buildScoreRow('Words Found', '${provider.foundWords.length}', Icons.text_fields_rounded, const Color(0xFF7CB342)),
                  if (provider.bonusWordsFound > 0) ...[
                    const SizedBox(height: 12),
                    _buildScoreRow('Bonus Words', '${provider.bonusWordsFound}', Icons.flare_rounded, const Color(0xFFFFB74D)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: provider.bonusWordsList.map((w) => _buildBonusWordChip(w, compact: true)).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildScoreRow('Word Score', '+$wordScore', Icons.abc_rounded, const Color(0xFF4DB6AC)),
                  const SizedBox(height: 12),
                  _buildScoreRow('Star Bonus', '+$starBonus', Icons.star_rounded, const Color(0xFFFFB74D)),
                  const SizedBox(height: 12),
                  _buildScoreRow('Brain Growth', '+${brainEarned}cc', Icons.psychology_rounded, const Color(0xFFE57373)),
                  const SizedBox(height: 12),
                  _buildScoreRow('Coins Earned', '+$coinsEarned', Icons.monetization_on_rounded, const Color(0xFFFFB74D)),
                  if (provider.hintsUsedInLevel > 0) ...[
                    const SizedBox(height: 12),
                    _buildScoreRow('Hints Used', '${provider.hintsUsedInLevel}', Icons.lightbulb_outline_rounded, const Color(0xFFD4A373)),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Divider(color: Color(0xFFD4A373), thickness: 2),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      Text('+$totalScore', style: const TextStyle(color: Color(0xFF3E2723), fontSize: 32, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            )
            .animate(delay: 800.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOut),

            const SizedBox(height: 20),
            _buildSocialProof(provider),
            const SizedBox(height: 24),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildControlButton(
                      icon: Icons.play_arrow_rounded,
                      label: provider.isCustomPuzzle ? 'FINISH' : (provider.isDailyChallenge ? 'CLAIM REWARD' : 'NEXT LEVEL'),
                      highlight: true, // Use the vibrant moss green AAA button!
                      onTap: () {
                        var user = Provider.of<UserProvider>(context, listen: false);

                        void proceed() {
                          if (provider.isDailyChallenge || provider.isCustomPuzzle) {
                            Navigator.pop(context);
                          } else {
                            provider.nextLevel();
                          }
                        }

                        if (!user.adsRemoved && !provider.isDailyChallenge && !provider.isCustomPuzzle && provider.currentLevel % 3 == 0) {
                          AdService.showInterstitialAd(proceed);
                        } else {
                          proceed();
                        }
                      },
                    )
                    .animate(delay: 1000.ms).scale(curve: Curves.elasticOut, duration: 600.ms),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildControlButton(
                      icon: Icons.share_rounded,
                      label: 'SHARE',
                      color: const Color(0xFF4DB6AC), // Teal
                      onTap: () async {
                        if (_isSharing) return;
                        setState(() => _isSharing = true);
                        try {
                          RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                          import_ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                          var byteData = await image.toByteData(format: import_ui.ImageByteFormat.png);
                          if (byteData != null) {
                            final directory = await getTemporaryDirectory();
                            final file = File('${directory.path}/score_share.png');
                            await file.writeAsBytes(byteData.buffer.asUint8List());

                            String title = provider.isDailyChallenge
                                ? 'Word Haven Daily Challenge'
                                : (provider.isCustomPuzzle ? 'Custom Puzzle' : 'Level ${provider.currentLevel}');
                            await SharePlus.instance.share(ShareParams(
                              files: [XFile(file.path)],
                              text: 'I just beat $title with $stars/3 stars and a score of ${provider.score}! Download Word Haven: Cozy Village!',
                            ));
                          }
                        } catch (e) {
                          debugPrint('Error sharing image: $e');
                        } finally {
                          if (mounted) setState(() => _isSharing = false);
                        }
                      },
                    )
                    .animate(delay: 1100.ms).scale(curve: Curves.elasticOut, duration: 600.ms),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: Color(0xFF5D4037), fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        Text(value, style: const TextStyle(color: Color(0xFF3E2723), fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSocialProof(GameProvider provider) {
    return const SizedBox.shrink();
  }

  Widget _buildGameUI(GameProvider provider) {
    bool isFever = provider.comboCount > 2;
    
    return AnimatedContainer(
      duration: 300.ms,
      decoration: BoxDecoration(
        color: isFever ? const Color(0xFFFFD700).withValues(alpha: 0.05) : Colors.transparent,
        boxShadow: isFever ? [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
            blurRadius: 50,
            spreadRadius: 10,
          )
        ] : [],
      ),
      child: Stack(
        children: [
          // Fever particles or vignette
          if (isFever)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.transparent, const Color(0xFFFFD700).withValues(alpha: 0.15)],
                    radius: 1.5,
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 500.ms, begin: 0.5, end: 1.0),
            ),
          
          Column(
            children: [
              // Top bar
              _buildTopBar(provider, context),

              const SizedBox(height: 8),

              // Current word display
              _buildCurrentWordDisplay(provider),

              const SizedBox(height: 8),

              // Hexagonal grid
              Expanded(
                child: _buildHexGrid(provider),
              ),

              // Word list
              _buildWordList(provider),

              // Bonus words (kept separate from the target words)
              _buildBonusStrip(provider),

              // Bottom controls
              _buildBottomControls(provider, context),

              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(GameProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isDailyChallenge 
                            ? 'DAILY CHALLENGE' 
                            : (provider.isCustomPuzzle ? 'CUSTOM PUZZLE' : 'LEVEL ${provider.currentLevel}'),
                        style: const TextStyle(
                          color: Color(0xFFF2C94C),
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!provider.isDailyChallenge && !provider.isCustomPuzzle)
                        Text(
                          provider.currentTheme.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3E2723), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF2C94C), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
                onPressed: () => _showPauseMenu(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWordDisplay(GameProvider provider) {
    bool hasCombo = provider.comboCount > 1;
    
    // Calculate dots count from the shortest remaining word
    int dotCount = 3; // fallback
    if (provider.remainingWords.isNotEmpty) {
      dotCount = provider.remainingWords.map((w) => w.length).reduce((a, b) => a < b ? a : b);
    }
    String dotsPlaceholder = List.generate(dotCount, (_) => '●').join('  ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Warm Parchment
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasCombo ? const Color(0xFFFFB74D).withValues(alpha: 0.6) : Colors.black26,
            blurRadius: hasCombo ? 15 : 6,
            spreadRadius: hasCombo ? 2 : 0,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: hasCombo
              ? const Color(0xFFFFB74D)
              : const Color(0xFFD4A373),
          width: 3,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
          ),
          child: provider.feedbackMessage != null
              ? _buildFeedbackPill(provider.feedbackMessage!)
              : Row(
          key: const ValueKey('word_row'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasCombo) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.comboCount}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              provider.currentWord.isEmpty ? dotsPlaceholder : provider.currentWord,
              style: TextStyle(
                color: provider.currentWord.isEmpty
                    ? const Color(0xFFD4A373).withValues(alpha: 0.8)
                    : const Color(0xFF5D4037), // Dark brown ink
                fontSize: provider.currentWord.isEmpty ? 16 : 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPill(String message) {
    final bool isBonus = message.startsWith('BONUS');
    final bool isReward = message.contains('HINT');
    final Color bg = isReward
        ? const Color(0xFF87A8A4)
        : (isBonus ? const Color(0xFFF2C94C) : const Color(0xFFE8E3D2));
    final Color fg = (isBonus || isReward) ? Colors.white : const Color(0xFF6B7A75);
    return Container(
      key: ValueKey('feedback_$message'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReward ? Icons.lightbulb_rounded : (isBonus ? Icons.star_rounded : Icons.info_outline_rounded),
            color: fg,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ],
      ),
    )
    .animate(key: ValueKey('feedback_$message'))
    .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 700.ms)
    .fadeIn(duration: 300.ms)
    .then(delay: 200.ms)
    .shake(hz: 4, duration: 400.ms);
  }

  Widget _buildHexGrid(GameProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = provider.engine!.cols;
        int rows = provider.engine!.rows;

        double availW = constraints.maxWidth - 20; // Reduced side padding to allow wider grid
        double availH = constraints.maxHeight; // Maximize available height

        // Calculate hex size to fit within available space
        double hexW = availW / (1 + (cols - 1) * 0.75);
        double hexH = hexW * (sqrt(3) / 2);

        // Check if height fits
        double totalH = hexH * rows + hexH * 0.5;
        if (totalH > availH) {
          hexH = availH / (rows + 0.5);
          hexW = hexH / (sqrt(3) / 2);
        }

        double boardW = hexW * (1 + (cols - 1) * 0.75);
        double boardH = hexH * rows + hexH * 0.5;

        double offsetX = (constraints.maxWidth - boardW) / 2;
        double offsetY = (constraints.maxHeight - boardH) / 2;

        return GestureDetector(
          onPanStart: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset local = box.globalToLocal(details.globalPosition);
            var cell = _findClosestCell(local, provider, hexW, hexH, offsetX, offsetY);
            if (cell != null) provider.selectCell(cell.q, cell.r);
          },
          onPanUpdate: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset local = box.globalToLocal(details.globalPosition);
            var cell = _findClosestCell(local, provider, hexW, hexH, offsetX, offsetY);
            if (cell != null) provider.selectCell(cell.q, cell.r);
          },
          onPanEnd: (_) {
            provider.endSelection();
          },
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: SwipeTrailPainter(
                    provider.selectedCells.map((cell) {
                      double cx = offsetX + cell.q * (hexW * 0.75) + hexW / 2;
                      double cy = offsetY + cell.r * hexH + (cell.q.isOdd ? hexH / 2 : 0) + hexH / 2;
                      return Offset(cx, cy);
                    }).toList(),
                    provider.comboCount > 2,
                  ),
                ),
                for (int q = 0; q < cols; q++)
                  for (int r = 0; r < rows; r++)
                    _buildHexTile(provider, q, r, hexW, hexH, offsetX, offsetY),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHexTile(GameProvider provider, int q, int r, double hexW, double hexH, double offsetX, double offsetY) {
    HexCell cell = provider.engine!.grid[q][r];
    if (cell.letter == ' ') return const SizedBox.shrink();

    bool isSelected = provider.selectedCells.any((c) => c.q == q && c.r == r);
    bool wasSelected = provider.lastSelectedCells.any((c) => c.q == q && c.r == r);
    bool isFound = cell.isFound && !wasSelected; // Delay hiding if it's animating success

    if (isFound) return const SizedBox.shrink();

    double left = offsetX + q * (hexW * 0.75);
    double top = offsetY + r * hexH + (q.isOdd ? hexH / 2 : 0);

    Color tileColor;
    Color textColor;
    double scale = 1.0;

    if (wasSelected && provider.lastWordStatus == WordStatus.correct) {
      tileColor = const Color(0xFF558B2F); // Richer Forest Green
      textColor = Colors.white;
      scale = 1.3; // Pop outwards!
    } else if (wasSelected && provider.lastWordStatus == WordStatus.wrong) {
      tileColor = const Color(0xFFE57373); // Muted Red
      textColor = Colors.white;
    } else if (wasSelected && provider.lastWordStatus == WordStatus.partial) {
      tileColor = const Color(0xFFFFB74D); // Amber
      textColor = const Color(0xFF4E342E);
    } else if (wasSelected && provider.lastWordStatus == WordStatus.bonus) {
      tileColor = const Color(0xFFFFD54F); // Gold
      textColor = const Color(0xFF4E342E);
      scale = 1.15;
    } else if (wasSelected && provider.lastWordStatus == WordStatus.alreadyFound) {
      tileColor = const Color(0xFFBCAAA4); // Pale grey wood
      textColor = const Color(0xFF4E342E);
    } else if (isSelected) {
      bool isFever = provider.comboCount > 2;
      tileColor = isFever ? const Color(0xFFFFD54F) : const Color(0xFFE2C4A2); // Warm peach/gold select
      textColor = const Color(0xFF3E2723);
      scale = 1.12;
    } else if (cell.isHinted) {
      tileColor = const Color(0xFFFFF59D); // Glowing hint
      textColor = const Color(0xFF3E2723);
    } else {
      tileColor = const Color(0xFFD2A679); // Rich Oak Wood
      textColor = const Color(0xFF4E342E); // Dark burned ink
    }

    double padding = 8.0; // Increased padding to separate tiles more

    return Positioned(
      left: left + padding / 2,
      top: top + padding / 2,
      width: hexW - padding,
      height: hexH - padding,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: (wasSelected && provider.lastWordStatus == WordStatus.wrong) ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(sin(value * pi * 4) * 6, 0),
            child: child,
          );
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                PhysicalShape(
                  clipper: HexagonClipper(),
                  color: tileColor,
                  elevation: isSelected ? 8.0 : 4.0,
                  shadowColor: isSelected ? tileColor : Colors.black87,
                  child: ClipPath(
                    clipper: HexagonClipper(), // CRITICAL: This clips the gradient square artifact!
                    child: Container(
                      width: hexW - padding,
                      height: hexH - padding,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35), // Glossy top highlight/varnish
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15), // Subtle dark bottom shadow
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          final slideAnim = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.bounceOut));
                          return SlideTransition(position: slideAnim, child: child);
                        },
                        child: Text(
                          cell.letter,
                          key: ValueKey('${cell.letter}_${cell.version}'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: (hexH - padding) * 0.40, // Slightly larger text
                            fontWeight: FontWeight.w900, // Extra bold
                            shadows: [
                              Shadow(color: Colors.white.withValues(alpha: 0.4), offset: const Offset(0, 1.5)) // Deboss/Engrave effect
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(hexW - padding, hexH - padding),
                  painter: HexagonBorderPainter(
                    borderColor: isSelected 
                        ? Colors.white.withValues(alpha: 0.8)
                        : (cell.isHinted 
                            ? const Color(0xFFFFD54F) 
                            : const Color(0xFF5D4037)), // Dark wood edge
                    borderWidth: isSelected ? 3.0 : 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList(GameProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), // Reduced margin
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037).withValues(alpha: 0.7), // Semi-transparent dark wood
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4E342E).withValues(alpha: 0.5), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          ...provider.foundWords.map((word) => _buildWordChip(word, true)),
          ...provider.remainingWords.map((word) => _buildWordChip(word, false)),
        ],
      ),
    );
  }

  /// Separate strip for bonus words + Bonus Jar progress (5 bonus words = 1 free hint).
  Widget _buildBonusStrip(GameProvider provider) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        final double progress = user.bonusJar / UserProvider.bonusJarTarget;
        return Container(
          height: 40,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              // Jar progress badge
              Tooltip(
                message: 'Find ${UserProvider.bonusJarTarget} bonus words to earn a free hint',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0), // Warm Parchment
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4A373), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => CircularProgressIndicator(
                                value: value,
                                strokeWidth: 3,
                                backgroundColor: const Color(0xFFFFB74D).withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB74D)),
                              ),
                            ),
                            const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB74D)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BONUS ${user.bonusJar}/${UserProvider.bonusJarTarget}',
                        style: const TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bonus words found in this level
              Expanded(
                child: provider.bonusWordsList.isEmpty
                    ? const Text(
                        'Find extra words for bonus points',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFFA9B5B0), fontSize: 12, fontWeight: FontWeight.w600),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        // index 0 = newest word, shown right beside the badge
                        itemCount: provider.bonusWordsList.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final word = provider.bonusWordsList[provider.bonusWordsList.length - 1 - i];
                          return Center(
                            child: _buildBonusWordChip(word, compact: true)
                                .animate(key: ValueKey('bonus_$word'))
                                .scale(begin: const Offset(0.6, 0.6), duration: 350.ms, curve: Curves.elasticOut),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordChip(String word, bool found) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Reduced vertical padding
      decoration: BoxDecoration(
        color: found ? const Color(0xFF7CB342) : const Color(0xFF3E2723).withValues(alpha: 0.8), // Moss Green found, Dark inset missing
        borderRadius: BorderRadius.circular(12),
        boxShadow: found
            ? const [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 4)),
                BoxShadow(color: Colors.white30, offset: Offset(0, 2), spreadRadius: -2) // Top bevel
              ]
            : const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3), spreadRadius: -2)], // Inner shadow
        border: Border.all(
          color: found ? const Color(0xFF558B2F) : const Color(0xFF2D1A11),
          width: found ? 2 : 1.5,
        ),
      ),
      child: Text(
        found ? word : word.replaceAll(RegExp(r'.'), '_ ').trim(),
        style: TextStyle(
          color: found ? Colors.white : const Color(0xFF8D6E63),
          fontSize: found ? 16 : 18,
          fontWeight: found ? FontWeight.w800 : FontWeight.w900,
          letterSpacing: found ? 2 : 4,
        ),
      ),
    );
    
    if (found) {
      return chip.animate(key: ValueKey('found_$word'))
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut, duration: 800.ms)
        .shimmer(delay: 200.ms, duration: 1200.ms, color: Colors.white54)
        .then()
        .shake(hz: 2, duration: 300.ms); // A tiny settling shake
    }
    
    return chip;
  }

  Widget _buildBonusWordChip(String word, {bool compact = false}) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2C94C), // Glowing Golden Yellow
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        boxShadow: [BoxShadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.4), blurRadius: compact ? 6 : 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: compact ? 13 : 18),
          const SizedBox(width: 4),
          Text(
            word,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 16,
              fontWeight: FontWeight.w900,
              letterSpacing: compact ? 1.5 : 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(GameProvider provider, BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle button
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.shuffle_rounded,
                      label: 'Shuffle',
                      onTap: () {
                        if (provider.isLevelComplete) return;
                        provider.shuffleBoard();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Hint button
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.lightbulb_rounded,
                      label: 'Hint (${user.hintsRegular})',
                      highlight: true,
                      onTap: () {
                        if (user.hintsRegular > 0) {
                          if (provider.applyHint()) {
                            user.useHint(); // consume the hint
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No more hints needed!'), behavior: SnackBarBehavior.floating));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of hints! Get more at the Store.'), behavior: SnackBarBehavior.floating));
                          Navigator.pushNamed(context, AppRouter.store);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.star_rounded,
                      label: 'Mega (${user.hintsMega})',
                      color: const Color(0xFFFFD700),
                      onTap: () {
                        if (user.hintsMega > 0) {
                          if (provider.applyMegaHint()) {
                            user.useMegaHint(); // consume the hint
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No more mega hints needed!'), behavior: SnackBarBehavior.floating));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of mega hints! Get more at the Store.'), behavior: SnackBarBehavior.floating));
                          Navigator.pushNamed(context, AppRouter.store);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.diamond_rounded,
                      label: 'Ultra (${user.hintsUltra})',
                      color: const Color(0xFF00D4FF),
                      onTap: () {
                        if (user.hintsUltra > 0) {
                          if (provider.applyUltraHint()) {
                            user.useUltraHint(); // consume the hint
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No more ultra hints needed!'), behavior: SnackBarBehavior.floating));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of ultra hints! Get more at the Store.'), behavior: SnackBarBehavior.floating));
                          Navigator.pushNamed(context, AppRouter.store);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool highlight = false,
    Color? color,
    required VoidCallback onTap,
  }) {
    // Warm tactile wood colors based on button type
    Color baseColor;
    if (highlight) {
      baseColor = const Color(0xFF7CB342); // Moss green
    } else if (color == const Color(0xFFFFD700)) {
      baseColor = const Color(0xFFFFB74D); // Orange for Mega
    } else if (color == const Color(0xFF00D4FF)) {
      baseColor = const Color(0xFF4DB6AC); // Teal for Ultra
    } else {
      baseColor = const Color(0xFFE2C4A2); // Light wood for Shuffle
    }
    
    Color darkColor = _darken(baseColor, 20);
    Color lightColor = _lighten(baseColor, 30);
    Color textColor = (highlight || baseColor == const Color(0xFF4DB6AC)) ? Colors.white : const Color(0xFF3E2723);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Reduced vertical padding to save height
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: darkColor.withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(0, 6)), // Hard 3D chunky shadow
            const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 8)), // Soft drop shadow
          ],
          border: Border.all(color: lightColor, width: 2), // Top bevel highlight
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 1.5), blurRadius: 0)], // Crisp text shadow
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color c, [int percent = 30]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
        c.a.toInt(), (c.r * f).round(), (c.g * f).round(), (c.b * f).round());
  }

  Color _lighten(Color c, [int percent = 30]) {
    assert(1 <= percent && percent <= 100);
    var p = percent / 100;
    return Color.fromARGB(
        c.a.toInt(),
        c.r.toInt() + ((255 - c.r) * p).round(),
        c.g.toInt() + ((255 - c.g) * p).round(),
        c.b.toInt() + ((255 - c.b) * p).round());
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
              color: const Color(0xFFFDF5E6), // Parchment
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF8B5A2B), width: 4), // Thick wood border
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAUSED',
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 32,
                    color: const Color(0xFF5D4037),
                    letterSpacing: 2,
                    shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
                  ),
                ),
                const SizedBox(height: 32),
                _buildMenuButton('RESUME', const Color(0xFF7CB342), () {
                  Navigator.pop(context);
                }),
                const SizedBox(height: 16),
                _buildMenuButton('RESTART', const Color(0xFFF2C94C), () {
                  if (provider.isDailyChallenge) {
                    provider.startDailyChallenge();
                  } else if (provider.isCustomPuzzle && provider.engine != null) {
                    provider.startCustomLevel(provider.engine!.words);
                  } else {
                    provider.startSpecificLevel(provider.currentLevel);
                  }
                  Navigator.pop(context);
                }, textColor: const Color(0xFF5D4037)),
                const SizedBox(height: 16),
                _buildMenuButton('QUIT', const Color(0xFFE53935), () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close GameScreen
                }),
              ],
            ),
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildMenuButton(String text, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 0)],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              color: textColor,
              fontSize: 22,
              letterSpacing: 1.5,
              shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Flat-topped hexagon
    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HexagonBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  
  HexagonBorderPainter({required this.borderColor, this.borderWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexagonBorderPainter old) => 
      old.borderColor != borderColor || old.borderWidth != borderWidth;
}

class SwipeTrailPainter extends CustomPainter {
  final List<Offset> points;
  final bool isFever;

  SwipeTrailPainter(this.points, this.isFever);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = isFever ? const Color(0xFFFFD700) : const Color(0xFF00D4FF)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SwipeTrailPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isFever != isFever;
  }
}

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
    
    // Slight meandering
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
      // Pulsing opacity
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

