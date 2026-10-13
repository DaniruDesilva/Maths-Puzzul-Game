import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/user_provider.dart';
import '../../../services/sound_service.dart';

class AcornVaultDialog extends StatefulWidget {
  final UserProvider user;

  const AcornVaultDialog({super.key, required this.user});

  @override
  State<AcornVaultDialog> createState() => _AcornVaultDialogState();
}

class _AcornVaultDialogState extends State<AcornVaultDialog> {
  bool _isCracked = false;
  int _collectedAmount = 0;

  void _crackVault() {
    if (!widget.user.canCrackAcornVault) return;

    SoundService.playSuccess();
    HapticFeedback.heavyImpact();

    final cracked = widget.user.crackAcornVault();
    setState(() {
      _isCracked = true;
      _collectedAmount = cracked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultCoins = widget.user.acornVaultCoins;
    final maxCoins = UserProvider.acornVaultMax;
    final threshold = UserProvider.acornVaultThreshold;
    final progress = (vaultCoins / maxCoins).clamp(0.0, 1.0);
    final canCrack = widget.user.canCrackAcornVault;
    final isFull = widget.user.isAcornVaultFull;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              // 1. Header Ribbon
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
                            const Icon(Icons.savings_rounded, color: Color(0xFFFFD54F), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'ACORN PIGGY BANK',
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
                      onTap: () => Navigator.pop(context),
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

              const SizedBox(height: 16),

              // 2. Acorn Hero Artwork
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFB45309)],
                  ),
                  border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB45309).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.savings_rounded,
                    color: Color(0xFFFFFBEB),
                    size: 56,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                    begin: 1.0,
                    end: 1.05,
                    duration: 1.8.seconds,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 14),

              // 3. Vault Balance Number
              Text(
                _isCracked ? '+$_collectedAmount COINS COLLECTED!' : '$vaultCoins / $maxCoins COINS',
                style: GoogleFonts.lilitaOne(
                  color: _isCracked ? const Color(0xFF2E7D32) : const Color(0xFF5D4037),
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _isCracked
                  ? 'All coins transferred to your main wallet!'
                  : (isFull
                      ? 'Vault is FULL! Crack now to collect maximum savings.'
                      : 'Solve equations to store +5 bonus coins per solve.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  color: const Color(0xFF7A451A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // 4. Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 18,
                  width: double.infinity,
                  color: const Color(0xFFD7CCC8),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: _isCracked ? 0.0 : progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFF59E0B)],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _isCracked
                            ? 'EMPTY'
                            : '${(progress * 100).toInt()}% ${isFull ? '(FULL)' : ''}',
                          style: GoogleFonts.lilitaOne(
                            color: const Color(0xFF4E342E),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Action Button
              if (_isCracked)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7CB342),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFAED581), width: 2.2),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF33691E), offset: Offset(0, 4), blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'CONTINUE PLAYING',
                          style: GoogleFonts.lilitaOne(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (canCrack)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _crackVault,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1B5E20),
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open_rounded, color: Color(0xFFFFD54F), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'CRACK VAULT (\$1.49)',
                              style: GoogleFonts.lilitaOne(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().shimmer(duration: 2.seconds, color: Colors.white24)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF9E9E9E), width: 2),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'UNLOCKS AT $threshold COINS (${threshold - vaultCoins} LEFT)',
                        style: GoogleFonts.lilitaOne(
                          color: const Color(0xFF424242),
                          fontSize: 14,
                          letterSpacing: 1.0,
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
}
