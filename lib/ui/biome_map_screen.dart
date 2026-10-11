import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../data/village_data.dart';

class BiomeMapScreen extends StatelessWidget {
  const BiomeMapScreen({super.key});

  final List<Map<String, dynamic>> _biomes = const [
    {'name': 'Oakheart Village', 'icon': '🌸', 'brainReq': 0, 'color': Color(0xFF689F38), 'startLevel': 1, 'endLevel': 40, 'isImplemented': true}, 
    {'name': 'Tidepool Harbor', 'icon': '🌊', 'brainReq': 3500, 'color': Color(0xFF00ACC1), 'startLevel': 41, 'endLevel': 80, 'isImplemented': false},
    {'name': 'Elderwood Grove', 'icon': '🌲', 'brainReq': 7500, 'color': Color(0xFF2E7D32), 'startLevel': 81, 'endLevel': 120, 'isImplemented': false},
    {'name': 'Frostfall Summit', 'icon': '🏔️', 'brainReq': 11500, 'color': Color(0xFF1976D2), 'startLevel': 121, 'endLevel': 160, 'isImplemented': false},
    {'name': 'Cinderforge Keep', 'icon': '🌋', 'brainReq': 16000, 'color': Color(0xFFD84315), 'startLevel': 161, 'endLevel': 200, 'isImplemented': false},
    {'name': 'Starlight Nexus', 'icon': '✨', 'brainReq': 21000, 'color': Color(0xFF6A1B9A), 'startLevel': 201, 'endLevel': 240, 'isImplemented': false},
    {'name': 'The Silent Abyss', 'icon': '🌀', 'brainReq': 27000, 'color': Color(0xFF37474F), 'startLevel': 241, 'endLevel': 280, 'isImplemented': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2620), // Dark Tavern background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, user, child) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _biomes.length,
                    itemBuilder: (context, index) {
                      final biome = _biomes[index];
                      return _buildBiomeCard(context, biome, user, index)
                          .animate(delay: (100 * index).ms)
                          .slideX(begin: 0.1, curve: Curves.easeOutCubic)
                          .fadeIn();
                    },
                  );
                },
              ),
            ),
          ],
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
              'WORLD MAP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
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

  Widget _buildBiomeCard(BuildContext context, Map<String, dynamic> biome, UserProvider user, int index) {
    bool isImplemented = biome['isImplemented'] as bool? ?? false;
    bool isUnlocked = isImplemented && user.brainSize >= (biome['brainReq'] as int);
    
    int completedInBiome = 0;
    int biomeTotalLevels = 1;
    
    if (biome['name'] == 'Oakheart Village') {
      biomeTotalLevels = VillageData.meadow.buildings.length * 3; // Max stages per building
      for (var b in VillageData.meadow.buildings) {
        completedInBiome += user.villageBuildings[b.id] ?? 0;
      }
    } else {
      int startLevel = biome['startLevel'] as int;
      int endLevel = biome['endLevel'] as int;
      biomeTotalLevels = endLevel - startLevel + 1;
      completedInBiome = (user.levelsCompleted - (startLevel - 1)).clamp(0, biomeTotalLevels);
    }
    
    double progress = completedInBiome / biomeTotalLevels.toDouble();
    Color biomeColor = biome['color'] as Color;

    return GestureDetector(
      onTap: () {
        if (!isImplemented) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${biome['name']} is coming soon in a future update!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4E342E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }

        if (isUnlocked) {
          if (biome['name'] == 'Oakheart Village') {
            Navigator.pushNamed(context, '/village', arguments: VillageData.meadow);
          } else {
            Navigator.pushNamed(context, '/packList', arguments: biome);
          }
        } else {
          // Locked bounce effect instead of just a snackbar
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Requires ${biome['brainReq']} Brain Size to unlock!', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF4E342E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 160,
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFFFFF3E0) : const Color(0xFF3E2723), // Parchment vs dark wood
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked ? biomeColor.withValues(alpha: 0.8) : const Color(0xFF2D1A11),
            width: 4,
          ),
          boxShadow: isUnlocked ? [
            BoxShadow(color: biomeColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4)),
            const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 6)),
          ] : const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background visual (Emoji watermark)
            Positioned(
              right: -20,
              bottom: -30,
              child: Opacity(
                opacity: isUnlocked ? 0.35 : 0.05,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Text(
                    biome['icon'] as String,
                    style: const TextStyle(fontSize: 150),
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          biome['name'] as String,
                          style: TextStyle(
                            color: isUnlocked ? const Color(0xFF3E2723) : const Color(0xFF795548),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (!isImplemented)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1A11),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8D6E63).withValues(alpha: 0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_clock_rounded, color: Color(0xFFFFB74D), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'COMING SOON',
                                style: TextStyle(
                                  color: Color(0xFFFFB74D),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1A11),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5D4037)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, color: Color(0xFFBCAAA4), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${biome['brainReq']}',
                                style: const TextStyle(color: Color(0xFFBCAAA4), fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.psychology_rounded, color: Color(0xFFF48FB1), size: 18),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (isUnlocked) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}% Restored',
                          style: TextStyle(
                            color: biomeColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: biomeColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2))],
                          ),
                          child: Text(
                            progress == 1.0 ? 'COMPLETED' : 'ENTER',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Chunky Custom Progress Bar
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1A11), // Dark wood trough
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black38, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.white12, offset: Offset(0, 1))],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: biomeColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                    ),
                  ] else if (!isImplemented) ...[
                    Row(
                      children: [
                        Icon(Icons.construction_rounded, color: const Color(0xFF8D6E63).withValues(alpha: 0.7), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'New village in development',
                          style: TextStyle(
                            color: const Color(0xFF8D6E63).withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
