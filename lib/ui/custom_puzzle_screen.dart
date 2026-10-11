import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class CustomPuzzleScreen extends StatefulWidget {
  const CustomPuzzleScreen({super.key});

  @override
  State<CustomPuzzleScreen> createState() => _CustomPuzzleScreenState();
}

class _CustomPuzzleScreenState extends State<CustomPuzzleScreen> {
  final TextEditingController _wordsController = TextEditingController();
  
  void _playPuzzle() {
    final words = _getWords();
    if (words.isEmpty) {
      _showError('Please enter at least one word.');
      return;
    }
    if (words.join('').length > 64) {
      _showError('Too many letters! Maximum is 64.');
      return;
    }
    
    // Start custom level and navigate to game screen
    Provider.of<GameProvider>(context, listen: false).startCustomLevel(words);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
  
  void _sharePuzzle() {
    final words = _getWords();
    if (words.isEmpty) {
      _showError('Please enter at least one word.');
      return;
    }
    if (words.join('').length > 64) {
      _showError('Too many letters! Maximum is 64.');
      return;
    }
    
    // Encode words to a short alphanumeric code (Base64)
    final text = words.join(',');
    final code = base64Url.encode(utf8.encode(text));
    
    SharePlus.instance.share(
      ShareParams(
        text: 'Play my custom Word Haven puzzle!\n\n'
            'Code: $code\n\n'
            'Download Word Haven: Cozy Village and enter this code to play!',
      ),
    );
  }
  
  List<String> _getWords() {
    final text = _wordsController.text.toUpperCase();
    return text
        .split(RegExp(r'[,\n\s]+'))
        .where((w) => w.isNotEmpty && RegExp(r'^[A-Z]+$').hasMatch(w))
        .toList();
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFD99B9B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF2C1E16), // Dark Wood
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFDF5E6), size: 32),
        title: Text(
          'CREATE',
          style: TextStyle(
            fontFamily: GoogleFonts.lilitaOne().fontFamily,
            color: const Color(0xFFFFD54F),
            fontSize: 32,
            letterSpacing: 3,
            shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4)],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Custom Puzzle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GoogleFonts.lilitaOne().fontFamily,
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 1.5,
                shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 2)],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter words separated by commas or spaces. We will generate a hexagonal grid for you and your friends.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF5E6), // Parchment
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5A2B), width: 4), // Thick wood border
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 8))],
                ),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _wordsController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    color: const Color(0xFF5D4037),
                    fontSize: 24,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CAT, DOG, BIRD...',
                    hintStyle: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      color: const Color(0xFFD7CCC8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildButton('PLAY NOW', const Color(0xFF7CB342), _playPuzzle),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButton('SHARE CODE', const Color(0xFF00ACC1), _sharePuzzle),
                ),
              ],
            ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            _buildButton('ENTER A CODE', const Color(0xFFF6A000), () => _showEnterCodeDialog(context))
                .animate().slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack),
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
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 0)],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: GoogleFonts.lilitaOne().fontFamily,
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 1.2,
              shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
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
            color: const Color(0xFFFDF5E6), // Parchment
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 4), // Thick wood border
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ENTER CODE',
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 28,
                  color: const Color(0xFF5D4037),
                  letterSpacing: 2,
                  shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5A2B), width: 2),
                ),
                child: TextField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GoogleFonts.lilitaOne().fontFamily,
                    color: const Color(0xFF5D4037),
                    fontSize: 22,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Paste here...',
                    hintStyle: TextStyle(color: Color(0xFFD7CCC8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildButton('CANCEL', const Color(0xFFE53935), () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton('PLAY', const Color(0xFF7CB342), () {
                      try {
                        final text = utf8.decode(base64Url.decode(codeController.text.trim()));
                        final words = text.split(',');
                        if (words.isNotEmpty) {
                          if (words.join('').length > 64) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('This puzzle is too massive to play!'), backgroundColor: Color(0xFFE53935)),
                            );
                            return;
                          }
                          Navigator.pop(context); // Close dialog
                          Provider.of<GameProvider>(context, listen: false).startCustomLevel(words);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid code!'), backgroundColor: Color(0xFFE53935)),
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
