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

import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import 'game/board_view.dart';
import 'game/number_tray.dart';
import 'game/game_toolbar.dart';
import 'game/hint_bubble.dart';

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
    int earnedScore = provider.score;

    user.recordLevelComplete(
      levelIndex: provider.currentLevel,
      scoreEarned: earnedScore,
      starsEarned: stars,
      hintsUsed: provider.hintsUsedInLevel,
      isDaily: provider.isDailyChallenge,
      isCustom: provider.isCustomPuzzle,
    );

    final eqCount = provider.currentPuzzle?.equations.length ?? 3;
    for (int i = 0; i < eqCount; i++) {
      user.addWordFound();
    }

    if (provider.isDailyChallenge) {
      user.completeDailyChallenge();
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
          // Deep Forest / Dusk Village Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F1E28), // Deep slate dusk
                  Color(0xFF1B2E3C), // Cozy rich twilight
                  Color(0xFF11222D), // Dark grounding shadow
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Custom Ambient Particles
          const Positioned.fill(
            child: FireflyParticles(),
          ),

          // Ambient Background Glows
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.2, duration: 4.seconds),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
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
                if (provider.isLoading || provider.currentPuzzle == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
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
    return Column(
      children: [
        // 1. Top Bar
        _buildTopBar(provider, context),

        // 2. Feedback Pill
        if (provider.feedbackMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _buildFeedbackPill(provider.feedbackMessage!),
          ),

        // 3. Central Interactive Crossword Board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: MathBoardView(provider: provider),
          ),
        ),

        // 4. Floating Smart Hint bubble (if active)
        MathHintBubble(provider: provider),

        // 5. Candidate Number Tray
        MathNumberTray(provider: provider),

        // 6. Action Toolbar (Undo, Erase, Notes, Hint)
        MathGameToolbar(provider: provider),

        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildTopBar(GameProvider provider, BuildContext context) {
    final puzzle = provider.currentPuzzle;
    final diffName = puzzle?.difficulty.displayName.toUpperCase() ?? 'EASY';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isDailyChallenge
                        ? 'DAILY CHALLENGE'
                        : (provider.isCustomPuzzle
                            ? 'CUSTOM PUZZLE'
                            : 'LEVEL ${provider.currentLevel}'),
                    style: const TextStyle(
                      color: Color(0xFFF2C94C),
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    diffName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF475569), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF2C94C), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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

  Widget _buildFeedbackPill(String message) {
    return Container(
      key: ValueKey('feedback_$message'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey('feedback_$message'))
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 500.ms)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildLevelComplete(GameProvider provider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!provider.levelProgressSaved) {
      _saveCurrentLevelProgress(provider, userProvider);
    }

    int stars = provider.calculateStars();
    int baseScore = provider.score;
    int starBonus = 100 * stars;
    int totalScore = baseScore + starBonus;
    int brainEarned = 50 * stars;
    int coinsEarned = 10 * stars;

    return Center(
      child: RepaintBoundary(
        key: _shareKey,
        child: Container(
          color: const Color(0xFF0F1E28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // Stars
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

                const SizedBox(height: 18),

                // Title
                Text(
                  provider.isDailyChallenge ? 'DAILY CHALLENGE' : 'LEVEL ${provider.currentLevel}',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ).animate().slideY(begin: 1.0).fadeIn(delay: 200.ms),

                const Text(
                  'SOLVED!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Color(0xFF10B981), blurRadius: 20),
                      Shadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms, delay: 400.ms),

                const SizedBox(height: 28),

                // Score Breakdown Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF334155), width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))
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
                        '+${brainEarned}cc',
                        Icons.psychology_rounded,
                        const Color(0xFFA78BFA),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreRow(
                        'Coins Earned',
                        '+$coinsEarned',
                        Icons.monetization_on_rounded,
                        const Color(0xFFF59E0B),
                      ),
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
                        child: Divider(color: Color(0xFF475569), thickness: 1.5),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '+$totalScore',
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 28),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          onTap: () {
                            var user = Provider.of<UserProvider>(context, listen: false);

                            void proceed() {
                              if (provider.isDailyChallenge || provider.isCustomPuzzle) {
                                Navigator.pop(context);
                              } else {
                                provider.nextLevel();
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

                const SizedBox(height: 36),
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
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
    Color? color,
  }) {
    final btnColor = highlight ? const Color(0xFF10B981) : (color ?? const Color(0xFF334155));

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
              color: btnColor.withValues(alpha: 0.35),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF475569), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAUSED',
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 30,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
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
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack);
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Ambient Particles
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
