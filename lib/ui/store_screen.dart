import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import 'village/overlays/acorn_vault_dialog.dart';

enum StoreCategory { all, coins, hints, bundles }

class StoreScreen extends StatefulWidget {
  final String? initialCategory;

  const StoreScreen({super.key, this.initialCategory});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _flashSaleTimer;
  Duration _timeLeft = Duration.zero;
  late StoreCategory _selectedCategory;

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

    _selectedCategory = _parseInitialCategory(widget.initialCategory);
    _calculateTimeLeft();

    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });
  }

  StoreCategory _parseInitialCategory(String? cat) {
    if (cat == null) return StoreCategory.all;
    switch (cat.toLowerCase()) {
      case 'coins':
      case 'coin':
        return StoreCategory.coins;
      case 'hints':
      case 'hint':
        return StoreCategory.hints;
      case 'bundles':
      case 'bundle':
        return StoreCategory.bundles;
      default:
        return StoreCategory.all;
    }
  }

  @override
  void didUpdateWidget(StoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        _selectedCategory = _parseInitialCategory(widget.initialCategory);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashSaleTimer.cancel();
    super.dispose();
  }

  void _showMockPurchase(BuildContext context, String item) {
    SoundService.playSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD54F), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Purchased: $item! (Mock IAP)',
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1E16), // Cozy Dark Wood
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFDF5E6), size: 28),
        title: Text(
          'VILLAGE MERCHANT',
          style: TextStyle(
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            color: const Color(0xFFFFD54F),
            fontSize: 26,
            letterSpacing: 2.5,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, user, child) {
          return Column(
            children: [
              // 1. Live Currency Bar (Coins, Hints, Stars)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildCurrencyHeader(user),
              ),

              // 2. Organized Category Tabs (All, Coins, Hints, Bundles)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildCategoryTabs(),
              ),

              // 3. Scrollable Categorized Inventory
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    // Flash Sale (If Saturday active)
                    if (_timeLeft.inSeconds > 0 &&
                        (_selectedCategory == StoreCategory.all || _selectedCategory == StoreCategory.bundles)) ...[
                      _buildFlashSale(user, context),
                      const SizedBox(height: 18),
                    ],

                    // --- SECTION 1: COINS VAULT (Most wanted for village progression) ---
                    if (_selectedCategory == StoreCategory.all || _selectedCategory == StoreCategory.coins) ...[
                      _buildSectionHeader(
                        icon: Icons.monetization_on_rounded,
                        title: 'COIN VAULT',
                        subtitle: 'Upgrade cottages & build landmarks',
                        accentColor: const Color(0xFFFFD54F),
                      ),
                      const SizedBox(height: 10),

                      // Acorn Piggy Bank / Vault Card
                      _buildAcornVaultStoreCard(user, context),
                      const SizedBox(height: 12),

                      // Free Daily Coins via Rewarded Ad
                      _buildStoreItem(
                        title: 'Free Daily Coins',
                        description: user.canClaimDailyCoinsAd
                            ? 'Watch a quick video to claim 50 free coins.'
                            : 'Claimed today • Resets tomorrow at midnight.',
                        icon: Icons.play_circle_fill_rounded,
                        iconColor: user.canClaimDailyCoinsAd ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                        badgeText: user.canClaimDailyCoinsAd ? 'FREE DAILY' : 'CLAIMED',
                        badgeColor: user.canClaimDailyCoinsAd ? const Color(0xFF4CAF50) : const Color(0xFF616161),
                        buttonText: user.canClaimDailyCoinsAd ? 'WATCH' : 'CLAIMED',
                        buttonColor: user.canClaimDailyCoinsAd ? const Color(0xFF7CB342) : const Color(0xFF757575),
                        buttonHighlight: user.canClaimDailyCoinsAd ? const Color(0xFFAED581) : const Color(0xFF9E9E9E),
                        buttonShadow: user.canClaimDailyCoinsAd ? const Color(0xFF33691E) : const Color(0xFF424242),
                        onTap: !user.canClaimDailyCoinsAd
                            ? null
                            : () {
                                AdService.showRewardedAd(
                                  user,
                                  onReward: () {
                                    user.recordDailyCoinsAdClaim();
                                    user.addCoins(50);
                                    _showMockPurchase(context, '50 Free Coins');
                                  },
                                );
                              },
                      ),
                      const SizedBox(height: 12),

                      // 250 Coins
                      _buildStoreItem(
                        title: 'Handful of Coins',
                        description: '250 Coins • Quick boost for small repairs.',
                        icon: Icons.monetization_on_outlined,
                        iconColor: const Color(0xFFFFB74D),
                        buttonText: '\$0.99',
                        buttonColor: const Color(0xFFF6A000),
                        buttonHighlight: const Color(0xFFFFD54F),
                        buttonShadow: const Color(0xFFB97700),
                        onTap: () {
                          user.addCoins(250);
                          _showMockPurchase(context, '250 Coins');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 750 Coins
                      _buildStoreItem(
                        title: 'Pouch of Coins',
                        description: '750 Coins • Great for unlocking new plots.',
                        icon: Icons.paid_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        buttonText: '\$1.99',
                        buttonColor: const Color(0xFFF6A000),
                        buttonHighlight: const Color(0xFFFFD54F),
                        buttonShadow: const Color(0xFFB97700),
                        onTap: () {
                          user.addCoins(750);
                          _showMockPurchase(context, '750 Coins');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2,000 Coins
                      _buildStoreItem(
                        title: 'Chest of Coins',
                        description: '2,000 Coins • Upgrade cottages to Lv.3!',
                        icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: '+25% BONUS',
                        badgeColor: const Color(0xFFE65100),
                        buttonText: '\$3.99',
                        buttonColor: const Color(0xFFF57C00),
                        buttonHighlight: const Color(0xFFFFB74D),
                        buttonShadow: const Color(0xFFB95000),
                        isFeatured: true,
                        onTap: () {
                          user.addCoins(2000);
                          _showMockPurchase(context, '2,000 Coins');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5,000 Coins
                      _buildStoreItem(
                        title: 'Sack of Treasures',
                        description: '5,000 Coins • Expand your village rapidly.',
                        icon: Icons.savings_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: 'MOST POPULAR ⭐',
                        badgeColor: const Color(0xFFC2185B),
                        buttonText: '\$6.99',
                        buttonColor: const Color(0xFFE91E63),
                        buttonHighlight: const Color(0xFFF48FB1),
                        buttonShadow: const Color(0xFF880E4F),
                        isFeatured: true,
                        onTap: () {
                          user.addCoins(5000);
                          _showMockPurchase(context, '5,000 Coins');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 12,000 Coins
                      _buildStoreItem(
                        title: 'Village Vault',
                        description: '12,000 Coins • Build the entire village with ease!',
                        icon: Icons.account_balance_rounded,
                        iconColor: const Color(0xFFFFD700),
                        badgeText: 'BEST VALUE 👑',
                        badgeColor: const Color(0xFF6A1B9A),
                        buttonText: '\$11.99',
                        buttonColor: const Color(0xFF7B1FA2),
                        buttonHighlight: const Color(0xFFBA68C8),
                        buttonShadow: const Color(0xFF4A148C),
                        isPremium: true,
                        onTap: () {
                          user.addCoins(12000);
                          _showMockPurchase(context, '12,000 Coins');
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- SECTION 2: HINTS & POWER-SOLVERS ---
                    if (_selectedCategory == StoreCategory.all || _selectedCategory == StoreCategory.hints) ...[
                      _buildSectionHeader(
                        icon: Icons.tips_and_updates_rounded,
                        title: 'HINTS & POWER-SOLVERS',
                        subtitle: 'Never get stuck on challenging math crosswords',
                        accentColor: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(height: 10),

                      // Free Hint (Watch Ad)
                      _buildStoreItem(
                        title: 'Free Regular Hint',
                        description: user.canClaimDailyHintAd
                            ? 'Watch a quick ad to earn 1 regular clue.'
                            : 'Claimed today • Resets tomorrow at midnight.',
                        icon: Icons.play_circle_fill_rounded,
                        iconColor: user.canClaimDailyHintAd ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                        badgeText: user.canClaimDailyHintAd ? 'FREE DAILY' : 'CLAIMED',
                        badgeColor: user.canClaimDailyHintAd ? const Color(0xFF4CAF50) : const Color(0xFF616161),
                        buttonText: user.canClaimDailyHintAd ? 'WATCH' : 'CLAIMED',
                        buttonColor: user.canClaimDailyHintAd ? const Color(0xFF7CB342) : const Color(0xFF757575),
                        buttonHighlight: user.canClaimDailyHintAd ? const Color(0xFFAED581) : const Color(0xFF9E9E9E),
                        buttonShadow: user.canClaimDailyHintAd ? const Color(0xFF33691E) : const Color(0xFF424242),
                        onTap: !user.canClaimDailyHintAd
                            ? null
                            : () {
                                AdService.showRewardedAd(
                                  user,
                                  onReward: () {
                                    user.recordDailyHintAdClaim();
                                    user.addHint();
                                    _showMockPurchase(context, '1 Free Hint');
                                  },
                                );
                              },
                      ),
                      const SizedBox(height: 12),

                      // 10 Regular Hints
                      _buildStoreItem(
                        title: '10 Regular Hints',
                        description: 'Reveals numbers directly on selected blank cells.',
                        icon: Icons.lightbulb_rounded,
                        iconColor: const Color(0xFFFFB74D),
                        buttonText: '\$0.99',
                        buttonColor: const Color(0xFFF6A000),
                        buttonHighlight: const Color(0xFFFFD54F),
                        buttonShadow: const Color(0xFFB97700),
                        onTap: () {
                          user.addHint(10);
                          _showMockPurchase(context, '10 Regular Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 30 Regular Hints
                      _buildStoreItem(
                        title: '30 Regular Hints',
                        description: 'Steady solver pack for difficult campaign levels.',
                        icon: Icons.lightbulb_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: 'POPULAR',
                        badgeColor: const Color(0xFFF57C00),
                        buttonText: '\$1.99',
                        buttonColor: const Color(0xFFF6A000),
                        buttonHighlight: const Color(0xFFFFD54F),
                        buttonShadow: const Color(0xFFB97700),
                        onTap: () {
                          user.addHint(30);
                          _showMockPurchase(context, '30 Regular Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 75 Regular Hints
                      _buildStoreItem(
                        title: '75 Regular Hints',
                        description: 'Ultimate hint stash. Solve without stress.',
                        icon: Icons.tips_and_updates_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: 'BEST VALUE',
                        badgeColor: const Color(0xFF2E7D32),
                        buttonText: '\$3.99',
                        buttonColor: const Color(0xFF43A047),
                        buttonHighlight: const Color(0xFF81C784),
                        buttonShadow: const Color(0xFF1B5E20),
                        isFeatured: true,
                        onTap: () {
                          user.addHint(75);
                          _showMockPurchase(context, '75 Regular Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5 Mega Hints
                      _buildStoreItem(
                        title: '5 Mega Hints ⭐',
                        description: 'Instantly solves 1 FULL equation on the active board!',
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        badgeText: 'MEGA',
                        badgeColor: const Color(0xFFF57F17),
                        buttonText: '\$1.99',
                        buttonColor: const Color(0xFFF57F17),
                        buttonHighlight: const Color(0xFFFFEE58),
                        buttonShadow: const Color(0xFFBC5100),
                        onTap: () {
                          user.addMegaHint(5);
                          _showMockPurchase(context, '5 Mega Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 15 Mega Hints
                      _buildStoreItem(
                        title: '15 Mega Hints ⭐⭐',
                        description: 'Solves 15 entire equations! Ideal for Expert mode.',
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFFFFD700),
                        badgeText: '+20% BONUS',
                        badgeColor: const Color(0xFFE65100),
                        buttonText: '\$4.99',
                        buttonColor: const Color(0xFFE65100),
                        buttonHighlight: const Color(0xFFFFB74D),
                        buttonShadow: const Color(0xFFAC1900),
                        isFeatured: true,
                        onTap: () {
                          user.addMegaHint(15);
                          _showMockPurchase(context, '15 Mega Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 3 Ultra Hints
                      _buildStoreItem(
                        title: '3 Ultra Hints 💎',
                        description: 'Power solver! Instantly completes 2 full equations.',
                        icon: Icons.diamond_rounded,
                        iconColor: const Color(0xFF00E5FF),
                        badgeText: '2X POWER',
                        badgeColor: const Color(0xFF00838F),
                        buttonText: '\$2.99',
                        buttonColor: const Color(0xFF00ACC1),
                        buttonHighlight: const Color(0xFF4DD0E1),
                        buttonShadow: const Color(0xFF006064),
                        onTap: () {
                          user.addUltraHint(3);
                          _showMockPurchase(context, '3 Ultra Hints');
                        },
                      ),
                      const SizedBox(height: 12),

                      // 8 Ultra Hints
                      _buildStoreItem(
                        title: '8 Ultra Hints 💎💎',
                        description: 'Super solver gem! Clears 16 equations across games.',
                        icon: Icons.diamond_rounded,
                        iconColor: const Color(0xFF00E5FF),
                        badgeText: 'ULTRA 👑',
                        badgeColor: const Color(0xFF006064),
                        buttonText: '\$5.99',
                        buttonColor: const Color(0xFF00838F),
                        buttonHighlight: const Color(0xFF4DD0E1),
                        buttonShadow: const Color(0xFF004D40),
                        isPremium: true,
                        onTap: () {
                          user.addUltraHint(8);
                          _showMockPurchase(context, '8 Ultra Hints');
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- SECTION 3: SPECIAL BUNDLES & PERKS ---
                    if (_selectedCategory == StoreCategory.all || _selectedCategory == StoreCategory.bundles) ...[
                      _buildSectionHeader(
                        icon: Icons.card_giftcard_rounded,
                        title: 'SPECIAL BUNDLES & PERKS',
                        subtitle: 'Best value packages to supercharge progress',
                        accentColor: const Color(0xFFA78BFA),
                      ),
                      const SizedBox(height: 10),

                      // Welcome Acorn Starter Pack ($0.99 Impulse Deal)
                      _buildStoreItem(
                        title: 'Welcome Acorn Pack',
                        description: user.hasPurchasedWelcomePack
                            ? 'Claimed! 1,000 Coins + 10 Hints + 2 Mega + 1 Ultra.'
                            : '1,000 Coins + 10 Hints + 2 Mega + 1 Ultra! (90% OFF)',
                        icon: Icons.savings_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: user.hasPurchasedWelcomePack ? 'CLAIMED' : '90% OFF ⚡',
                        badgeColor: user.hasPurchasedWelcomePack ? const Color(0xFF616161) : const Color(0xFFE53935),
                        buttonText: user.hasPurchasedWelcomePack ? 'OWNED' : '\$0.99',
                        buttonColor: user.hasPurchasedWelcomePack ? const Color(0xFF9E9E9E) : const Color(0xFFE53935),
                        buttonHighlight: user.hasPurchasedWelcomePack ? const Color(0xFFBDBDBD) : const Color(0xFFFF8A80),
                        buttonShadow: user.hasPurchasedWelcomePack ? const Color(0xFF616161) : const Color(0xFFB71C1C),
                        isFeatured: !user.hasPurchasedWelcomePack,
                        onTap: user.hasPurchasedWelcomePack
                            ? null
                            : () {
                                user.purchaseWelcomePack();
                                _showMockPurchase(context, 'Welcome Acorn Pack');
                              },
                      ),
                      const SizedBox(height: 12),

                      // Cozy Village Starter Pack
                      _buildStoreItem(
                        title: 'Cozy Starter Pack',
                        description: '1,500 Coins + 25 Hints + 3 Mega Hints! (60% OFF)',
                        icon: Icons.all_inclusive_rounded,
                        iconColor: const Color(0xFFFFD54F),
                        badgeText: '60% OFF 🏷️',
                        badgeColor: const Color(0xFFD32F2F),
                        buttonText: '\$2.99',
                        buttonColor: const Color(0xFFE53935),
                        buttonHighlight: const Color(0xFFEF9A9A),
                        buttonShadow: const Color(0xFFB71C1C),
                        isFeatured: true,
                        onTap: () {
                          user.addCoins(1500);
                          user.addHint(25);
                          user.addMegaHint(3);
                          _showMockPurchase(context, 'Cozy Starter Pack');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Remove Ads
                      _buildStoreItem(
                        title: 'Remove Ads',
                        description: 'Play uninterrupted forever. Removes all interstitial popups.',
                        icon: Icons.block_rounded,
                        iconColor: const Color(0xFFE57373),
                        badgeText: user.adsRemoved ? 'OWNED' : 'PERMANENT',
                        badgeColor: user.adsRemoved ? const Color(0xFF616161) : const Color(0xFF1976D2),
                        buttonText: user.adsRemoved ? 'BOUGHT' : '\$2.99',
                        buttonColor: user.adsRemoved ? const Color(0xFF9E9E9E) : const Color(0xFF1E88E5),
                        buttonHighlight: user.adsRemoved ? const Color(0xFFBDBDBD) : const Color(0xFF64B5F6),
                        buttonShadow: user.adsRemoved ? const Color(0xFF616161) : const Color(0xFF0D47A1),
                        onTap: user.adsRemoved
                            ? null
                            : () {
                                user.removeAds();
                                _showMockPurchase(context, 'Remove Ads');
                              },
                      ),
                      const SizedBox(height: 12),

                      // Master Village Bundle
                      _buildStoreItem(
                        title: 'Master Village Bundle',
                        description: '8,000 Coins + 50 Hints + 5 Ultra Hints + No Ads!',
                        icon: Icons.workspace_premium_rounded,
                        iconColor: const Color(0xFFFFD700),
                        badgeText: 'ULTIMATE PACK 👑',
                        badgeColor: const Color(0xFF4A148C),
                        buttonText: '\$9.99',
                        buttonColor: const Color(0xFF6A1B9A),
                        buttonHighlight: const Color(0xFFBA68C8),
                        buttonShadow: const Color(0xFF311B92),
                        isPremium: true,
                        onTap: () {
                          user.addCoins(8000);
                          user.addHint(50);
                          user.addUltraHint(5);
                          if (!user.adsRemoved) user.removeAds();
                          _showMockPurchase(context, 'Master Village Bundle');
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      (StoreCategory.all, 'ALL', Icons.apps_rounded),
      (StoreCategory.coins, 'COINS', Icons.monetization_on_rounded),
      (StoreCategory.hints, 'HINTS', Icons.tips_and_updates_rounded),
      (StoreCategory.bundles, 'BUNDLES', Icons.card_giftcard_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2723),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5D4037), width: 2),
      ),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.$1 == _selectedCategory;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                SoundService.playClick();
                setState(() => _selectedCategory = cat.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFD54F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.$3,
                        size: 14,
                        color: isSelected ? const Color(0xFF3E2723) : const Color(0xFFD7CCC8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cat.$2,
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          fontSize: 12,
                          color: isSelected ? const Color(0xFF3E2723) : const Color(0xFFD7CCC8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2723),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBCAAA4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyHeader(UserProvider user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2723),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrencyPill(Icons.monetization_on_rounded, const Color(0xFFFFD54F), user.coins.toString(), 'Coins'),
          _buildCurrencyPill(Icons.lightbulb_rounded, const Color(0xFFFFB74D), user.hintsRegular.toString(), 'Hints'),
          _buildCurrencyPill(Icons.star_rounded, const Color(0xFFFFD700), user.hintsMega.toString(), 'Mega'),
          _buildCurrencyPill(Icons.diamond_rounded, const Color(0xFF00E5FF), user.hintsUltra.toString(), 'Ultra'),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill(IconData icon, Color color, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                color: Colors.white,
                fontSize: 15,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFBCAAA4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1E16).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF5252), width: 1.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD54F), size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'LIMITED FLASH SALE',
                      style: TextStyle(
                        fontFamily: GoogleFonts.lilitaOne().fontFamily,
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1.2,
                        shadows: const [Shadow(color: Color(0xFFFF5252), blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                  ),
                  child: Text(
                    '${_timeLeft.inHours.toString().padLeft(2, '0')}:${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Starter Power Bundle: 100 Hints + Remove All Ads!',
              style: TextStyle(
                color: Color(0xFFFDF5E6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                user.addHint(100);
                if (!user.adsRemoved) user.removeAds();
                _showMockPurchase(context, 'Flash Starter Bundle');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, offset: Offset(0, 4), blurRadius: 0),
                  ],
                ),
                child: Center(
                  child: Text(
                    '\$3.99 (50% OFF)',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: const Color(0xFF3E2723),
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ).animate(controller: _pulseController).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02)),
          ],
        ),
      ),
    );
  }

  Widget _buildAcornVaultStoreCard(UserProvider user, BuildContext context) {
    final vaultCoins = user.acornVaultCoins;
    final maxCoins = UserProvider.acornVaultMax;
    final threshold = UserProvider.acornVaultThreshold;
    final progress = (vaultCoins / maxCoins).clamp(0.0, 1.0);
    final canCrack = user.canCrackAcornVault;
    final isFull = user.isAcornVaultFull;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AcornVaultDialog(user: user),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E2723), Color(0xFF261205)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: canCrack ? const Color(0xFFFFD54F) : const Color(0xFF8B5A2B),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFB45309)],
                      ),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Color(0xFFFFFBEB), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Acorn Piggy Bank',
                              style: TextStyle(
                                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                                fontSize: 16,
                                color: const Color(0xFFFFFBEB),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: canCrack ? const Color(0xFF2E7D32) : const Color(0xFF5D4037),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFull ? 'FULL' : (canCrack ? 'READY' : 'SAVING'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$vaultCoins / $maxCoins Bonus Coins Saved',
                            style: TextStyle(
                              fontFamily: GoogleFonts.baloo2().fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canCrack)
                    GestureDetector(
                      onTap: () {
                        final cracked = user.crackAcornVault();
                        _showMockPurchase(context, 'Acorn Vault ($cracked Coins)');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF1B5E20), offset: Offset(0, 3), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          'CRACK\n\$1.49',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: GoogleFonts.lilitaOne().fontFamily,
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 0.8,
                            height: 1.1,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E342E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6D4C41), width: 1.5),
                      ),
                      child: Text(
                        '${threshold - vaultCoins} to unlock',
                        style: TextStyle(
                          fontFamily: GoogleFonts.baloo2().fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBCAAA4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 10,
                  width: double.infinity,
                  color: const Color(0xFF2E1A11),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFF59E0B)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    String? badgeText,
    Color? badgeColor,
    bool isFeatured = false,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    final borderColor = isPremium
        ? const Color(0xFFFFD54F)
        : (isFeatured ? const Color(0xFFFFB74D) : const Color(0xFF8B5A2B));

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 5),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6), // Parchment
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isPremium ? const Color(0xFFFFF9C4) : const Color(0xFFD7CCC8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: GoogleFonts.lilitaOne().fontFamily,
                          color: const Color(0xFF5D4037),
                          fontSize: 15.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor ?? const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chunky AAA Wood/Gold Button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: buttonShadow, width: 2),
                  boxShadow: [
                    BoxShadow(color: buttonShadow, offset: const Offset(0, 3), blurRadius: 0),
                    BoxShadow(color: buttonHighlight, offset: const Offset(0, -2), spreadRadius: -1),
                  ],
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 1.0,
                    shadows: const [
                      Shadow(color: Colors.black45, offset: Offset(0, 1.5), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
