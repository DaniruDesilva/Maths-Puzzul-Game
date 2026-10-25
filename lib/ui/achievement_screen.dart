import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';

class AchievementData {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int rewardHints;
  final IconData icon;

  const AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.rewardHints,
    required this.icon,
  });
}

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  static const List<AchievementData> achievements = [
    // Equations Solved
    AchievementData(id: 'words_50', title: 'Math Apprentice', description: 'Solve 50 equations', targetValue: 50, rewardHints: 2, icon: Icons.calculate_outlined),
    AchievementData(id: 'words_250', title: 'Arithmetic Wizard', description: 'Solve 250 equations', targetValue: 250, rewardHints: 5, icon: Icons.calculate_rounded),
    AchievementData(id: 'words_1000', title: 'Crossmath Legend', description: 'Solve 1000 equations', targetValue: 1000, rewardHints: 10, icon: Icons.auto_awesome_rounded),
    // Levels Completed
    AchievementData(id: 'levels_10', title: 'Beginner', description: 'Complete 10 levels', targetValue: 10, rewardHints: 2, icon: Icons.star_border_rounded),
    AchievementData(id: 'levels_50', title: 'Explorer', description: 'Complete 50 levels', targetValue: 50, rewardHints: 5, icon: Icons.star_half_rounded),
    AchievementData(id: 'levels_150', title: 'Conqueror', description: 'Complete 150 levels', targetValue: 150, rewardHints: 10, icon: Icons.star_rounded),
    // Hints Used
    AchievementData(id: 'hints_20', title: 'Need a Hand?', description: 'Use 20 hints', targetValue: 20, rewardHints: 1, icon: Icons.lightbulb_rounded),
    // Streaks
    AchievementData(id: 'streak_3', title: 'Warming Up', description: 'Reach a 3-day streak', targetValue: 3, rewardHints: 3, icon: Icons.local_fire_department_outlined),
    AchievementData(id: 'streak_7', title: 'On Fire', description: 'Reach a 7-day streak', targetValue: 7, rewardHints: 7, icon: Icons.local_fire_department_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2620), // Dark Tavern background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Consumer<UserProvider>(
                    builder: (context, user, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          return _buildAchievementCard(context, achievements[index], user)
                              .animate(delay: (50 * index).ms)
                              .slideY(begin: 0.2, curve: Curves.easeOut)
                              .fadeIn();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4E342E), // Dark wood
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3E2723), width: 2),
                boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF3E0), size: 28),
            ),
          ),
          const Expanded(
            child: Text(
              'ACHIEVEMENTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: Color(0xFFFFB74D), blurRadius: 15),
                  Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 56), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementData achievement, UserProvider user) {
    int currentValue = 0;
    
    if (achievement.id.startsWith('words_')) {
      currentValue = user.wordsFound;
    } else if (achievement.id.startsWith('levels_')) {
      currentValue = user.levelsCompleted;
    } else if (achievement.id.startsWith('hints_')) {
      currentValue = user.hintsUsedTotal;
    } else if (achievement.id.startsWith('streak_')) {
      currentValue = user.dailyStreak;
    }

    bool isUnlocked = currentValue >= achievement.targetValue;
    bool isClaimed = user.claimedAchievements.contains(achievement.id);
    double progress = (currentValue / achievement.targetValue).clamp(0.0, 1.0);

    // Determine colors based on state
    Color bgColor = isClaimed ? const Color(0xFF4DB6AC).withValues(alpha: 0.15) 
                  : (isUnlocked ? const Color(0xFFFFF3E0) : const Color(0xFF4E342E));
    Color borderColor = isClaimed ? const Color(0xFF4DB6AC) 
                      : (isUnlocked ? const Color(0xFFD4A373) : const Color(0xFF3E2723));
    Color titleColor = isClaimed ? const Color(0xFFB2DFDB) 
                     : (isUnlocked ? const Color(0xFF5D4037) : const Color(0xFFFFD54F));
    Color descColor = isClaimed ? const Color(0xFF80CBC4) 
                    : (isUnlocked ? const Color(0xFF8D6E63) : const Color(0xFFBCAAA4));
    Color iconBoxColor = isClaimed ? const Color(0xFF004D40) 
                       : (isUnlocked ? const Color(0xFFFFD54F) : const Color(0xFF3E2723));
    Color iconColor = isClaimed ? const Color(0xFF80CBC4) 
                    : (isUnlocked ? const Color(0xFF5D4037) : const Color(0xFF8D6E63));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black26, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
            ),
            child: Icon(achievement.icon, color: iconColor, size: 36),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(color: descColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                
                // Progress Bar
                if (!isClaimed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: isUnlocked ? const Color(0xFFEFEBE0) : const Color(0xFF2D1A11),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black26, width: 1.5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isUnlocked ? const Color(0xFF7CB342) : const Color(0xFFFFB74D),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), offset: const Offset(0, 2))],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentValue > achievement.targetValue ? achievement.targetValue : currentValue}/${achievement.targetValue}',
                        style: TextStyle(
                          color: isUnlocked ? const Color(0xFF5D4037) : const Color(0xFFFFD54F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Claimed state text
                  const Text(
                    'COMPLETED',
                    style: TextStyle(color: Color(0xFF4DB6AC), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Action Button / Status
          if (isClaimed)
            const Icon(Icons.verified_rounded, color: Color(0xFF4DB6AC), size: 40)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
          else if (isUnlocked)
            GestureDetector(
              onTap: () => user.claimAchievement(achievement.id, achievement.rewardHints),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CB342), // Vibrant green
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF33691E), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CLAIM', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    Text('+${achievement.rewardHints} Hints', style: const TextStyle(color: Color(0xFFDCEDC8), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms)
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 2),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF5D4037), size: 24),
            ),
        ],
      ),
    );
  }
}
