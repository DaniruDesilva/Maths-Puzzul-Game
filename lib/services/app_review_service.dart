import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppReviewService {
  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.creatorboxstudios.numberhaven';
  static const String playStoreMarketUrl =
      'market://details?id=com.creatorboxstudios.numberhaven';
  static const String feedbackEmail = 'creatorboxstudios@gmail.com';

  /// Opens Google Play Store directly to the Number Haven review/listing page
  static Future<void> openPlayStore() async {
    final marketUri = Uri.parse(playStoreMarketUrl);
    final webUri = Uri.parse(playStoreWebUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch play store URL: $e');
    }
  }

  /// Opens the device email client to send direct feedback
  static Future<void> sendFeedback() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {
        'subject': 'Number Haven Feedback & Ideas (v1.0.4)',
        'body': 'Hi CreatorBox Studios team,\n\nHere is my feedback for Number Haven:\n',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web link or store
        await openPlayStore();
      }
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  /// Checks if we should display the milestone review prompt
  static Future<bool> shouldPromptMilestoneReview(int completedLevel) async {
    // Only prompt on key achievement levels: Level 5, 15, 30
    if (completedLevel != 5 && completedLevel != 15 && completedLevel != 30) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    if (hasRated) return false;

    final lastPromptLevel = prefs.getInt('last_prompt_review_level') ?? 0;
    if (lastPromptLevel == completedLevel) return false;

    return true;
  }

  /// Marks that the user completed rating or permanently dismissed
  static Future<void> markRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated_app', true);
  }

  /// Records that the prompt was shown at this level
  static Future<void> recordPromptLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_prompt_review_level', level);
  }

  /// Displays the cozy in-app rating prompt dialog
  static Future<void> showMilestoneRatingDialog(
    BuildContext context, {
    required int level,
    VoidCallback? onComplete,
  }) async {
    await recordPromptLevel(level);

    if (!context.mounted) {
      onComplete?.call();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF5E6), // Parchment
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 4),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart / Star Icon Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF3CD),
                  boxShadow: [
                    BoxShadow(color: Color(0xFFFFD54F), blurRadius: 14),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE53935),
                  size: 40,
                ),
              ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),

              const SizedBox(height: 16),

              Text(
                'ENJOYING NUMBER HAVEN?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GoogleFonts.lilitaOne().fontFamily,
                  fontSize: 22,
                  color: const Color(0xFF5D4037),
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // 5 Golden Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 32,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 12),

              Text(
                'Your rating helps our small indie team grow and brings more cozy puzzles & village features to life!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GoogleFonts.nunito().fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D4C41),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 22),

              // Rate 5 Stars Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    await markRated();
                    await openPlayStore();
                  },
                  icon: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                  label: Text(
                    'RATE 5 STARS ⭐',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B), // Golden amber
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ).animate().scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack, duration: 400.ms),

              const SizedBox(height: 10),

              // Remind Later Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D4C41),
                    side: const BorderSide(color: Color(0xFFBCAAA4), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'REMIND ME LATER',
                    style: TextStyle(
                      fontFamily: GoogleFonts.lilitaOne().fontFamily,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // No thanks text button
              TextButton(
                onPressed: () async {
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  await markRated();
                },
                child: Text(
                  'No, thanks',
                  style: TextStyle(
                    fontFamily: GoogleFonts.nunito().fontFamily,
                    fontSize: 12,
                    color: const Color(0xFF8D6E63),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );

    onComplete?.call();
  }
}
