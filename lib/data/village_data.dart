import 'dart:ui';

/// What a building hands out when the player taps its reward bubble.
enum RewardType { coins, hint, megaHint }

class BuildingReward {
  final RewardType type;

  /// Amount granted per bubble for stages 1, 2, 3.
  final List<int> amounts;
  
  /// Generation interval for stages 1, 2, 3.
  final List<Duration> intervals;
  
  final int maxStack;

  const BuildingReward({
    required this.type,
    required this.amounts,
    required this.intervals,
    required this.maxStack,
  });
}

class BuildingDef {
  /// Stable id, persisted as `village_<biomeKey>_<id>`.
  final String id;
  final String name;
  final String emoji;

  final Offset plot;
  
  /// The size at which this building should be drawn on the map.
  final Size spriteSize;

  /// Area (1-4) inside the biome whose start unlocks this plot.
  final int unlockArea;

  /// Player level required to unlock this plot for construction.
  final int requiredLevel;

  /// Coin cost of stages 1, 2 and 3.
  final List<int> costs;

  /// Sprite paths (relative to `assets/images/`) for stages 1..3.
  /// Empty when the art is not ready yet: the plot shows "Coming soon".
  final List<String> sprites;

  /// Per-stage description of what the building does.
  final List<String> perks;
  final BuildingReward? reward;

  /// Villager that moves in once the building reaches stage 1.
  final String? villagerId;

  /// Extra coins per bonus word, multiplied by stage (Library perk).
  final int bonusWordCoinsPerStage;

  /// Chimney position relative to the sprite (0-1), for smoke from stage 2.
  final Offset? chimney;

  /// Whether the sprite needs to be flipped horizontally to connect its door to the road.
  final bool flipHorizontal;

  /// Per-stage flipping overrides. If provided, must match the length of `sprites`.
  final List<bool>? flipStages;
  
  /// Explicit custom position for the signboard (relative to building top-left)
  final Offset? signboardPos;

  const BuildingDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.plot,
    this.spriteSize = const Size(200, 200), // Default logical size for the map
    this.flipHorizontal = false,
    this.flipStages,
    required this.unlockArea,
    this.requiredLevel = 1,
    required this.costs,
    required this.sprites,
    required this.perks,
    this.reward,
    this.villagerId,
    this.bonusWordCoinsPerStage = 0,
    this.chimney,
    this.signboardPos,
  });

  int get maxStage => costs.length;
  bool get hasArt => sprites.length == costs.length;
}

enum VillagerKind { fox, bunny, owl }

class VillagerDef {
  final String id;
  final String name;
  final VillagerKind kind;
  final List<String> lines;

  const VillagerDef({required this.id, required this.name, required this.kind, required this.lines});
}

class VillageDef {
  final String biomeName;
  final String key;
  final String background;
  final Size worldSize;
  final List<BuildingDef> buildings;
  final List<VillagerDef> villagers;

  /// Walkable waypoint graph (cobblestone paths + open grass).
  final List<Offset> waypoints;
  final List<List<int>> edges;

  const VillageDef({
    required this.biomeName,
    required this.key,
    required this.background,
    required this.worldSize,
    required this.buildings,
    required this.villagers,
    required this.waypoints,
    required this.edges,
  });

  List<int> neighbours(int node) => [
        for (final e in edges)
          if (e[0] == node) e[1] else if (e[1] == node) e[0],
      ];

  String buildingKey(BuildingDef b) => '${key}_${b.id}';
}

class VillageData {
  static const meadow = VillageDef(
    biomeName: 'Oakheart Village',
    key: 'meadow',
    background: 'village/meadow/island_bg.webp',
    worldSize: Size(768, 1376),
    buildings: [
      BuildingDef(
        id: 'cottage',
        name: 'Cottage',
        emoji: '🏠',
        plot: Offset(260, 540), // Moved UP and LEFT according to user arrow
        spriteSize: Size(200, 200), // Scaled down to prevent covering roads
        flipHorizontal: true, // Keep flipped for road connection
        unlockArea: 1,
        requiredLevel: 1, // Starter plot
        costs: [100, 250, 500],
        sprites: [
          'village/meadow/cottage_stage1.webp',
          'village/meadow/cottage_stage2.webp',
          'village/meadow/cottage_stage3.webp',
        ],
        perks: [
          'Bunny the farmer moves in • 10 coins every 3h',
          '20 coins every 3h',
          '35 coins every 3h',
        ],
        reward: BuildingReward(
          type: RewardType.coins, 
          amounts: [10, 20, 35], 
          intervals: [Duration(hours: 3), Duration(hours: 3), Duration(hours: 3)], 
          maxStack: 2,
        ),
        villagerId: 'bunny',
        chimney: Offset(0.47, 0.12),
        signboardPos: Offset(40, 160), // Inside Cottage yard, left side
      ),
      BuildingDef(
        id: 'bakery',
        name: 'Bakery',
        emoji: '🍞',
        plot: Offset(530, 540), // Moved up to not cover road
        spriteSize: Size(200, 200), // Scaled down
        flipHorizontal: true, // User requested rotation
        unlockArea: 1,
        requiredLevel: 6, // Unlocks after early starter pack
        costs: [200, 450, 850],
        sprites: [
          'village/meadow/bakery_stage1.webp',
          'village/meadow/bakery_stage2.webp',
          'village/meadow/bakery_stage3.webp',
        ],
        perks: [
          'Fox the baker moves in • 15 coins every 2h',
          '30 coins every 2h',
          '50 coins every 2h',
        ],
        reward: BuildingReward(
          type: RewardType.coins, 
          amounts: [15, 30, 50], 
          intervals: [Duration(hours: 2), Duration(hours: 2), Duration(hours: 2)], 
          maxStack: 3,
        ),
        villagerId: 'fox',
        chimney: Offset(0.70, 0.06),
        signboardPos: Offset(160, 160), // Inside Bakery yard, right side
      ),
      BuildingDef(
        id: 'windmill',
        name: 'Windmill',
        emoji: '🌾',
        plot: Offset(545, 845), // Moved slightly down and left to perfectly align door with road
        spriteSize: Size(230, 230), 
        flipHorizontal: true, // Flipped so the door perfectly faces the cobblestone road
        unlockArea: 2,
        requiredLevel: 14, // Mid-village milestone
        costs: [350, 750, 1400],
        sprites: [
          'village/meadow/windmill_stage1.webp',
          'village/meadow/windmill_stage2.webp',
          'village/meadow/windmill_stage3.webp',
        ],
        perks: [
          '1 free hint every day',
          '2 free hints every day',
          '3 free hints every day',
        ],
        reward: BuildingReward(
          type: RewardType.hint, 
          amounts: [1, 2, 3], 
          intervals: [Duration(hours: 24), Duration(hours: 24), Duration(hours: 24)], 
          maxStack: 1,
        ),
        signboardPos: Offset(180, 190), // Inside Windmill yard, right side (since door is on left)
      ),
      BuildingDef(
        id: 'library',
        name: 'Library',
        emoji: '📚',
        plot: Offset(220, 850), // Moved DOWN and LEFT to align new circular base with dirt patch
        spriteSize: Size(200, 200), // Scaled down
        flipHorizontal: true, // User requested rotation
        unlockArea: 3,
        requiredLevel: 22, // Advanced scholar milestone
        costs: [500, 1100, 2000],
        sprites: [
          'village/meadow/library_stage1.webp',
          'village/meadow/library_stage2.webp',
          'village/meadow/library_stage3.webp',
        ],
        perks: [
          'Professor Hoot moves in • +2 coins per equation',
          '+4 coins per equation',
          '+6 coins per equation',
        ],
        villagerId: 'owl',
        bonusWordCoinsPerStage: 2,
        signboardPos: Offset(170, 160), // Inside Library yard, right side
      ),
      BuildingDef(
        id: 'tower',
        name: 'Tower',
        emoji: '🗼',
        plot: Offset(385, 690), // Moved BACKWARD (up) to center perfectly on dirt patch
        spriteSize: Size(260, 260), // Increased size (images have transparent padding)
        flipHorizontal: false, // Stage 1 naturally faces bottom-left
        flipStages: [false, false, false], // All new tower stages naturally face bottom-left
        unlockArea: 4,
        requiredLevel: 30, // Apex village milestone
        costs: [800, 1600, 3000],
        sprites: [
          'village/meadow/tower_stage1.webp',
          'village/meadow/tower_stage2.webp',
          'village/meadow/tower_stage3.webp',
        ], 
        perks: [
          '1 Mega hint every day',
          '1 Mega hint every 12h',
          '2 Mega hints every day',
        ],
        reward: BuildingReward(
          type: RewardType.megaHint, 
          amounts: [1, 1, 2], // 1 hint, 1 hint (faster), 2 hints
          intervals: [Duration(hours: 24), Duration(hours: 12), Duration(hours: 24)], // Stage 2 is faster
          maxStack: 1,
        ),
        signboardPos: Offset(200, 220), // Inside Tower yard, right side (avoids Library completely)
      ),
    ],
    villagers: [
      VillagerDef(id: 'fox', name: 'Fern the Fox', kind: VillagerKind.fox, lines: ['Fresh bread!', 'Smell that?', 'Yum!']),
      VillagerDef(id: 'bunny', name: 'Bramble the Bunny', kind: VillagerKind.bunny, lines: ['Carrots!', 'Hop hop!', 'Lovely day!']),
      VillagerDef(id: 'owl', name: 'Professor Hoot', kind: VillagerKind.owl, lines: ['Hoo knew?', 'Read more!', 'Splendid!']),
    ],
    waypoints: [
      Offset(240, 560), // 0: Cottage front yard
      Offset(280, 560), // 1: Cottage door
      Offset(320, 550), // 2: Top-left junction
      Offset(300, 585), // 3: S-curve upper
      Offset(275, 625), // 4: S-curve mid-upper
      Offset(280, 665), // 5: S-curve mid
      Offset(310, 700), // 6: S-curve lower-left
      Offset(355, 725), // 7: Front of Tower door
      Offset(395, 745), // 8: Road below Tower
      Offset(430, 775), // 9: Road curving down
      Offset(435, 805), // 10: Heading to bottom road
      Offset(390, 835), // 11: Bottom road junction
      Offset(310, 835), // 12: In front of Library
      Offset(470, 835), // 13: In front of Windmill
      Offset(365, 690), // 14: Tower doorstep
      // Bakery road:
      Offset(440, 550), // 15: Road left of Bakery
      Offset(490, 565), // 16: In front of Bakery counter
      Offset(545, 570), // 17: Bakery plaza east
    ],
    edges: [
      [0, 1], [1, 2],
      [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 10], [10, 11],
      [11, 12],
      [11, 13],
      [7, 14],
      [2, 15], [15, 16], [16, 17],
    ],
  );

  static VillageDef? forBiome(String biomeName) {
    if (biomeName == meadow.biomeName) return meadow;
    return null;
  }

  static VillagerDef? villager(VillageDef v, String id) {
    for (final d in v.villagers) {
      if (d.id == id) return d;
    }
    return null;
  }
}
