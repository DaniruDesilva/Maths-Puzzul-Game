import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_router.dart';
import '../providers/user_provider.dart';
import '../data/village_data.dart';
import '../data/math_level_repository.dart';
import 'village_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<String> _loadingTips = const [
    'Warming the hearth in Oakheart...',
    'Gathering fresh wooden number tiles...',
    'Mayor Bramble is preparing your daily rewards...',
    'Brewing chamomile tea at the bakery...',
  ];
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _tipTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (timer.tick) % _loadingTips.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAppInitialization();
    });
  }

  Future<void> _startAppInitialization() async {
    // 1. Kick off visual progress bar animation
    final animationFuture = _progressController.forward();

    // 2. Await UserProvider SQLite & SharedPreferences initialization
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final dataFuture = userProvider.initialized;

    // 3. Precache village and villager artwork
    final precacheFuture = _precacheVillageAssets();

    // 4. Preload verified campaign levels JSON
    final campaignFuture = MathLevelRepository.preloadCampaign();

    // 5. Await data readiness, asset preloading, campaign loading, and progress bar
    await Future.wait([
      animationFuture,
      dataFuture,
      precacheFuture,
      campaignFuture,
    ]);

    _tipTimer?.cancel();
    if (!mounted) return;

    if (!mounted) return;

    // Smooth cinematic cross-fade transition directly into the Village
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: const RouteSettings(name: AppRouter.home),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return VillageScreen(village: VillageData.meadow, isRoot: true);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _precacheVillageAssets() async {
    if (!mounted) return;
    try {
      await Future.wait([
        precacheImage(const AssetImage('assets/images/village/meadow/island_bg.webp'), context),
        precacheImage(const AssetImage('assets/images/village/meadow/cottage_stage1.webp'), context),
        precacheImage(const AssetImage('assets/images/village/meadow/cottage_stage3.webp'), context),
        precacheImage(const AssetImage('assets/images/village/meadow/windmill_stage3.webp'), context),
        precacheImage(const AssetImage('assets/images/village/meadow/bakery_stage3.webp'), context),
        precacheImage(const AssetImage('assets/images/village/villagers/bunny.webp'), context),
        precacheImage(const AssetImage('assets/images/village/villagers/fox.webp'), context),
        precacheImage(const AssetImage('assets/images/village/villagers/bunny_hd.webp'), context),
        precacheImage(const AssetImage('assets/images/village/villagers/fox_hd.webp'), context),
        precacheImage(const AssetImage('assets/images/village/villagers/owl_hd.webp'), context),
      ]);
    } catch (e) {
      debugPrint('Precache assets error (non-fatal): $e');
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1E14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen fairytale village illustration background
          Image.asset(
            'assets/images/splash_bg.webp',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 2. Atmospheric vignette / gradients for contrast & depth
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.28, 0.60, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. Foreground UI Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // TOP HERO: 3D Tile Emblem + Word Haven Title + Cozy Village Badge
                  _buildHeroLogo(),

                  const Spacer(),

                  // BOTTOM SECTION: Dynamic progress bar & rotating tips
                  _buildLoadingSection(),

                  const SizedBox(height: 28),

                  // DEVELOPER BRANDING: Creator Box Studios
                  _buildDeveloperCredit(),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Wooden Tile Emblem
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 3.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Image.asset(
              'assets/images/store/store_icon_512.png',
              fit: BoxFit.cover,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),

        const SizedBox(height: 16),

        // Main Title: NUMBER HAVEN
        Text(
          'NUMBER HAVEN',
          textAlign: TextAlign.center,
          style: GoogleFonts.lilitaOne(
            fontSize: 40,
            letterSpacing: 4.5,
            color: const Color(0xFFFFFDF5),
            shadows: const [
              Shadow(
                color: Color(0xFF2C190B),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
              Shadow(
                color: Color(0xFF5D4037),
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

        const SizedBox(height: 8),

        // Subtitle Pill: 🌿 COZY VILLAGE 🌿
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF3E2723).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa_rounded, color: Color(0xFFFFD54F), size: 15),
              const SizedBox(width: 8),
              Text(
                'COZY VILLAGE',
                style: GoogleFonts.lilitaOne(
                  color: const Color(0xFFFFE082),
                  fontSize: 14,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.spa_rounded, color: Color(0xFFFFD54F), size: 15),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rotating cozy village loading whisper
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            _loadingTips[_currentTipIndex],
            key: ValueKey<int>(_currentTipIndex),
            textAlign: TextAlign.center,
            style: GoogleFonts.baloo2(
              color: const Color(0xFFFFF8E7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Polished Game Progress Bar
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E140C).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.0),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value.clamp(0.04, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB300),
                        Color(0xFF81C784),
                        Color(0xFF66BB6A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF81C784).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms);
  }

  Widget _buildDeveloperCredit() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DEVELOPED BY',
          style: GoogleFonts.baloo2(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'CREATOR BOX STUDIOS',
          textAlign: TextAlign.center,
          style: GoogleFonts.lilitaOne(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 2.2,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms);
  }
}
