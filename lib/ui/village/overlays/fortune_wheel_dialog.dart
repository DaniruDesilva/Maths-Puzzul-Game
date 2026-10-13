import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/user_provider.dart';
import '../../../services/ad_service.dart';
import '../../../services/sound_service.dart';

enum PrizeType { tryAgain, coins, hint, megaHint, ultraHint }

class WheelPrize {
  final String label;
  final PrizeType type;
  final int amount;
  final IconData icon;
  final Color color;
  final Color textColor;

  const WheelPrize({
    required this.label,
    required this.type,
    required this.amount,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
  });
}

class FortuneWheelDialog extends StatefulWidget {
  final UserProvider user;

  const FortuneWheelDialog({super.key, required this.user});

  @override
  State<FortuneWheelDialog> createState() => _FortuneWheelDialogState();
}

class _FortuneWheelDialogState extends State<FortuneWheelDialog> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  final List<WheelPrize> _prizes = const [
    WheelPrize(
      label: '50 Coins',
      type: PrizeType.coins,
      amount: 50,
      icon: Icons.monetization_on_rounded,
      color: Color(0xFF2E7D32),
    ),
    WheelPrize(
      label: 'Try Again',
      type: PrizeType.tryAgain,
      amount: 0,
      icon: Icons.replay_rounded,
      color: Color(0xFF5D4037),
      textColor: Color(0xFFFFD54F),
    ),
    WheelPrize(
      label: '100 Coins',
      type: PrizeType.coins,
      amount: 100,
      icon: Icons.monetization_on_rounded,
      color: Color(0xFF0288D1),
    ),
    WheelPrize(
      label: '1 Hint',
      type: PrizeType.hint,
      amount: 1,
      icon: Icons.lightbulb_rounded,
      color: Color(0xFFE65100),
    ),
    WheelPrize(
      label: '250 Coins',
      type: PrizeType.coins,
      amount: 250,
      icon: Icons.monetization_on_rounded,
      color: Color(0xFF7B1FA2),
    ),
    WheelPrize(
      label: '500 Coins',
      type: PrizeType.coins,
      amount: 500,
      icon: Icons.stars_rounded,
      color: Color(0xFFFFB300),
      textColor: Color(0xFF3E2723),
    ),
  ];

  double _currentRotation = 0.0;
  bool _isSpinning = false;
  bool _isWatchingAd = false;
  WheelPrize? _wonPrize;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinTheWheel({bool isFree = false}) {
    if (_isSpinning) return;

    if (isFree) {
      widget.user.recordFreeSpin();
    }

    setState(() {
      _isSpinning = true;
      _wonPrize = null;
    });

    SoundService.playClick();
    HapticFeedback.mediumImpact();

    // Weighted selection:
    // Sector 0 (50 Coins): 30%
    // Sector 1 (Try Again): 25%
    // Sector 2 (100 Coins): 20%
    // Sector 3 (1 Hint): 13%
    // Sector 4 (250 Coins): 8%
    // Sector 5 (500 Coins): 4%
    // Total = 100%
    // Lower rewards / Try Again: 75% of the time. Higher rewards: rare.
    final weights = [30, 25, 20, 13, 8, 4];
    final random = math.Random();
    int roll = random.nextInt(100);
    int winningIndex = 0;
    for (int i = 0; i < weights.length; i++) {
      if (roll < weights[i]) {
        winningIndex = i;
        break;
      }
      roll -= weights[i];
    }

    final targetPrize = _prizes[winningIndex];

    // Mathematical alignment with Top Pointer:
    // Wheel has N segments, each segment is 2*pi / N radians.
    // In Canvas.drawArc, segment 0 starts at 0 rad (3 o'clock) and extends clockwise.
    // The top pointer is positioned at 12 o'clock, which is 270 degrees = 1.5 * pi radians.
    // To position segment 'winningIndex' directly beneath the 12 o'clock pointer:
    // (segmentCenter + targetRotation) % 2*pi == 1.5 * pi
    // targetRotation == (1.5 * pi - segmentCenter) % 2*pi
    final segmentAngle = (2 * math.pi) / _prizes.length;
    final segmentCenter = winningIndex * segmentAngle + (segmentAngle / 2);
    final targetFinalAngle = (1.5 * math.pi - segmentCenter) % (2 * math.pi);
    final normalizedTarget = targetFinalAngle < 0 ? targetFinalAngle + 2 * math.pi : targetFinalAngle;

    // Calculate clockwise delta from current wheel orientation so multiple spins never jump or drift:
    final currentNorm = _currentRotation % (2 * math.pi);
    double forwardDelta = normalizedTarget - currentNorm;
    while (forwardDelta < 0) {
      forwardDelta += 2 * math.pi;
    }

    // Add 5 to 7 full 360-degree rotations for realistic spinning deceleration:
    final extraFullSpins = (5 + random.nextInt(3)) * 2 * math.pi;
    final totalDelta = extraFullSpins + forwardDelta;
    final endRotation = _currentRotation + totalDelta;

    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));

    _spinController.reset();
    _spinController.forward().then((_) {
      _currentRotation = endRotation % (2 * math.pi);
      _grantPrize(targetPrize);
    });
  }

  void _grantPrize(WheelPrize prize) {
    if (prize.type == PrizeType.tryAgain) {
      SoundService.playThwack();
      HapticFeedback.mediumImpact();
    } else {
      switch (prize.type) {
        case PrizeType.coins:
          widget.user.addCoins(prize.amount);
          break;
        case PrizeType.hint:
          widget.user.addHint(prize.amount);
          break;
        case PrizeType.megaHint:
          widget.user.addMegaHint(prize.amount);
          break;
        case PrizeType.ultraHint:
          widget.user.addUltraHint(prize.amount);
          break;
        case PrizeType.tryAgain:
          break;
      }
      SoundService.playSuccess();
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _isSpinning = false;
      _wonPrize = prize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.user,
      builder: (context, _) {
        final canFreeSpin = widget.user.canClaimFreeSpin;

        return PopScope(
          canPop: !_isSpinning && !_isWatchingAd,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFDF5), Color(0xFFFFF3DB)],
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
                    // Top Ribbon Header
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'VILLAGE FORTUNE WHEEL',
                                    style: GoogleFonts.lilitaOne(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 12.5,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: (_isSpinning || _isWatchingAd) ? null : () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5A2B),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF5D4037), width: 2),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 12),

              Text(
                'Spin daily for cozy coins and hints!',
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  color: const Color(0xFF7A451A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              // The Wheel Area
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Brass Rim
                    Container(
                      width: 246,
                      height: 246,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFB45309)],
                        ),
                        border: Border.all(color: const Color(0xFF5D4037), width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),

                    // Rotating Wheel Segments
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        final rotation = _isSpinning ? _spinAnimation.value : _currentRotation;
                        return Transform.rotate(
                          angle: rotation,
                          child: CustomPaint(
                            size: const Size(230, 230),
                            painter: _WheelPainter(prizes: _prizes),
                          ),
                        );
                      },
                    ),

                    // Center Brass Hub
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFFFD54F), Color(0xFF8B5A2B)],
                        ),
                        border: Border.all(color: const Color(0xFF5D4037), width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.star_rounded, color: Color(0xFF5D4037), size: 28),
                      ),
                    ),

                    // Top Pointer Ticker
                    Positioned(
                      top: 0,
                      child: CustomPaint(
                        size: const Size(24, 28),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Won Prize Celebration Card
              if (_wonPrize != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _wonPrize!.type == PrizeType.tryAgain
                          ? [const Color(0xFF5D4037), const Color(0xFF3E2723)]
                          : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _wonPrize!.type == PrizeType.tryAgain
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFFFD54F),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _wonPrize!.type == PrizeType.tryAgain
                            ? Icons.replay_rounded
                            : _wonPrize!.icon,
                        color: const Color(0xFFFFD54F),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _wonPrize!.type == PrizeType.tryAgain
                              ? 'SO CLOSE! TRY AGAIN! 🍀'
                              : 'YOU WON: ${_wonPrize!.label}!',
                          style: GoogleFonts.lilitaOne(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                const SizedBox(height: 14),
              ],

              // Spin Buttons
              if (canFreeSpin)
                _buildSpinButton(
                  label: 'FREE DAILY SPIN',
                  subtitle: 'Available once every 24h',
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFF7CB342),
                  highlight: const Color(0xFFAED581),
                  shadow: const Color(0xFF33691E),
                  onTap: _isSpinning ? null : () => _spinTheWheel(isFree: true),
                )
              else if (widget.user.canClaimAdSpin)
                _buildSpinButton(
                  label: _isWatchingAd
                      ? 'LOADING AD...'
                      : (_wonPrize?.type == PrizeType.tryAgain
                          ? 'TRY AGAIN (WATCH AD)'
                          : 'SPIN AGAIN (WATCH AD)'),
                  subtitle: _isWatchingAd
                      ? 'Please wait a moment...'
                      : 'Watch video • ${widget.user.remainingAdSpinsToday} of ${UserProvider.maxDailyAdSpins} ad spins left today',
                  icon: _isWatchingAd ? Icons.hourglass_top_rounded : Icons.videocam_rounded,
                  color: const Color(0xFFF59E0B),
                  highlight: const Color(0xFFFDE68A),
                  shadow: const Color(0xFFB45309),
                  onTap: (_isSpinning || _isWatchingAd)
                      ? null
                      : () {
                          if (!widget.user.canClaimAdSpin) return;
                          setState(() => _isWatchingAd = true);
                          AdService.showRewardedAd(
                            widget.user,
                            onReward: () {
                              if (!mounted) return;
                              widget.user.recordAdSpin();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isSpinning) {
                                  _spinTheWheel(isFree: false);
                                }
                              });
                            },
                            onDismissed: () {
                              if (mounted) {
                                setState(() => _isWatchingAd = false);
                              }
                            },
                          );
                        },
                )
              else
                _buildSpinButton(
                  label: 'DAILY SPINS COMPLETED',
                  subtitle: 'Daily limit reached (0/${UserProvider.maxDailyAdSpins}). Resets tomorrow!',
                  icon: Icons.lock_clock_rounded,
                  color: const Color(0xFF5D4037),
                  highlight: const Color(0xFF8B5A2B),
                  shadow: const Color(0xFF3E2723),
                  onTap: null,
                ),
            ],
          ),
        ),
      ),
    ),
  );
},
);
}

  Widget _buildSpinButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color highlight,
    required Color shadow,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDisabled ? const Color(0xFF616161) : color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDisabled ? const Color(0xFF757575) : highlight,
              width: 2.2,
            ),
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: shadow,
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: GoogleFonts.lilitaOne(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.baloo2(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelPrize> prizes;

  _WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / prizes.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFFFFBEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = i * sweepAngle;
      paint.color = prizes[i].color;

      // Draw wedge
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw divider line
      final x = center.dx + radius * math.cos(startAngle);
      final y = center.dy + radius * math.sin(startAngle);
      canvas.drawLine(center, Offset(x, y), linePaint);

      // Draw prize label
      final midAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(midAngle);
      final textY = center.dy + textRadius * math.sin(midAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(midAngle + math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i].label,
          style: TextStyle(
            color: prizes[i].textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom point pointing down to wheel
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => false;
}
