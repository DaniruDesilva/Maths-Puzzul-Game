import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CustomPuzzleScreenState extends State<CustomPuzzleScreen> with SingleTickerProviderStateMixin {
  Difficulty _selectedDifficulty = Difficulty.medium;
  final TextEditingController _seedController = TextEditingController();
  bool _isExplaining = false;
  late AnimationController _diceController;

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _generateRandomSeed();
    _seedController.addListener(_onSeedChanged);
  }

  void _onSeedChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _diceController.dispose();
    _seedController.removeListener(_onSeedChanged);
    _seedController.dispose();
    super.dispose();
  }

  void _generateRandomSeed() {
    final seed = Random().nextInt(900000) + 100000;
    _seedController.text = seed.toString();
    _diceController.forward(from: 0.0);
  }

  int _getCurrentSeed() {
    final text = _seedController.text.trim();
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) return parsed;
    return 123456;
  }

  String _buildCurrentShareCode() {
    final seed = _getCurrentSeed();
    return MathPuzzleCodec.encodeSeed(
      difficulty: _selectedDifficulty,
      seed: seed,
      id: 999,
    );
  }

  void _playPuzzle() {
    final code = _buildCurrentShareCode();
    final provider = Provider.of<GameProvider>(context, listen: false);
    final success = provider.startCustomSeed(code);
    if (success) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not generate puzzle with this seed. Please try another seed.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _copyShareCode() {
    final code = _buildCurrentShareCode();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 8),
            Text('Copied $code to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePuzzle() {
    final code = _buildCurrentShareCode();
    SharePlus.instance.share(
      ShareParams(
        text: '🧩 Play my custom Number Haven math crossword puzzle!\n\n'
            'Difficulty: ${_selectedDifficulty.displayName}\n'
            'Seed: ${_getCurrentSeed()}\n'
            'Code: $code\n\n'
            'Open Number Haven -> Custom Puzzle -> "ENTER A CODE" and paste this code to play the exact same puzzle!',
      ),
    );
  }

  Color _getDifficultyColor(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return const Color(0xFF10B981); // Emerald
      case Difficulty.medium:
        return const Color(0xFFF59E0B); // Amber
      case Difficulty.hard:
        return const Color(0xFFF97316); // Orange
      case Difficulty.expert:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  String _getDifficultySpecs(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return '5×5 Grid  •  4 Equations  •  2-3 Blanks  •  Addition & Subtraction';
      case Difficulty.medium:
        return '7×7 Grid  •  6 Equations  •  4-5 Blanks  •  Add, Sub & Multiply';
      case Difficulty.hard:
        return '9×9 Grid  •  8 Equations  •  6-7 Blanks  •  Multi-operation Intersections';
      case Difficulty.expert:
        return '11×11 Grid  •  11 Equations  •  8+ Blanks  •  Master Mind Logic';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getDifficultyColor(_selectedDifficulty);
    final currentCode = _buildCurrentShareCode();

    return Scaffold(
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
            letterSpacing: 2.2,
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFFFFD54F), size: 26),
            tooltip: 'How Custom Puzzles Work',
            onPressed: () => _showHowItWorksDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tagline & Quick Guide Banner
              const Text(
                'Craft & Share Crossmath Puzzles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create infinite procedural math crosswords or challenge friends to solve the exact same board!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 14),

              // 2. Expandable "What is a Seed?" Explainer Card
              _buildExplainerBanner(),

              const SizedBox(height: 18),

              // 3. Difficulty Segment Selector
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: Difficulty.values.map((diff) {
                    final isSelected = diff == _selectedDifficulty;
                    final diffColor = _getDifficultyColor(diff);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = diff),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? diffColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: diffColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              diff.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // 4. Difficulty Spec Preview Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: activeColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDifficultySpecs(_selectedDifficulty),
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Seed & Code Configuration Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF334155), width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'PUZZLE SEED NUMBER',
                                  style: TextStyle(
                                    color: Color(0xFFF2C94C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DNA KEY',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _generateRandomSeed,
                          child: RotationTransition(
                            turns: _diceController,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF38BDF8),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Seed textfield
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fingerprint_rounded, color: Color(0xFF64748B), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _seedController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                              ],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter 1-8 digits...',
                                hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Share Code Banner with Copy Action
                    GestureDetector(
                      onTap: _copyShareCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SHARE CODE (TAP TO COPY)',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentCode,
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildActionButton(
                      text: 'PLAY NOW',
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF10B981),
                      onTap: _playPuzzle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: _buildActionButton(
                      text: 'SHARE CODE',
                      icon: Icons.share_rounded,
                      color: const Color(0xFF0F766E),
                      onTap: _sharePuzzle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                text: 'ENTER A CODE FROM FRIEND',
                icon: Icons.input_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => _showEnterCodeDialog(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplainerBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFD54F), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'How do Custom Puzzles work?',
                  style: TextStyle(
                    color: Color(0xFFFDF5E6),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isExplaining = !_isExplaining),
                child: Text(
                  _isExplaining ? 'Hide' : 'Learn More',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_isExplaining) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 10),
            _buildExplainerPoint(
              icon: Icons.fingerprint_rounded,
              title: 'Seed = Puzzle DNA',
              description: 'The seed number uniquely calculates all equations and grid intersections so it is 100% reproducible.',
            ),
            const SizedBox(height: 8),
            _buildExplainerPoint(
              icon: Icons.people_alt_rounded,
              title: 'Play Identical Boards',
              description: 'Friends who enter the same Share Code get the EXACT same puzzle. See who solves it faster with fewer hints!',
            ),
            const SizedBox(height: 8),
            _buildExplainerPoint(
              icon: Icons.refresh_rounded,
              title: 'Infinite Puzzles',
              description: 'Tap the refresh button anytime to generate an endless variety of brand-new challenges.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplainerPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(color: Color(0xFFFDF5E6), fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF475569), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_center_rounded, color: Color(0xFFFFD54F), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'HOW SEEDS WORK',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '• What is a Seed Number?\n'
                'In Number Haven, each puzzle is created mathematically using an RNG Seed. The seed acts as a recipe key: the same seed always produces the exact same crossword layout, equations, and answer blanks.\n\n'
                '• How do I play with friends?\n'
                '1. Pick your preferred difficulty and seed.\n'
                '2. Tap "SHARE CODE" or "Copy Code".\n'
                '3. Send the code (e.g. NH1-X-999-816268) to your friend.\n'
                '4. Your friend enters that code in "ENTER A CODE".\n'
                '5. You both solve the identical puzzle!',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'GOT IT!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scaleXY(begin: 0.85, end: 1.0, duration: 250.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _showEnterCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final rawInput = codeController.text.trim();
          final parsed = MathPuzzleCodec.decodeSeed(rawInput);
          final isValid = parsed != null;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF475569), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ENTER PUZZLE CODE',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 22,
                      color: const Color(0xFFFFD54F),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Paste a code or full message shared by a friend',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),

                  // Text input container with Paste button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isValid
                            ? const Color(0xFF10B981)
                            : (rawInput.isEmpty ? const Color(0xFF334155) : const Color(0xFFEF4444)),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            onChanged: (_) => setDialogState(() {}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. NH1-X-999-816268',
                              hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.paste_rounded, color: Color(0xFF38BDF8), size: 22),
                          tooltip: 'Paste from Clipboard',
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              codeController.text = data!.text!;
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Live Validation / Status indicator
                  if (isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Valid: ${parsed.difficulty.displayName} • Seed ${parsed.seed}',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (rawInput.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF450A0A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Format must be: NH1-[E/M/H/X]-[ID]-[SEED]',
                              style: TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          text: 'CANCEL',
                          icon: Icons.close_rounded,
                          color: const Color(0xFF64748B),
                          onTap: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          text: 'PLAY',
                          icon: Icons.play_arrow_rounded,
                          color: isValid ? const Color(0xFF10B981) : const Color(0xFF334155),
                          onTap: () {
                            if (parsed != null) {
                              Navigator.pop(dialogContext);
                              final provider = Provider.of<GameProvider>(context, listen: false);
                              final success = provider.startCustomSeed(rawInput);
                              if (success) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not generate puzzle with this code.'),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid code format! Example: NH1-X-999-816268'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().scaleXY(begin: 0.85, end: 1.0, duration: 250.ms, curve: Curves.easeOutBack);
        },
      ),
    );
  }
}
