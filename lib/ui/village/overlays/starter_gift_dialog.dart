import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/user_provider.dart';
import '../../../services/sound_service.dart';

class StarterGiftDialog extends StatelessWidget {
  final UserProvider user;

  const StarterGiftDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5),
              Color(0xFFFFF3DB),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF7A451A), width: 3.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. TOP CARVED WOOD RIBBON: WELCOME STARTER GIFT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42220E), Color(0xFF261205)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD54F), size: 16),
                    const SizedBox(width: 7),
                    Text(
                      'WELCOME STARTER GIFT',
                      style: GoogleFonts.lilitaOne(
                        color: const Color(0xFFFFD54F),
                        fontSize: 12.5,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. HERO CELEBRATION STAGE: MAYOR BRAMBLE & 3D TREASURE CHEST
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Radiant Golden Aura Background
                    Container(
                      width: 220,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFE082).withValues(alpha: 0.55),
                            const Color(0xFFFFCA28).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          radius: 0.75,
                        ),
                      ),
                    ),

                    // Stage Row: Mayor Bramble on Left + Golden Chest on Right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Mayor Bramble standing proudly
                        Image.asset(
                          'assets/images/village/villagers/bunny_hd.webp',
                          height: 110,
                          fit: BoxFit.contain,
                        )
                            .animate()
                            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 380.ms, curve: Curves.easeOutBack),

                        const SizedBox(width: 8),

                        // 3D Golden Treasure Chest overflowing with coins
                        Image.asset(
                          'assets/images/village/meadow/starter_gift_chest.webp',
                          height: 96,
                          fit: BoxFit.contain,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1.4.seconds)
                            .then()
                            .shimmer(duration: 1.2.seconds, color: const Color(0xFFFFF9C4).withValues(alpha: 0.4)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. HEADER TITLE
              Text(
                'WELCOME TO OAKHEART!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  color: const Color(0xFF381B09),
                  fontSize: 22,
                  letterSpacing: 1.3,
                  shadows: const [
                    Shadow(color: Color(0x33FFE082), offset: Offset(0, 2), blurRadius: 4),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // 4. WELCOMING NARRATIVE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "Mayor Bramble has gifted you starting funds to build your very first home in our cozy meadow!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFF4E2C14),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. PRESTIGE REWARD SHOWCASE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF28170B),
                      Color(0xFF1B0E05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Golden Coins Total Banner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 26),
                        const SizedBox(width: 8),
                        Text(
                          '+100 GOLDEN COINS',
                          style: GoogleFonts.lilitaOne(
                            color: const Color(0xFFFFD54F),
                            fontSize: 19,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Gold Divider
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    ),

                    const SizedBox(height: 8),

                    // Full-width Meadow Cottage Stage 1 Spotlight Card (100 Coins = 100% Ready to Build!)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF382313),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF10B981), width: 1.6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.22),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 3D Cottage Stage 1 asset
                          Image.asset(
                            'assets/images/village/meadow/cottage_stage1.webp',
                            height: 42,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Meadow Cottage',
                                        style: GoogleFonts.lilitaOne(
                                          color: const Color(0xFFFFF9E6),
                                          fontSize: 14.5,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6), width: 1),
                                        ),
                                        child: Text(
                                          'LEVEL 1 • STAGE 1',
                                          style: GoogleFonts.baloo2(
                                            color: const Color(0xFF34D399),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Cost: 100 💰',
                                      style: GoogleFonts.baloo2(
                                        color: const Color(0xFFFFD54F),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '• Ready to Build Now!',
                                        style: GoogleFonts.baloo2(
                                          color: const Color(0xFF34D399),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Next milestone pill: Bakery unlocks at Level 6
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/village/meadow/bakery_stage1.webp',
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Next Goal: Village Bakery unlocks at Level 6 (200 💰)',
                              style: GoogleFonts.baloo2(
                                color: const Color(0xFFD4A373),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .shimmer(delay: 500.ms, duration: 1800.ms, color: const Color(0xFFFFE082).withValues(alpha: 0.3)),

              const SizedBox(height: 16),

              // 6. GRAND TACTILE 3D CTA BUTTON: CLAIM YOUR 100 COINS
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF66BB6A),
                        Color(0xFF388E3C),
                        Color(0xFF2E7D32),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF1B5E20),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black38,
                        offset: Offset(0, 6),
                        blurRadius: 8,
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFFFE082), width: 2),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      SoundService.playClick();
                      await user.claimStarterGift();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF43A047),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD54F), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🎉 100 Starter Coins claimed! Tap Cottage to build!',
                                  style: GoogleFonts.lilitaOne(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFE082), size: 23),
                        const SizedBox(width: 8),
                        Text(
                          'CLAIM YOUR 100 COINS',
                          style: GoogleFonts.lilitaOne(
                            fontSize: 16.5,
                            letterSpacing: 1.3,
                            color: const Color(0xFFFFFFFF),
                            shadows: const [
                              Shadow(
                                color: Color(0xFF1B5E20),
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.02, 1.02), duration: 1100.ms),
            ],
          ),
        ),
      )
          .animate()
          .scale(begin: const Offset(0.88, 0.88), end: const Offset(1.0, 1.0), duration: 350.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 250.ms),
    );
  }
}
