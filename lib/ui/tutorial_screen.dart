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
            // 1. Lush Meadow Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg.webp',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Warm Sunlit Vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2E4D1E).withValues(alpha: 0.38),
                      const Color(0xFF241A0E).withValues(alpha: 0.58),
                      const Color(0xFF140D07).withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Main Content
            SafeArea(
              child: Column(
                children: [
                  _buildTopHeader(),
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
                        _buildSlideCrossmathEquations(),
                        _buildSlideCandidateTray(),
                        _buildSlideHintsAndTools(),
                        _buildSlideVillageRestoration(),
                        _buildSlideReadyToPlay(),
                      ],
                    ),
                  ),
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
  // TOP HEADER
  // -------------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Navigation & Progress Bar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _previousPage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2718),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFD54F), size: 16),
                  ),
                )
              else
                const SizedBox(width: 38),

              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1B0E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.25), blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        'OAKHEART GUIDE • ${_currentPage + 1} / $_totalPages',
                        style: GoogleFonts.lilitaOne(
                          color: const Color(0xFFFFD54F),
                          fontSize: 12.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: _finishTutorial,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2718),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    'SKIP',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 2. Full-Width Slide Title (Zero truncation with FittedBox)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _getSlideTitle(_currentPage),
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 1.4,
                  shadows: const [
                    Shadow(color: Color(0xFF10B981), blurRadius: 10),
                    Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSlideTitle(int page) {
    switch (page) {
      case 0:
        return 'WELCOME TO NUMBER HAVEN!';
      case 1:
        return 'CROSSMATH EQUATIONS';
      case 2:
        return 'CANDIDATE NUMBER TRAY';
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
  // SLIDE 0: Welcome to Number Haven!
  // -------------------------------------------------------------
  Widget _buildSlideWelcome() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('✨ A COZY CROSSMATH ADVENTURE ✨'),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/village/meadow/cottage_stage3.webp', height: 80),
                      const SizedBox(width: 14),
                      _buildEquationMiniRow([
                        _buildMiniTile('2', isGiven: true),
                        _buildMiniTile('+', isOp: true),
                        _buildMiniTile('3', isBlank: true),
                        _buildMiniTile('=', isOp: true),
                        _buildMiniTile('5', isGiven: true),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Solve Math Crosswords • Restore Oakheart Village',
                    style: GoogleFonts.baloo2(
                      color: const Color(0xFFFFD54F),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _buildPillTag('🧩 Crossmath Logic', const Color(0xFF10B981)),
                    _buildPillTag('💰 Golden Coins', const Color(0xFFFFD54F)),
                    _buildPillTag('🏡 Restore Haven', const Color(0xFF38BDF8)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/bunny_hd.webp',
            isLeft: true,
            villagerPill: 'MAYOR BRAMBLE • VILLAGE GUIDE',
            speech: "Welcome to Number Haven! Solve relaxing math crosswords to collect golden coins, expand your brain, and rebuild our beautiful village!",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 1: Crossmath Equations
  // -------------------------------------------------------------
  Widget _buildSlideCrossmathEquations() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('HORIZONTAL & VERTICAL EQUATIONS!'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140D07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4A3320)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 38),
                          _buildMiniTile('2', isGiven: true),
                          const SizedBox(width: 38),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 38),
                          _buildMiniTile('+', isOp: true),
                          const SizedBox(width: 38),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniTile('18', isGiven: true),
                          _buildMiniTile('-', isOp: true),
                          _buildMiniTile('3', isBlank: true, isHighlight: true),
                          _buildMiniTile('=', isOp: true),
                          _buildMiniTile('15', isGiven: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 38),
                          _buildMiniTile('=', isOp: true),
                          const SizedBox(width: 38),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 38),
                          _buildMiniTile('5', isGiven: true),
                          const SizedBox(width: 38),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildCalcGuidePill('↔ Horizontal', '18 - 3 = 15', const Color(0xFFFFD54F)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCalcGuidePill('↕ Vertical', '2 + 3 = 5', const Color(0xFF34D399)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rows & Columns intersect! The middle tile balances both equations.',
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFD1FAE5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/owl_hd.webp',
            isLeft: false,
            villagerPill: 'PROFESSOR HOOT • MATHEMATICIAN',
            speech: "Every horizontal row and vertical column must be mathematically correct! Standard left-to-right calculation order applies.",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 2: Candidate Number Tray
  // -------------------------------------------------------------
  Widget _buildSlideCandidateTray() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('PICK NUMBERS FROM YOUR TRAY'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140D07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF5A3C23), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTrayItem(5, count: 1),
                      _buildTrayItem(15, count: 2, isHighlight: true),
                      _buildTrayItem(8, count: 1),
                      _buildTrayItem(3, count: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStepItem('1', 'Tap any empty blank tile on the board to select it'),
                const SizedBox(height: 6),
                _buildStepItem('2', 'Tap a number from your tray to place it!'),
                const SizedBox(height: 6),
                _buildStepItem('★', 'Numbers with badge multipliers (like ×2) can be placed into multiple slots!'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/fox_hd.webp',
            isLeft: true,
            villagerPill: 'FERN THE FOX • NUMBER CRAFTER',
            speech: "Numbers with badge multipliers (like ×2) can be placed into multiple slots. If you change your mind, tap Erase to return the number to your tray!",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 3: Helpful Puzzle Tools
  // -------------------------------------------------------------
  Widget _buildSlideHintsAndTools() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('POWERFUL IN-GAME ASSISTANTS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolFeatureCard(
                        icon: Icons.lightbulb_rounded,
                        title: 'SMART HINT',
                        desc: 'Guides you to the next logical deduction',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToolFeatureCard(
                        icon: Icons.edit_note_rounded,
                        title: 'NOTES MODE',
                        desc: 'Pencil in candidate numbers safely',
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolFeatureCard(
                        icon: Icons.undo_rounded,
                        title: 'UNDO',
                        desc: 'Revert any mistake with a tap',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToolFeatureCard(
                        icon: Icons.backspace_rounded,
                        title: 'ERASE',
                        desc: 'Clear tile & return number to tray',
                        color: const Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillTag('HINT', const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _buildPillTag('MEGA HINT', const Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      _buildPillTag('ULTRA HINT', const Color(0xFF00ACC1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/owl_hd.webp',
            isLeft: false,
            villagerPill: 'PROFESSOR HOOT • PUZZLE MASTER',
            speech: "Use Smart Hints whenever you feel stuck! Toggle Notes Mode ON to pencil in candidates before committing your final numbers.",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 4: Restore Oakheart Village
  // -------------------------------------------------------------
  Widget _buildSlideVillageRestoration() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('REBUILD YOUR FLOATING HAVEN'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBuildingShowcase('Cottage', 'assets/images/village/meadow/cottage_stage3.webp', '+15 Coins/3h')),
                    Expanded(child: _buildBuildingShowcase('Bakery', 'assets/images/village/meadow/bakery_stage1.webp', '+10 Coins/2h')),
                    Expanded(child: _buildBuildingShowcase('Windmill', 'assets/images/village/meadow/windmill_stage1.webp', 'Daily Hints')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Spend golden coins earned from puzzles to upgrade homes, restore shops, and welcome adorable animal villagers!',
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFFFFBEB),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/bunny_hd.webp',
            isLeft: true,
            villagerPill: 'MAYOR BRAMBLE • VILLAGE ECONOMY',
            speech: "Every building grants idle coins or daily hints. The Library even grants extra coins for every equation solved in your puzzles!",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 5: Ready for Adventure!
  // -------------------------------------------------------------
  Widget _buildSlideReadyToPlay() {
    return _buildSlideWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStageCard(
            child: Column(
              children: [
                _buildRibbon('⭐ START LEVEL 1 TODAY ⭐'),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 40)
                            .animate(delay: (i * 200).ms)
                            .scale(curve: Curves.elasticOut),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '3-STAR EXCELLENCE • BRAIN CAPACITY (cc)',
                    style: GoogleFonts.lilitaOne(
                      color: const Color(0xFFFFD54F),
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPerkItem(Icons.star_rounded, '3-Star Mastery', 'Solve puzzles with 0 mistakes & 0 hints to earn 3 Stars!', const Color(0xFFFFD54F)),
                const SizedBox(height: 6),
                _buildPerkItem(Icons.psychology_rounded, 'Brain Capacity (cc)', 'Grow your Brain Size to unlock new biomes on the World Map!', const Color(0xFF38BDF8)),
                const SizedBox(height: 6),
                _buildPerkItem(Icons.card_giftcard_rounded, '100 Coin Starter Gift', 'Mayor Bramble has funds waiting to build your Meadow Cottage!', const Color(0xFF34D399)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildVillagerDialog(
            imagePath: 'assets/images/village/villagers/bunny_hd.webp',
            isLeft: true,
            villagerPill: 'MAYOR BRAMBLE • VILLAGE GUIDE',
            speech: "Step into Level 1, relax your mind with satisfying crossmath, and let's restore Oakheart Village together!",
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER BUILDERS
  // -------------------------------------------------------------
  Widget _buildSlideWrapper({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 12),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E1C0F),
            Color(0xFF1B1008),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4A373), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRibbon(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF689F38), Color(0xFF558B2F)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.lilitaOne(
          color: Colors.white,
          fontSize: 11.5,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildMiniTile(String text, {bool isGiven = false, bool isBlank = false, bool isOp = false, bool isHighlight = false}) {
    Color bg = const Color(0xFF26190F);
    Color border = const Color(0xFF5A3C23);
    Color textColor = Colors.white;

    if (isHighlight) {
      bg = const Color(0xFF78350F);
      border = const Color(0xFFF59E0B);
      textColor = const Color(0xFFFDE68A);
    } else if (isOp) {
      bg = const Color(0xFF0F2B1D);
      border = const Color(0xFF10B981);
      textColor = const Color(0xFF6EE7B7);
    } else if (isBlank) {
      bg = const Color(0xFF1E130A);
      border = const Color(0xFFD4A373);
      textColor = const Color(0xFFFFD54F);
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.lilitaOne(color: textColor, fontSize: 14),
      ),
    );
  }

  Widget _buildEquationMiniRow(List<Widget> children) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildTrayItem(int num, {int count = 1, bool isHighlight = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isHighlight
                  ? [const Color(0xFF854D0E), const Color(0xFF543209)]
                  : [const Color(0xFF4A3320), const Color(0xFF2D1F13)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight ? const Color(0xFFFBBF24) : const Color(0xFF8B5A2B),
              width: 1.8,
            ),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(
            '$num',
            style: GoogleFonts.lilitaOne(
              color: const Color(0xFFFFFBEB),
              fontSize: 18,
            ),
          ),
        ),
        if (count > 1)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '×$count',
                style: GoogleFonts.baloo2(
                  color: const Color(0xFF451A03),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepItem(String step, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFF140D07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A3320), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              step,
              style: GoogleFonts.lilitaOne(color: const Color(0xFF451A03), fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.baloo2(
                color: const Color(0xFFFFFBEB),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcGuidePill(String dir, String eq, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dir: ',
              style: GoogleFonts.baloo2(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              eq,
              style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFF140D07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lilitaOne(color: color, fontSize: 12),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF17100B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lilitaOne(color: color, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: GoogleFonts.baloo2(color: const Color(0xFF94A3B8), fontSize: 10, height: 1.15),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.lilitaOne(color: color, fontSize: 9.5),
      ),
    );
  }

  Widget _buildBuildingShowcase(String name, String imagePath, String perk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF140D07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B5A2B), width: 1.2),
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name, style: GoogleFonts.lilitaOne(color: const Color(0xFFFFD54F), fontSize: 11)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(perk, style: GoogleFonts.baloo2(color: const Color(0xFF94A3B8), fontSize: 9.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildVillagerDialog({
    required String imagePath,
    required bool isLeft,
    required String villagerPill,
    required String speech,
  }) {
    final avatar = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD54F).withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Image.asset(imagePath, height: 95, fit: BoxFit.contain),
      ],
    );

    final bubble = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5),
              Color(0xFFFFF2D6),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF8B5A2B), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF382313),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                villagerPill,
                style: GoogleFonts.lilitaOne(
                  color: const Color(0xFFFFD54F),
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              speech,
              style: GoogleFonts.baloo2(
                color: const Color(0xFF3E2310),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.26,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isLeft ? [avatar, const SizedBox(width: 8), bubble] : [bubble, const SizedBox(width: 8), avatar],
    );
  }

  // -------------------------------------------------------------
  // BOTTOM CONTROLS
  // -------------------------------------------------------------
  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF22140A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6E4726), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _totalPages,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: index == _currentPage ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: index == _currentPage ? const Color(0xFFFFD54F) : const Color(0xFF5A3D24),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: index == _currentPage
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.65),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onTap: _nextPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF34D399),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF064E3B),
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == _totalPages - 1 ? 'START YOUR JOURNEY' : 'NEXT',
                        style: GoogleFonts.lilitaOne(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 1.1,
                          shadows: const [
                            Shadow(color: Color(0xFF064E3B), offset: Offset(0, 1.5), blurRadius: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        _currentPage == _totalPages - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
