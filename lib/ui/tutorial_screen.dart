import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_router.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 6;

  void _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_tutorial', true);
        if (!didPop && context.mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2816),
      body: Stack(
        children: [
          // 1. LUSH MEADOW BACKGROUND (Sunlit, warm fairy-tale atmosphere)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 2. WARM SUNLIT VIGNETTE (Vibrant, airy morning atmosphere - no muddy darkness!)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2E4D1E).withValues(alpha: 0.38), // Sunlit sky visible
                    const Color(0xFF241A0E).withValues(alpha: 0.58), // Warm golden midday
                    const Color(0xFF140D07).withValues(alpha: 0.88), // Grounded bottom for controls
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. MAIN INTERACTIVE CONTENT
          SafeArea(
            child: Column(
              children: [
                // Top Header (Step Counter Pill, Slide Title & Back/Close Buttons)
                _buildTopHeader(),

                // Slide PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildSlideWelcome(),
                      _buildSlideHexagonSwiping(),
                      _buildSlideTargetWords(),
                      _buildSlideHintsAndTools(),
                      _buildSlideVillageRestoration(),
                      _buildSlideReadyToPlay(),
                    ],
                  ),
                ),

                // Bottom Pagination & Navigation Controls
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // -------------------------------------------------------------
  // TOP HEADER (Clean, elegant, non-repetitive)
  // -------------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(
        children: [
          // Back button (when page > 0)
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C1E14).withValues(alpha: 0.95),
                  border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD54F), size: 20),
              ),
            )
          else
            const SizedBox(width: 38),

          // Center: Step Badge Pill & Slide Title
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1D10).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.8), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'OAKHEART GUIDE • ${_currentPage + 1} / $_totalPages',
                          style: GoogleFonts.lilitaOne(
                            color: const Color(0xFFFFD54F),
                            fontSize: 11,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _getSlideTitle(_currentPage),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFFFF9E6),
                      fontSize: 19,
                      letterSpacing: 1.6,
                      shadows: const [
                        Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cozy Wooden Close (X) Button
          GestureDetector(
            onTap: _finishTutorial,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2C1E14).withValues(alpha: 0.95),
                border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Color(0xFFFFF8E7), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _getSlideTitle(int page) {
    switch (page) {
      case 0:
        return 'WELCOME TO WORD HAVEN!';
      case 1:
        return 'HEXAGONAL WORD SWIPING';
      case 2:
        return 'TARGET WORD BOXES';
      case 3:
        return 'HELPFUL PUZZLE TOOLS';
      case 4:
        return 'RESTORE OAKHEART VILLAGE';
      case 5:
        return 'READY FOR ADVENTURE!';
      default:
        return '';
    }
  }

  // -------------------------------------------------------------
  // SLIDE 0: Welcome to Word Haven! (Mayor Bramble on Left)
  // -------------------------------------------------------------
  Widget _buildSlideWelcome() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Inspiring Oakheart Village Showcase (Cottage + 3D Letter Tile + Coins)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2F1F13), Color(0xFF1E140C)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ribbon: A Cozy Woodland Word Adventure
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF689F38), Color(0xFF558B2F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '✨ A COZY WOODLAND ADVENTURE ✨',
                    style: GoogleFonts.lilitaOne(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Village Cottage + Floating Golden 3D Tile
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cozy Cottage Preview
                    Container(
                      width: 95,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17100B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.7), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/village/meadow/cottage_stage3.webp',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Glowing 3D Wooden Tile "W" with floating coins
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFD54F).withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7CB342),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFE082), width: 2.2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'W',
                            style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 34),
                          ),
                        ),
                        // Orbiting Golden Coin Badge
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFB300),
                            ),
                            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 16),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 1.seconds),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Subtext Tag
                Text(
                  'Solve Word Puzzles • Restore Oakheart Village',
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFFFE082),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Mayor Bramble on Left with Connected Speech Bubble on Right
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/bunny_hd.webp',
            characterOnLeft: true,
            characterWidth: 100,
            characterHeight: 160,
            speaker: 'MAYOR BRAMBLE • VILLAGE GUIDE',
            badgeIcon: Icons.eco_rounded,
            badgeColor: const Color(0xFF4CAF50),
            greetingText: "Hello, traveler! Welcome to Oakheart!",
            bodyText:
                "Solve relaxing word puzzles to collect golden coins, rebuild our cozy village, and bring warmth back to our meadow!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 1: Hexagonal Honeycomb Swiping (Mayor Bramble on Left)
  // -------------------------------------------------------------
  Widget _buildSlideHexagonSwiping() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Interactive Honeycomb Hexagon Grid Showcase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2B1D12), Color(0xFF1B1109)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: const _TutorialHoneycombSwipeDemo(),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Mayor Bramble on Left with Connected Speech Bubble on Right
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/bunny_hd.webp',
            characterOnLeft: true,
            characterWidth: 100,
            characterHeight: 160,
            speaker: 'MAYOR BRAMBLE • PUZZLE RULES',
            badgeIcon: Icons.grid_view_rounded,
            badgeColor: const Color(0xFFFFB300),
            greetingText: "Swipe adjacent hexagon tiles to make words!",
            bodyText:
                "You can connect in all 6 directions: up, down, sideways, and diagonally. Release your finger to submit words!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 2: Target Word Boxes (Fern the Fox on Right)
  // -------------------------------------------------------------
  Widget _buildSlideTargetWords() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Target Word Clue Slots Showcase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C1E12), Color(0xFF1B120A)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Solved Word 1 (COZY)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTargetWordPill(
                      letters: ['C', 'O', 'Z', 'Y'],
                      isSolved: true,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Unsolved Word 2 (HAVEN - 5 letters)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTargetWordPill(
                      letters: ['', '', '', '', ''],
                      isSolved: false,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: Color(0xFFFFD54F), size: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                  ),
                  child: Text(
                    'TARGET WORD LENGTHS: 4 & 5 LETTERS',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFFFD54F),
                      fontSize: 11,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Fern the Fox on Right with Connected Speech Bubble on Left
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/fox_hd.webp',
            characterOnLeft: false,
            characterWidth: 110,
            characterHeight: 160,
            speaker: 'FERN THE FOX • MASTER BAKER',
            badgeIcon: Icons.bakery_dining_rounded,
            badgeColor: const Color(0xFFFF9800),
            greetingText: "Look at the wooden boxes above the board!",
            bodyText:
                "Each box tells you the exact number of letters needed. Find all target words to win the level and collect coins!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 3: Helpful Puzzle Tools (Professor Hoot on Right)
  // -------------------------------------------------------------
  Widget _buildSlideHintsAndTools() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Compact 2x2 Grid of Tactical Power-Up Tokens
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C1D11), Color(0xFF1B1109)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCardMini(
                        icon: Icons.lightbulb_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        title: 'HINT',
                        desc: 'Reveals next letter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToolCardMini(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        title: 'MEGA HINT',
                        desc: 'First & last letters',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCardMini(
                        icon: Icons.diamond_rounded,
                        iconColor: const Color(0xFF00D4FF),
                        title: 'ULTRA HINT',
                        desc: 'Solves entire word',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToolCardMini(
                        icon: Icons.shuffle_rounded,
                        iconColor: const Color(0xFF81C784),
                        title: 'SHUFFLE',
                        desc: 'Mixes board layout',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Professor Hoot on Right with Connected Speech Bubble on Left
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/owl_hd.webp',
            characterOnLeft: false,
            characterWidth: 120,
            characterHeight: 160,
            speaker: 'PROFESSOR HOOT • VILLAGE SCHOLAR',
            badgeIcon: Icons.auto_awesome_rounded,
            badgeColor: const Color(0xFF00E5FF),
            greetingText: "Whenever you're stuck, tap a handy tool!",
            bodyText:
                "Use Hint for the next letter, Mega Hint for first & last letters, or Ultra Hint to solve the entire word. Collect free Hints from the Windmill and Mega Hints from the Tower!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToolCardMini({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B120B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.18),
              border: Border.all(color: iconColor, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 12, letterSpacing: 1.1),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    desc,
                    style: GoogleFonts.baloo2(color: const Color(0xFFD7CCC8), fontSize: 10, height: 1.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 4: Village Restoration & Idle Rewards (Mayor Bramble on Left)
  // -------------------------------------------------------------
  Widget _buildSlideVillageRestoration() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Village Building Restoration Showcase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C1D11), Color(0xFF1B1109)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cottage & Windmill with Floating Idle Reward Bubble
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 85,
                          width: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E140C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/village/meadow/cottage_stage3.webp',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  '+15 COINS',
                                  style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.08, 1.08), duration: 1.seconds),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Windmill Preview
                    Container(
                      height: 85,
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E140C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/village/meadow/windmill_stage3.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Building perks strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22160E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4A373), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildBuildingPerkMini('🏠 Cottage', 'Coins every 3h')),
                      Container(width: 1, height: 22, color: const Color(0xFF5D4037)),
                      Expanded(child: _buildBuildingPerkMini('🌾 Windmill', 'Daily hints')),
                      Container(width: 1, height: 22, color: const Color(0xFF5D4037)),
                      Expanded(child: _buildBuildingPerkMini('🍞 Bakery', 'Sweet idle gold')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Mayor Bramble on Left with Connected Speech Bubble on Right
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/bunny_hd.webp',
            characterOnLeft: true,
            characterWidth: 100,
            characterHeight: 160,
            speaker: 'MAYOR BRAMBLE • VILLAGE ECONOMY',
            badgeIcon: Icons.home_rounded,
            badgeColor: const Color(0xFF8D6E63),
            greetingText: "Invest coins to rebuild Oakheart's buildings!",
            bodyText:
                "Once built, your village produces idle coins and free hints over time for you to collect anytime you visit!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBuildingPerkMini(String title, String desc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: GoogleFonts.lilitaOne(color: const Color(0xFFFFD54F), fontSize: 11),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            desc,
            style: GoogleFonts.baloo2(color: const Color(0xFFE8F2EF), fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SLIDE 5: Bonus Jar & Ready to Begin! (Dual Mascots)
  // -------------------------------------------------------------
  Widget _buildSlideReadyToPlay() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // UPPER STAGE: Bonus Word Jar & Woodland Celebration Showcase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C1D11), Color(0xFF1B1109)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ribbon: HIDDEN BONUS WORDS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                  ),
                  child: Text(
                    '⭐ EXTRA BONUS WORDS ⭐',
                    style: GoogleFonts.lilitaOne(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bonus Word Jar Meter Showcase
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 30),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'BONUS WORD JAR: 4 / 5',
                              style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 14, letterSpacing: 1.2),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Find valid extra words to earn free hints & gold!',
                              style: GoogleFonts.baloo2(color: const Color(0xFFFFE082), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LOWER STAGE: Bramble on Left with Connected Speech Bubble on Right
          _buildCharacterSpeechSection(
            characterAsset: 'assets/images/village/villagers/bunny_hd.webp',
            characterOnLeft: true,
            characterWidth: 100,
            characterHeight: 160,
            speaker: 'OAKHEART MEADOW CALLS',
            badgeIcon: Icons.favorite_rounded,
            badgeColor: const Color(0xFFFF5252),
            greetingText: "You are all set for your cozy adventure!",
            bodyText:
                "Step into Level 1, relax your mind with word puzzles, and make Oakheart Village shine brighter than ever!",
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE CHARACTER + CONNECTED SPEECH BUBBLE COMPONENT
  // (Ground contact shadow + Tail aligned to character's chest/mouth!)
  // -------------------------------------------------------------
  Widget _buildCharacterSpeechSection({
    required String characterAsset,
    required bool characterOnLeft,
    required double characterWidth,
    required double characterHeight,
    required String speaker,
    required IconData badgeIcon,
    required Color badgeColor,
    required String greetingText,
    required String bodyText,
  }) {
    // 1. Character Avatar with Ground Contact Shadow (No more floating!)
    final characterWidget = SizedBox(
      width: characterWidth,
      height: characterHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Ground contact shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: characterWidth * 0.72,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(characterWidth * 0.72, 12)),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Character Image bobbing gently above the shadow
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Image.asset(
              characterAsset,
              fit: BoxFit.contain,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -5, duration: 1.8.seconds, curve: Curves.easeInOut),
          ),
        ],
      ),
    );

    // 2. Connected Warm Parchment Speech Bubble with top-aligned tail
    final speechBubble = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9EA),
              Color(0xFFFFF0D4),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC89666), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker Tag with leaf & badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2211),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      speaker,
                      style: GoogleFonts.lilitaOne(
                        color: const Color(0xFFFFD54F),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Snappy Hook / Greeting
            Text(
              greetingText,
              style: GoogleFonts.baloo2(
                color: const Color(0xFF2E1708),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 3),

            // Concise Actionable Body
            Text(
              bodyText,
              style: GoogleFonts.baloo2(
                color: const Color(0xFF4A311D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );

    // 3. Speech Tail Pointer positioned at CHEST/MOUTH height (not at the boots!)
    final speechTail = Padding(
      padding: const EdgeInsets.only(top: 40.0), // Aligned right with character's mouth/chest!
      child: CustomPaint(
        size: const Size(10, 16),
        painter: _SpeechBubbleTailPainter(
          pointsToLeft: characterOnLeft,
          fillColor: const Color(0xFFFFF9EA),
          borderColor: const Color(0xFFC89666),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Top alignment so tail points at mouth/chest!
        children: characterOnLeft
            ? [
                characterWidget,
                speechTail,
                speechBubble,
              ]
            : [
                speechBubble,
                speechTail,
                characterWidget,
              ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE SLIDE SCROLL WRAPPER (Tight, cohesive vertical layout)
  // -------------------------------------------------------------
  Widget _buildSlideWrapper({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // TARGET BOX COMPONENTS
  // -------------------------------------------------------------

  Widget _buildTargetWordPill({
    required List<String> letters,
    required bool isSolved,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: letters.map((l) {
        final bool hasLetter = l.isNotEmpty;
        return Container(
          width: 28,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: hasLetter ? const Color(0xFFFFF9E6) : const Color(0xFF1B120B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSolved
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFF8D6E63).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: hasLetter
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            l,
            style: GoogleFonts.lilitaOne(
              color: const Color(0xFF3E2723),
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM CONTROLS & UNIFIED PRIMARY CTA IN THUMB ZONE
  // -------------------------------------------------------------
  Widget _buildBottomControls() {
    final bool isLastPage = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: isLastPage
          ? // FINAL SLIDE: Glorious Primary Call-To-Action in Natural Thumb Zone!
          Row(
              children: [
                // Back button
                TextButton(
                  onPressed: _previousPage,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'BACK',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFD7CCC8),
                      fontSize: 14,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Grand Glowing CTA Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _finishTutorial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF558B2F),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF7CB342).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: const BorderSide(color: Color(0xFFFFD54F), width: 2.2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFD54F), size: 26),
                            const SizedBox(width: 8),
                            Text(
                              'START YOUR JOURNEY',
                              style: GoogleFonts.lilitaOne(
                                fontSize: 17,
                                letterSpacing: 1.8,
                                color: const Color(0xFFFFFDF5),
                                shadows: const [
                                  Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOutBack),
                ),
              ],
            )
          : // REGULAR SLIDES: Skip, Warm Dots, Next
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: SKIP Button
                TextButton(
                  onPressed: _finishTutorial,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(
                    'SKIP',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFD7CCC8),
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // Center: Warm Dots Indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_totalPages, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                              )
                            : null,
                        color: isActive ? null : const Color(0xFF4E342E),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive ? const Color(0xFFFFE082) : Colors.black26,
                          width: 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                // Right: NEXT Button
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF3E2723),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFFFF9C4), width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NEXT',
                        style: GoogleFonts.lilitaOne(
                          fontSize: 14,
                          letterSpacing: 1.4,
                          color: const Color(0xFF2E1C0C),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF2E1C0C),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// FLAT-TOPPED HEXAGON CLIPPER & BORDER PAINTER
// -------------------------------------------------------------
class _TutorialHexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Flat-topped hexagon matching game_screen.dart
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

class _TutorialHexagonBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  _TutorialHexagonBorderPainter({required this.borderColor, this.borderWidth = 2.5});

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
  bool shouldRepaint(covariant _TutorialHexagonBorderPainter old) =>
      old.borderColor != borderColor || old.borderWidth != borderWidth;
}

// -------------------------------------------------------------
// DYNAMIC HONEYCOMB SWIPE DEMO WIDGET (Slide 2)
// Demonstrates word selection step-by-step: C -> O -> Z -> Y
// -------------------------------------------------------------
class _TutorialHoneycombSwipeDemo extends StatefulWidget {
  const _TutorialHoneycombSwipeDemo();

  @override
  State<_TutorialHoneycombSwipeDemo> createState() => _TutorialHoneycombSwipeDemoState();
}

class _TutorialHoneycombSwipeDemoState extends State<_TutorialHoneycombSwipeDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _boardWidth = 260.0;
  static const double _boardHeight = 152.0;
  static const double _hexW = 46.0;
  static const double _hexH = 40.0;

  // Honeycomb tile centers:
  // Center is (130, 76)
  static const Offset _pC = Offset(130 - 46, 76 - 27); // (84, 49)
  static const Offset _pO = Offset(130, 76);           // (130, 76)
  static const Offset _pZ = Offset(130 + 46, 76 - 27); // (176, 49)
  static const Offset _pY = Offset(130 + 46, 76 + 27); // (176, 103)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        Offset fingerPos;
        int reachedIndex;
        bool tileCLit = false;
        bool tileOLit = false;
        bool tileZLit = false;
        bool tileYLit = false;
        String wordText = 'C';
        bool isComplete = false;
        double fingerScale = 1.0;
        double fingerOpacity = 1.0;
        double trailOpacity = 1.0;

        if (t < 0.10) {
          // Phase 0: Touchdown at 'C'
          fingerPos = _pC;
          reachedIndex = 0;
          tileCLit = true;
          wordText = 'C';
          final subT = t / 0.10;
          fingerScale = 1.3 - (0.3 * subT);
          fingerOpacity = 1.0;
        } else if (t < 0.35) {
          // Phase 1: Swipe C -> O
          final subT = (t - 0.10) / 0.25;
          final curved = Curves.easeInOut.transform(subT);
          fingerPos = Offset.lerp(_pC, _pO, curved)!;
          reachedIndex = 1;
          tileCLit = true;
          tileOLit = subT >= 0.85;
          wordText = subT >= 0.85 ? 'C • O' : 'C';
        } else if (t < 0.60) {
          // Phase 2: Swipe O -> Z
          final subT = (t - 0.35) / 0.25;
          final curved = Curves.easeInOut.transform(subT);
          fingerPos = Offset.lerp(_pO, _pZ, curved)!;
          reachedIndex = 2;
          tileCLit = true;
          tileOLit = true;
          tileZLit = subT >= 0.85;
          wordText = subT >= 0.85 ? 'C • O • Z' : 'C • O';
        } else if (t < 0.84) {
          // Phase 3: Swipe Z -> Y
          final subT = (t - 0.60) / 0.24;
          final curved = Curves.easeInOut.transform(subT);
          fingerPos = Offset.lerp(_pZ, _pY, curved)!;
          reachedIndex = 3;
          tileCLit = true;
          tileOLit = true;
          tileZLit = true;
          tileYLit = subT >= 0.85;
          wordText = subT >= 0.85 ? 'C • O • Z • Y' : 'C • O • Z';
          isComplete = subT >= 0.85;
        } else if (t < 0.94) {
          // Phase 4: Full word completion celebration at Y
          fingerPos = _pY;
          reachedIndex = 4;
          tileCLit = true;
          tileOLit = true;
          tileZLit = true;
          tileYLit = true;
          wordText = 'C • O • Z • Y';
          isComplete = true;
          final subT = (t - 0.84) / 0.10;
          fingerScale = 1.0 + (0.15 * subT);
          fingerOpacity = 1.0;
        } else {
          // Phase 5: Smooth fade & reset
          fingerPos = _pY;
          reachedIndex = 4;
          tileCLit = true;
          tileOLit = true;
          tileZLit = true;
          tileYLit = true;
          wordText = 'C • O • Z • Y';
          isComplete = true;
          final subT = (t - 0.94) / 0.06;
          fingerScale = 1.15 + (0.1 * subT);
          fingerOpacity = (1.0 - subT).clamp(0.0, 1.0);
          trailOpacity = (1.0 - subT).clamp(0.0, 1.0);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word Formation Status Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B120B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isComplete ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isComplete ? const Color(0xFF81C784) : const Color(0xFFFFD54F))
                        .withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WORD: ',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFD7CCC8),
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    wordText,
                    style: GoogleFonts.lilitaOne(
                      color: isComplete ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                      fontSize: 13,
                      letterSpacing: 1.8,
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF81C784), size: 15),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Honeycomb Canvas
            SizedBox(
              width: _boardWidth,
              height: _boardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 7 Hexagon Tiles in Honeycomb Formation
                  _buildTile('H', const Offset(130, 22), false),
                  _buildTile('C', _pC, tileCLit),
                  _buildTile('O', _pO, tileOLit),
                  _buildTile('Z', _pZ, tileZLit),
                  _buildTile('W', const Offset(84, 103), false),
                  _buildTile('D', const Offset(130, 130), false),
                  _buildTile('Y', _pY, tileYLit),

                  // Progressive glowing swipe trail connecting C -> O -> Z -> Y
                  CustomPaint(
                    size: const Size(_boardWidth, _boardHeight),
                    painter: _TutorialSwipeTrailPainter(
                      waypoints: const [_pC, _pO, _pZ, _pY],
                      reachedIndex: reachedIndex,
                      currentPos: fingerPos,
                      trailOpacity: trailOpacity,
                      isComplete: isComplete,
                    ),
                  ),

                  // Luminous golden touch ripple under the fingertip
                  if (fingerOpacity > 0.05)
                    Positioned(
                      left: fingerPos.dx - 14,
                      top: fingerPos.dy - 14,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: fingerOpacity,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                              border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Animated Pointer Hand pointing precisely at fingerPos
                  if (fingerOpacity > 0.05)
                    Positioned(
                      left: fingerPos.dx - 18,
                      top: fingerPos.dy - 8,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: fingerOpacity,
                          child: Transform.scale(
                            scale: fingerScale,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFFFFD54F),
                              size: 36,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(1.5, 2.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Direction Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2E1C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_alt_rounded, color: Color(0xFF81C784), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'SWIPE IN ALL 6 DIRECTIONS!',
                      style: GoogleFonts.lilitaOne(
                        color: const Color(0xFFE8F5E9),
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(String letter, Offset center, bool isLit) {
    return Positioned(
      left: center.dx - (_hexW / 2),
      top: center.dy - (_hexH / 2),
      child: AnimatedScale(
        scale: isLit ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PhysicalShape(
              clipper: _TutorialHexagonClipper(),
              color: isLit ? const Color(0xFF7CB342) : const Color(0xFF5D4037),
              elevation: isLit ? 6.0 : 2.5,
              shadowColor: isLit ? const Color(0xFFFFD54F) : Colors.black87,
              child: ClipPath(
                clipper: _TutorialHexagonClipper(),
                child: Container(
                  width: _hexW,
                  height: _hexH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isLit ? 0.35 : 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                  child: Text(
                    letter,
                    style: GoogleFonts.lilitaOne(
                      color: Colors.white,
                      fontSize: 18,
                      shadows: const [
                        Shadow(color: Colors.black45, offset: Offset(0, 1.5), blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(_hexW, _hexH),
              painter: _TutorialHexagonBorderPainter(
                borderColor: isLit ? const Color(0xFFFFD54F) : const Color(0xFF3E2723),
                borderWidth: isLit ? 2.5 : 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// PROGRESSIVE SWIPE TRAIL PAINTER CONNECTING C -> O -> Z -> Y
// -------------------------------------------------------------
class _TutorialSwipeTrailPainter extends CustomPainter {
  final List<Offset> waypoints;
  final int reachedIndex;
  final Offset currentPos;
  final double trailOpacity;
  final bool isComplete;

  _TutorialSwipeTrailPainter({
    required this.waypoints,
    required this.reachedIndex,
    required this.currentPos,
    this.trailOpacity = 1.0,
    this.isComplete = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trailOpacity <= 0.01) return;

    if (reachedIndex == 0) {
      final startPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.8 * trailOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(waypoints[0], 5, startPaint);
      return;
    }

    final path = Path();
    path.moveTo(waypoints[0].dx, waypoints[0].dy);

    for (int i = 1; i < reachedIndex && i < waypoints.length; i++) {
      path.lineTo(waypoints[i].dx, waypoints[i].dy);
    }

    if (reachedIndex < waypoints.length) {
      path.lineTo(currentPos.dx, currentPos.dy);
    } else {
      path.lineTo(waypoints.last.dx, waypoints.last.dy);
    }

    final glowColor = isComplete ? const Color(0xFF81C784) : const Color(0xFFFFD54F);
    final coreColor = isComplete ? const Color(0xFFE8F5E9) : const Color(0xFFFFF9E6);

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.55 * trailOpacity)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final corePaint = Paint()
      ..color = coreColor.withValues(alpha: trailOpacity)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);

    final nodePaint = Paint()
      ..color = glowColor.withValues(alpha: trailOpacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= reachedIndex && i < waypoints.length; i++) {
      canvas.drawCircle(waypoints[i], 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TutorialSwipeTrailPainter old) {
    return old.currentPos != currentPos ||
        old.reachedIndex != reachedIndex ||
        old.trailOpacity != trailOpacity ||
        old.isComplete != isComplete;
  }
}

// -------------------------------------------------------------
// SPEECH BUBBLE TAIL PAINTER
// (Points horizontally toward character's mouth/chest)
// -------------------------------------------------------------
class _SpeechBubbleTailPainter extends CustomPainter {
  final bool pointsToLeft;
  final Color fillColor;
  final Color borderColor;

  _SpeechBubbleTailPainter({
    required this.pointsToLeft,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsToLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
      path.close();
    }

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
