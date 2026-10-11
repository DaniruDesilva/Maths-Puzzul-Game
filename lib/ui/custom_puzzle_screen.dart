import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../engine/math/models.dart';
import '../engine/math/puzzle_codec.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class CustomPuzzleScreen extends StatefulWidget {
  const CustomPuzzleScreen({super.key});

  @override
  State<CustomPuzzleScreen> createState() => _CustomPuzzleScreenState();
}

class _CustomPuzzleScreenState extends State<CustomPuzzleScreen> {
  Difficulty _selectedDifficulty = Difficulty.medium;
  final TextEditingController _seedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateRandomSeed();
  }

  void _generateRandomSeed() {
    final seed = Random().nextInt(900000) + 100000;
    _seedController.text = seed.toString();
  }

  String _buildCurrentShareCode() {
    final seed = int.tryParse(_seedController.text.trim()) ?? 12345;
    return MathPuzzleCodec.encodeSeed(
      difficulty: _selectedDifficulty,
      seed: seed,
      id: 999,
    );
  }

  void _playPuzzle() {
    final code = _buildCurrentShareCode();
    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.startCustomSeed(code);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _sharePuzzle() {
    final code = _buildCurrentShareCode();
    SharePlus.instance.share(
      ShareParams(
        text: 'Play my custom Number Haven math crossword puzzle!\n\n'
            'Difficulty: ${_selectedDifficulty.displayName}\n'
            'Code: $code\n\n'
            'Download Number Haven: Cozy Math Village and enter this code to play!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0F1E28),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFDF5E6), size: 28),
        title: Text(
          'CUSTOM PUZZLE',
          style: TextStyle(
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            color: const Color(0xFFFFD54F),
            fontSize: 26,
            letterSpacing: 2.5,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4)
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Craft & Share Crossmath Puzzles',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your difficulty and seed, or paste a code from a friend to solve their challenge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Difficulty Segment Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 1.5),
              ),
              child: Row(
                children: Difficulty.values.map((diff) {
                  final isSelected = diff == _selectedDifficulty;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = diff),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            diff.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Seed display / card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PUZZLE SEED NUMBER',
                    style: TextStyle(
                      color: Color(0xFFF2C94C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _seedController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter seed...',
                            hintStyle: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 28),
                        onPressed: _generateRandomSeed,
                        tooltip: 'Randomize Seed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Share Code: ${_buildCurrentShareCode()}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: _buildButton('PLAY NOW', const Color(0xFF10B981), _playPuzzle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildButton('SHARE CODE', const Color(0xFF0F766E), _sharePuzzle),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildButton('ENTER A CODE', const Color(0xFFF59E0B), () => _showEnterCodeDialog(context)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
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

  void _showEnterCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              const Text(
                'ENTER PUZZLE CODE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: TextField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. NH1-H-42-1002',
                    hintStyle: TextStyle(color: Color(0xFF475569)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildButton('CANCEL', const Color(0xFFEF4444), () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton('PLAY', const Color(0xFF10B981), () {
                      final input = codeController.text.trim();
                      final parsed = MathPuzzleCodec.decodeSeed(input);
                      if (parsed != null) {
                        Navigator.pop(context);
                        final provider = Provider.of<GameProvider>(context, listen: false);
                        provider.startCustomSeed(input);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid code format! Example: NH1-M-1-12345'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    }),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}
