import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';

class LevelListScreen extends StatelessWidget {
  final Map<String, dynamic> pack;
  const LevelListScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    String packName = pack['name'] ?? 'Unknown Area';
    int startLevel = pack['startLevel'] ?? 1;
    int endLevel = pack['endLevel'] ?? 10;
    int levelCount = endLevel - startLevel + 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
        title: Text(packName.toUpperCase(), style: const TextStyle(color: Color(0xFF2C3E35), fontWeight: FontWeight.w600, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, user, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: levelCount,
            itemBuilder: (context, index) {
              int levelNum = startLevel + index;
              bool isUnlocked = levelNum <= user.levelsCompleted + 1;
              bool isCompleted = levelNum <= user.levelsCompleted;

              return GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    var provider = Provider.of<GameProvider>(context, listen: false);
                    provider.startSpecificLevel(levelNum);
                    Navigator.pushNamed(context, '/game');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF87A8A4) : const Color(0xFFE8E3D2),
                      width: isCompleted ? 2 : 1,
                    ),
                    boxShadow: isUnlocked ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ] : [],
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$levelNum',
                                style: TextStyle(
                                  color: isCompleted ? const Color(0xFF2C3E35) : const Color(0xFF4A4A4A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isCompleted) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int s = 0; s < 3; s++)
                                      Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: s < (user.levelStars[levelNum] ?? 1)
                                            ? const Color(0xFFFFB300)
                                            : const Color(0xFFCFD8DC),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : const Icon(Icons.lock_outline, color: Color(0xFFDCE2DF), size: 20),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
