import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum HandPointerDirection {
  tapping,      // Tilted ~ -28° (classic casual game touchscreen tap, arm from bottom-right)
  pointingDown, // Pointing straight down (arm from above, great for buttons & tray tiles)
  pointingUp,   // Pointing straight up (arm from below)
  pointingLeft, // Pointing towards left
  pointingRight // Pointing towards right
}

/// A premium, casual-game-styled cartoon pointer hand inspired by top games (Royal Match, Gardenscapes, Candy Crush).
/// Features a crisp white cartoon glove with glossy highlights, springy tap bounce physics,
/// and concentric expanding touch shockwave ripples emitted precisely from the fingertip contact point.
class CartoonHandPointer extends StatefulWidget {
  final HandPointerDirection direction;
  final double size;
  final bool showRipple;
  final String? label;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const CartoonHandPointer({
    super.key,
    this.direction = HandPointerDirection.tapping,
    this.size = 56.0,
    this.showRipple = true,
    this.label,
    this.onTap,
    this.onDismiss,
  });

  /// Calculates the exact pixel offset of the pointing index fingertip relative to the
  /// top-left of the CartoonHandPointer widget (when label is null).
  /// Callers can position the widget so its fingertip touches a target point:
  /// `left: targetX - tipOffset.dx, top: targetY - tipOffset.dy`
  static Offset getFingertipOffset({
    required HandPointerDirection direction,
    required double size,
  }) {
    // In base 100x100 coordinates, glove center is (50, 50) and index fingertip is at (48, 6).
    final baseTipDx = -0.02 * size;
    final baseTipDy = -0.44 * size;

    double angle = 0.0;
    switch (direction) {
      case HandPointerDirection.tapping:
        angle = -math.pi * 0.16; // ~ -29° (pointing up-left)
        break;
      case HandPointerDirection.pointingDown:
        angle = math.pi; // 180° (pointing straight down)
        break;
      case HandPointerDirection.pointingUp:
        angle = 0.0;
        break;
      case HandPointerDirection.pointingLeft:
        angle = -math.pi * 0.5;
        break;
      case HandPointerDirection.pointingRight:
        angle = math.pi * 0.5;
        break;
    }

    final tipDx = baseTipDx * math.cos(angle) - baseTipDy * math.sin(angle);
    final tipDy = baseTipDx * math.sin(angle) + baseTipDy * math.cos(angle);
    final center = size * 0.75;
    return Offset(center + tipDx, center + tipDy);
  }

  @override
  State<CartoonHandPointer> createState() => _CartoonHandPointerState();
}

class _CartoonHandPointerState extends State<CartoonHandPointer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // 0.0 -> 0.35: Hand glides from hover position into the target contact point
    // 0.35 -> 0.45: Contact! Hand compresses slightly (tap impact) and ripple triggers
    // 0.45 -> 1.0: Hand rebounds with a subtle springy overshoot back to hover
    _pressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 53,
      ),
    ]).animate(_controller);

    // Ripple expands from the moment of contact (0.35 -> 0.90)
    _rippleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.92, curve: Curves.easeOutCubic),
    );

    _rippleOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.95, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pressFactor = _pressAnimation.value;
          final rippleFactor = _rippleAnimation.value;
          final rippleOpacity = _rippleOpacityAnimation.value.clamp(0.0, 1.0);

          // Determine base pointing angle and hover offset vector
          // Note: In base coords, glove finger points straight UP (0 rad), wrist is DOWN (+Y).
          double angle = 0.0;
          double hoverDx = 0.0;
          double hoverDy = 0.0;

          switch (widget.direction) {
            case HandPointerDirection.tapping:
              // Natural right-hand touchscreen tap: finger points top-left (~-30°), arm extends down-right
              angle = -math.pi * 0.16; // ~ -29°
              // Hover pulled back along arm axis (down and right)
              hoverDx = 10.0 * (1.0 - pressFactor);
              hoverDy = 10.0 * (1.0 - pressFactor);
              break;
            case HandPointerDirection.pointingDown:
              // Finger points straight down (180°), arm extends UP (-Y)
              angle = math.pi;
              // Hover pulled back upwards (-Y)
              hoverDx = 0.0;
              hoverDy = -12.0 * (1.0 - pressFactor);
              break;
            case HandPointerDirection.pointingUp:
              // Finger points straight up (0°), arm extends DOWN (+Y)
              angle = 0.0;
              // Hover pulled back downwards (+Y)
              hoverDx = 0.0;
              hoverDy = 12.0 * (1.0 - pressFactor);
              break;
            case HandPointerDirection.pointingLeft:
              angle = -math.pi * 0.5; // -90°
              hoverDx = 12.0 * (1.0 - pressFactor);
              hoverDy = 0.0;
              break;
            case HandPointerDirection.pointingRight:
              angle = math.pi * 0.5; // +90°
              hoverDx = -12.0 * (1.0 - pressFactor);
              hoverDy = 0.0;
              break;
          }

          // Elastic compression squish on tap impact
          final double squish = 1.0 - (0.07 * pressFactor);

          // Calculate precise contact point of the fingertip inside the 1.5x stack
          final baseTipDx = -0.02 * widget.size;
          final baseTipDy = -0.44 * widget.size;
          final tipDx = baseTipDx * math.cos(angle) - baseTipDy * math.sin(angle);
          final tipDy = baseTipDx * math.sin(angle) + baseTipDy * math.cos(angle);
          final center = widget.size * 0.75;
          final contactX = center + tipDx;
          final contactY = center + tipDy;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2E1C11),
                        Color(0xFF1E130B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      const BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label!,
                        style: GoogleFonts.lilitaOne(
                          color: const Color(0xFFFFD54F),
                          fontSize: 12.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.onDismiss != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: const Icon(Icons.close_rounded, color: Color(0xFFE2E8F0), size: 14),
                        ),
                      ],
                    ],
                  ),
                ),

              // The animated hand canvas + contact shockwave ripples
              SizedBox(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Concentric touch shockwave ripples emitted exactly from contact point
                    if (widget.showRipple && _controller.value >= 0.35)
                      Positioned(
                        left: contactX - 28,
                        top: contactY - 28,
                        child: CustomPaint(
                          size: const Size(56, 56),
                          painter: _TouchRipplePainter(
                            progress: rippleFactor,
                            opacity: rippleOpacity,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ),

                    // Cartoon Hand Glove
                    Transform.translate(
                      offset: Offset(hoverDx, hoverDy),
                      child: Transform.rotate(
                        angle: angle,
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: squish,
                          child: CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: const _CartoonGlovePainter(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for the expanding touch shockwave ripple rings
class _TouchRipplePainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Color color;

  _TouchRipplePainter({
    required this.progress,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.48;

    // Contact spark flash at instant of tap
    if (progress < 0.25) {
      final sparkOpacity = (1.0 - (progress / 0.25)) * opacity;
      final sparkPaint = Paint()
        ..color = Colors.white.withValues(alpha: sparkOpacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 4.0 + progress * 8.0, sparkPaint);
    }

    // Ring 1 (Leading wave)
    final r1 = 4.0 + (maxRadius - 4.0) * progress;
    final paint1 = Paint()
      ..color = color.withValues(alpha: opacity * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * (1.0 - (progress * 0.45));
    canvas.drawCircle(center, r1, paint1);

    // Ring 2 (Secondary echo wave, delayed)
    if (progress > 0.20) {
      final p2 = (progress - 0.20) / 0.80;
      final r2 = 3.0 + (maxRadius * 0.72) * p2;
      final paint2 = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.75 * (1.0 - p2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, r2, paint2);
    }
  }

  @override
  bool shouldRepaint(_TouchRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

/// Draws an iconic casual-game white cartoon glove with index finger pointing,
/// comic-book style dark bold outline, palm shading, wrist cuff, and glove stitches.
class _CartoonGlovePainter extends CustomPainter {
  const _CartoonGlovePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Scale normalized 100x100 canvas
    final scale = w / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Soft drop shadow to lift the glove off the background
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
    canvas.drawOval(const Rect.fromLTWH(20, 52, 60, 28), shadowPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF0F172A) // Dark slate outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // Crisp pure white highlight
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0), // Volumetric soft shadow
        ],
        stops: [0.0, 0.50, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    // Vector Path of the iconic casual cartoon glove
    final glovePath = Path();

    // 1. Tip of pointing index finger
    glovePath.moveTo(48, 6);
    // Index finger tip curve
    glovePath.cubicTo(56, 6, 58, 14, 58, 22);
    // Right side of index finger down to knuckle
    glovePath.lineTo(58, 44);

    // 2. Middle finger (curled into fist)
    glovePath.cubicTo(68, 42, 78, 44, 78, 54);
    glovePath.cubicTo(78, 60, 70, 62, 64, 62);

    // 3. Ring finger (curled into fist)
    glovePath.cubicTo(72, 62, 78, 64, 78, 72);
    glovePath.cubicTo(78, 78, 70, 80, 62, 80);

    // 4. Pinky finger (curled into fist)
    glovePath.cubicTo(70, 80, 74, 82, 74, 88);
    glovePath.cubicTo(74, 94, 64, 94, 52, 92);

    // 5. Wrist base
    glovePath.lineTo(38, 92);
    glovePath.cubicTo(32, 92, 30, 86, 32, 80);

    // 6. Thumb (curled across palm)
    glovePath.cubicTo(20, 78, 16, 68, 20, 58);
    glovePath.cubicTo(24, 48, 34, 48, 38, 56);

    // 7. Left side of index finger back to tip
    glovePath.lineTo(38, 22);
    glovePath.cubicTo(38, 14, 40, 6, 48, 6);
    glovePath.close();

    // Fill glove body
    canvas.drawPath(glovePath, fillPaint);

    // Finger separation creases (adds cartoon depth)
    final creasePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Crease between index and middle
    canvas.drawLine(const Offset(58, 45), const Offset(50, 49), creasePaint);
    // Crease between middle and ring
    canvas.drawLine(const Offset(64, 62), const Offset(54, 64), creasePaint);
    // Crease between ring and pinky
    canvas.drawLine(const Offset(62, 80), const Offset(52, 80), creasePaint);
    // Thumb inner knuckle fold
    canvas.drawLine(const Offset(32, 60), const Offset(38, 66), creasePaint);

    // 3 classic casual-game glove stitches on back of hand
    final stitchPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 68), const Offset(43, 78), stitchPaint);
    canvas.drawLine(const Offset(46, 67), const Offset(49, 79), stitchPaint);
    canvas.drawLine(const Offset(52, 68), const Offset(55, 78), stitchPaint);

    // Draw dark bold outline
    canvas.drawPath(glovePath, outlinePaint);

    // Rolled wrist cuff at base
    final cuffRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 88, 30, 10),
      const Radius.circular(5),
    );
    final cuffFill = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRRect(cuffRect, cuffFill);
    canvas.drawRRect(cuffRect, outlinePaint);

    // Glossy fingertip shine
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(44, 12), const Offset(44, 24), highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A compact, charming speech bubble callout used in tutorials to guide player actions
class TutorialSpeechBubble extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onSkip;
  final IconData? icon;

  const TutorialSpeechBubble({
    super.key,
    required this.title,
    required this.message,
    this.onSkip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1C11),
            Color(0xFF1D1109),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFFFFD54F), size: 16),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lilitaOne(
                    color: const Color(0xFFFFD54F),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (onSkip != null)
                GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip',
                          style: GoogleFonts.baloo2(
                            color: const Color(0xFFE2E8F0),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1), size: 11),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.baloo2(
              color: const Color(0xFFE2E8F0),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
