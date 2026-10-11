import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/village_data.dart';
import '../../../providers/user_provider.dart';

class BuildSheet extends StatelessWidget {
  final BuildingDef buildingDef;

  const BuildSheet({super.key, required this.buildingDef});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) {
        int currentStage = user.villageBuildings[buildingDef.id] ?? 0;
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
                    color: Colors.grey,
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
                
                // Stage indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMaxed ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMaxed ? 'MAX LEVEL' : 'UPGRADE TO STAGE ${currentStage + 1}',
                    style: TextStyle(
                      color: isMaxed ? Colors.green[800] : Colors.blue[800],
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
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Building Perk',
                        style: TextStyle(
                          color: Colors.grey,
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Button
                if (!isMaxed)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canAfford
                          ? () {
                              user.spendCoins(cost);
                              user.upgradeBuilding(buildingDef.id);
                              Navigator.pop(context); // Close sheet
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: canAfford ? 4 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!canAfford)
                            const Text(
                              'NOT ENOUGH ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                                letterSpacing: 1,
                              ),
                            )
                          else
                            const Text(
                              'BUILD FOR ',
                              style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: canAfford ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
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
