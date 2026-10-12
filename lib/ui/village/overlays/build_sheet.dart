import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/village_data.dart';
import '../../../providers/user_provider.dart';
import '../../store_screen.dart';

class BuildSheet extends StatelessWidget {
  final BuildingDef buildingDef;

  const BuildSheet({super.key, required this.buildingDef});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        int currentStage = user.villageBuildings[buildingDef.id] ?? 0;
        bool isLocked = currentStage == 0 && user.currentLevel < buildingDef.requiredLevel;
        bool isMaxed = currentStage >= buildingDef.maxStage;
        
        int cost = isMaxed ? 0 : buildingDef.costs[currentStage];
        bool canAfford = user.coins >= cost;
        
        String perkText = '';
        if (isMaxed) {
          perkText = buildingDef.perks.last;
        } else {
          perkText = buildingDef.perks[currentStage];
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF9F7F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buildingDef.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      buildingDef.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C3E35),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stage indicator or Lock indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFFFEF3C7)
                        : (isMaxed ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLocked
                        ? '🔒 UNLOCKS AT LEVEL ${buildingDef.requiredLevel}'
                        : (isMaxed
                            ? 'MAX LEVEL'
                            : (currentStage == 0
                                ? 'READY TO BUILD (STAGE 1)'
                                : 'UPGRADE TO STAGE ${currentStage + 1}')),
                    style: TextStyle(
                      color: isLocked
                          ? const Color(0xFFB45309)
                          : (isMaxed ? Colors.green[800] : Colors.blue[800]),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Perk Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLocked ? const Color(0xFFFDE68A) : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isLocked ? 'Plot Perk Preview' : 'Building Perk',
                        style: TextStyle(
                          color: isLocked ? const Color(0xFFB45309) : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        perkText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF2C3E35),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 12),
                        Text(
                          'You are currently at Level ${user.currentLevel}. Complete Level ${buildingDef.requiredLevel - 1} to unlock this construction plot!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber[900],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // Action Buttons
                if (isLocked) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                      label: Text(
                        'LOCKED (REACH LEVEL ${buildingDef.requiredLevel})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else if (!isMaxed) ...[
                  if (canAfford)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          user.spendCoins(cost);
                          user.upgradeBuilding(buildingDef.id);
                          Navigator.pop(context); // Close sheet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentStage == 0 ? 'BUILD FOR ' : 'UPGRADE FOR ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFF2C94C),
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$cost',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Not enough button
                        Expanded(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'NEED ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black54,
                                  ),
                                ),
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$cost',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Get Coins shortcut to Store
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StoreScreen()),
                            );
                          },
                          icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'GET COINS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                ],
                
                if (isMaxed)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'This building is fully upgraded!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
