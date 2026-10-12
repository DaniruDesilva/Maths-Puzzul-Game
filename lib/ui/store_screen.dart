import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _flashSaleTimer;
  Duration _timeLeft = Duration.zero;

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday) {
      final endOfSaturday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      _timeLeft = endOfSaturday.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    } else {
      _timeLeft = Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _calculateTimeLeft();
    
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateTimeLeft();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashSaleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1E16), // Dark Wood Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFDF5E6), size: 32),
        title: Text(
          'MERCHANT',
          style: TextStyle(
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            color: const Color(0xFFFFD54F),
            fontSize: 32,
            letterSpacing: 3,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, user, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildCurrencyHeader(user),
              const SizedBox(height: 24),
              
              // Flash Sale Banner
              if (_timeLeft.inSeconds > 0) ...[
                _buildFlashSale(user, context),
                const SizedBox(height: 24),
              ],

              // Watch Ad Option
              _buildStoreItem(
                title: 'Free Hint',
                description: 'Watch a quick ad to earn 1 free regular hint.',
                icon: Icons.play_circle_fill_rounded,
                iconColor: const Color(0xFF4CAF50),
                buttonText: 'WATCH',
                buttonColor: const Color(0xFF7CB342),
                buttonHighlight: const Color(0xFFAED581),
                buttonShadow: const Color(0xFF33691E),
                onTap: () {
                  AdService.showRewardedAd(user);
                },
              ),
              const SizedBox(height: 16),
              
              // Buy 10 Hints
              _buildStoreItem(
                title: '10 Hint Pack',
                description: 'Stuck? Get a small pack of regular hints.',
                icon: Icons.lightbulb_rounded,
                iconColor: const Color(0xFFFFB74D),
                buttonText: '\$0.99',
                buttonColor: const Color(0xFFF6A000),
                buttonHighlight: const Color(0xFFFFD54F),
                buttonShadow: const Color(0xFFB97700),
                onTap: () {
                  user.addHint(10);
                  _showMockPurchase(context, '10 Hints');
                },
              ),
              const SizedBox(height: 16),

              // Buy 50 Hints
              _buildStoreItem(
                title: '50 Hint Pack',
                description: 'Best value! Never get stuck again.',
                icon: Icons.tips_and_updates_rounded,
                iconColor: const Color(0xFFFFD54F),
                buttonText: '\$2.99',
                buttonColor: const Color(0xFFF6A000),
                buttonHighlight: const Color(0xFFFFD54F),
                buttonShadow: const Color(0xFFB97700),
                isPremium: true,
                onTap: () {
                  user.addHint(50);
                  _showMockPurchase(context, '50 Hints');
                },
              ),
              const SizedBox(height: 16),
              
              // Mega Hints
              _buildStoreItem(
                title: '5 Mega Hints',
                description: 'Reveals a key number to unlock multiple equations.',
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFD700),
                buttonText: '\$1.99',
                buttonColor: const Color(0xFFF6A000),
                buttonHighlight: const Color(0xFFFFD54F),
                buttonShadow: const Color(0xFFB97700),
                onTap: () {
                  user.addMegaHint(5);
                  _showMockPurchase(context, '5 Mega Hints');
                },
              ),
              const SizedBox(height: 16),

              // Ultra Hints
              _buildStoreItem(
                title: '3 Ultra Hints',
                description: 'Instantly solves an entire equation.',
                icon: Icons.diamond_rounded,
                iconColor: const Color(0xFF00D4FF),
                buttonText: '\$2.99',
                buttonColor: const Color(0xFF00ACC1),
                buttonHighlight: const Color(0xFF4DD0E1),
                buttonShadow: const Color(0xFF006064),
                onTap: () {
                  user.addUltraHint(3);
                  _showMockPurchase(context, '3 Ultra Hints');
                },
              ),
              const SizedBox(height: 16),

              // Buy 500 Coins
              _buildStoreItem(
                title: '500 Coins',
                description: 'Upgrade your village faster!',
                icon: Icons.monetization_on_rounded,
                iconColor: const Color(0xFFFFD54F),
                buttonText: '\$1.99',
                buttonColor: const Color(0xFFF6A000),
                buttonHighlight: const Color(0xFFFFD54F),
                buttonShadow: const Color(0xFFB97700),
                onTap: () {
                  user.addCoins(500);
                  _showMockPurchase(context, '500 Coins');
                },
              ),
              const SizedBox(height: 16),

              // Buy 2000 Coins
              _buildStoreItem(
                title: '2000 Coins',
                description: 'Build the ultimate Cozy Village.',
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFFFFD54F),
                buttonText: '\$4.99',
                buttonColor: const Color(0xFFF6A000),
                buttonHighlight: const Color(0xFFFFD54F),
                buttonShadow: const Color(0xFFB97700),
                isPremium: true,
                onTap: () {
                  user.addCoins(2000);
                  _showMockPurchase(context, '2000 Coins');
                },
              ),
              const SizedBox(height: 16),

              // Remove Ads
              _buildStoreItem(
                title: 'Remove Ads',
                description: 'Play uninterrupted forever. Removes interstitial ads.',
                icon: Icons.block_rounded,
                iconColor: const Color(0xFFE57373),
                buttonText: user.adsRemoved ? 'BOUGHT' : '\$2.99',
                buttonColor: user.adsRemoved ? const Color(0xFF9E9E9E) : const Color(0xFFE53935),
                buttonHighlight: user.adsRemoved ? const Color(0xFFBDBDBD) : const Color(0xFFEF5350),
                buttonShadow: user.adsRemoved ? const Color(0xFF616161) : const Color(0xFFB71C1C),
                onTap: () {
                  if (!user.adsRemoved) {
                    user.removeAds();
                    _showMockPurchase(context, 'Remove Ads');
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrencyHeader(UserProvider user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCurrencyPill(Icons.monetization_on_rounded, const Color(0xFFFFD54F), user.coins.toString()),
        _buildCurrencyPill(Icons.lightbulb_rounded, const Color(0xFFFFB74D), user.hintsRegular.toString()),
        _buildCurrencyPill(Icons.star_rounded, const Color(0xFF4DD0E1), user.hintsMega.toString()),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildCurrencyPill(IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showMockPurchase(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Purchase successful: $item (Mock IAP)',
        style: TextStyle(fontFamily: GoogleFonts.lilitaOne().fontFamily, fontSize: 16),
      ),
      backgroundColor: const Color(0xFF7CB342),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  Widget _buildFlashSale(UserProvider user, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFF8E0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1E16).withValues(alpha: 0.8), // Inner dark tint
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF5252), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD54F), size: 26),
                    const SizedBox(width: 6),
                    Text(
                      'FLASH SALE',
                      style: TextStyle(
                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 1,
                        shadows: const [Shadow(color: Color(0xFFFF5252), blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 2),
                  ),
                  child: Text(
                    '${_timeLeft.inHours.toString().padLeft(2, '0')}:${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Starter Bundle: 100 Hints + Remove Ads',
              style: TextStyle(
                color: Color(0xFFFDF5E6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                user.addHint(100);
                if (!user.adsRemoved) user.removeAds();
                _showMockPurchase(context, 'Starter Bundle');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, offset: Offset(0, 6), blurRadius: 0),
                  ],
                ),
                child: Center(
                  child: Text(
                    '\$3.99 (50% OFF)',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: const Color(0xFF3E2723),
                      fontSize: 22,
                      letterSpacing: 1.5,
                      shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(0, 1))],
                    ),
                  ),
                ),
              ),
            ).animate(controller: _pulseController).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.03, 1.03)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildStoreItem({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required Color buttonColor,
    required Color buttonHighlight,
    required Color buttonShadow,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFFD54F) : const Color(0xFF8B5A2B), // Thick border color
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 6),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6), // Parchment
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPremium ? const Color(0xFFFFF9C4) : const Color(0xFFD7CCC8), width: 2), // Inner light rim
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                        color: const Color(0xFF5D4037),
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chunky AAA Button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: buttonShadow, width: 2),
                  boxShadow: [
                    BoxShadow(color: buttonShadow, offset: const Offset(0, 4), blurRadius: 0),
                    BoxShadow(color: buttonHighlight, offset: const Offset(0, -2), spreadRadius: -1),
                  ],
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 2)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

