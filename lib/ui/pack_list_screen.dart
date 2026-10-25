import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class PackListScreen extends StatelessWidget {
  final Map<String, dynamic> biome;
  const PackListScreen({super.key, required this.biome});

  @override
  Widget build(BuildContext context) {
    String biomeName = biome['name'] ?? 'Unknown';
    int startLevel = biome['startLevel'] ?? 1;
    int endLevel = biome['endLevel'] ?? 40;
    
    // Create 4 packs based on start and end level
    int levelsPerPack = (endLevel - startLevel + 1) ~/ 4;
    List<Map<String, dynamic>> packs = [];
    for (int i = 0; i < 4; i++) {
      int pStart = startLevel + (i * levelsPerPack);
      int pEnd = pStart + levelsPerPack - 1;
      packs.add({
        'name': 'Area ${i + 1}',
        'levels': levelsPerPack,
        'startLevel': pStart,
        'endLevel': pEnd,
      });
    }

    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final isDark = user.darkModeEnabled;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF14110E) : const Color(0xFFF1F5DD),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: isDark ? const Color(0xFFECEFF1) : const Color(0xFF4A4A4A)),
            title: Text(
              biomeName.toUpperCase(),
              style: TextStyle(
                color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFF2C3E35),
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFF2C94C), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${user.coins}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFF2C3E35),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- VILLAGE SECTION ---
              Text(
                'Your Village',
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF8A9A95),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _buildVillage(context, user, biomeName, isDark: isDark),
              const SizedBox(height: 32),
              
              // --- PACKS SECTION ---
              Text(
                'Exploration',
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF8A9A95),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              ...packs.map((pack) {
                int pStart = pack['startLevel'];
                int pEnd = pack['endLevel'];
                int levelsInPack = pEnd - pStart + 1;
                int completedInPack = (user.levelsCompleted - (pStart - 1)).clamp(0, levelsInPack);
                double progress = completedInPack / levelsInPack.toDouble();
                bool isUnlocked = user.levelsCompleted >= (pStart - 1);
                
                return GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      Navigator.pushNamed(context, '/levelList', arguments: pack);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isDark ? const Color(0xFF241C15) : Colors.white)
                          : (isDark ? const Color(0xFF1A1410) : const Color(0xFFF9F6F0)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF4E382A) : const Color(0xFFE8E3D2)),
                      boxShadow: [
                        if (isUnlocked)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pack['name'],
                              style: TextStyle(
                                color: isUnlocked
                                    ? (isDark ? const Color(0xFFFFE0B2) : const Color(0xFF2C3E35))
                                    : (isDark ? const Color(0xFF757575) : const Color(0xFFB0B0B0)),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isUnlocked)
                              Icon(Icons.lock_outline, color: isDark ? const Color(0xFF757575) : const Color(0xFFB0B0B0), size: 18)
                            else
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF8A9A95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark ? const Color(0xFF2C221B) : const Color(0xFFF9F6F0),
                          color: isUnlocked ? const Color(0xFF81C784) : (isDark ? const Color(0xFF5D4037) : const Color(0xFFD6D1C4)),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVillage(BuildContext context, UserProvider user, String biomeName, {bool isDark = false}) {
    // 3 Buildings per village
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBuilding(context, user, biomeName, 'Bakery', '🥖', 100, 1, isDark: isDark),
        _buildBuilding(context, user, biomeName, 'Windmill', '🌾', 150, 0, isDark: isDark),
        _buildBuilding(context, user, biomeName, 'Tower', '🏰', 300, 2, isDark: isDark),
      ],
    );
  }
  
  Widget _buildBuilding(BuildContext context, UserProvider user, String biomeName, String name, String icon, int baseCost, int rewardType, {bool isDark = false}) {
    String bId = '${biomeName}_$name';
    int level = user.villageBuildings[bId] ?? 0;
    int cost = baseCost + (level * 50);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _showBuildingModal(context, user, bId, name, icon, cost, level, rewardType, isDark: isDark);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF241C15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF4E382A) : const Color(0xFFE8E3D2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 32, color: level == 0 ? Colors.grey.withValues(alpha: 0.3) : null)),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFF2C3E35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                level > 0 ? 'Lv. $level' : 'Build',
                style: TextStyle(
                  fontSize: 11,
                  color: level > 0 ? const Color(0xFF81C784) : const Color(0xFFD99B9B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuildingModal(BuildContext context, UserProvider user, String bId, String name, String icon, int cost, int level, int rewardType, {bool isDark = false}) {
    String rewardDesc = rewardType == 0 ? 'Generates passive Coins' : (rewardType == 1 ? 'Generates free Hints' : 'Generates Mega Hints');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF241C15) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            '$icon $name',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFF2C3E35),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Level $level', style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                rewardDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFFECEFF1) : const Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 24),
              if (level < 5)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2C94C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    if (user.spendCoins(cost)) {
                      user.upgradeBuilding(bId);
                      Navigator.pop(ctx);
                    } else {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!'), backgroundColor: Color(0xFFD99B9B)));
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Upgrade ($cost)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                const Text('MAX LEVEL', style: TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
