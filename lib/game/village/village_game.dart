import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/village_data.dart';
import '../../../providers/user_provider.dart';
import 'components/building_component.dart';
import 'components/animal_villager_component.dart';

class VillageGame extends FlameGame with PanDetector {
  final VillageDef village;
  final UserProvider userProvider;
  final void Function(BuildingDef)? onBuildingTapped;

  VillageGame({required this.village, required this.userProvider, this.onBuildingTapped});

  static bool get _isInTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  late SpriteComponent background;
  late List<BuildingComponent> buildings = [];

  @override
  Color backgroundColor() => const Color(0xFFD9E8FE); // Light sky blue to blend with island sky

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set up camera without fixed resolution to fill screen responsively
    camera = CameraComponent();
    world = World();
    camera.world = world;
    addAll([camera, world]);

    if (_isInTest) return;

    // Load background
    final bgSprite = await loadSprite(village.background);
    final bgSize = Vector2(village.worldSize.width, village.worldSize.height);
    background = SpriteComponent(
      sprite: bgSprite,
      size: bgSize,
      anchor: Anchor.topLeft,
    );
    world.add(background);

    // Load buildings
    for (var buildingDef in village.buildings) {
      final comp = BuildingComponent(
        def: buildingDef,
        userProvider: userProvider,
        onTapped: () => onBuildingTapped?.call(buildingDef),
      );
      buildings.add(comp);
      world.add(comp);
    }
    
    // Add villagers if their buildings are built
    _checkAndSpawnVillagers();
  }
  
  final Set<String> _spawnedVillagers = {};
  
  void _checkAndSpawnVillagers() {
    for (BuildingDef def in village.buildings) {
      if (def.villagerId != null && !_spawnedVillagers.contains(def.villagerId)) {
        int stage = userProvider.villageBuildings[def.id] ?? 0;
        if (stage > 0) {
          VillagerDef? vDef = VillageData.villager(village, def.villagerId!);
          if (vDef != null) {
            int startNode = 1; // default to Cottage door
            if (def.villagerId == 'bunny') {
              startNode = 1; // Cottage door
            } else if (def.villagerId == 'fox') {
              startNode = 16; // Bakery counter
            } else if (def.villagerId == 'owl') {
              startNode = 12; // Library entrance
            } else {
              startNode = math.Random().nextInt(village.waypoints.length);
            }

            world.add(AnimalVillagerComponent(
              def: vDef,
              village: village,
              userProvider: userProvider,
              startNode: startNode,
            ));
            _spawnedVillagers.add(def.villagerId!);
          }
        }
      }
    }
  }

  double _villagerCheckTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isInTest) return;
    _villagerCheckTimer += dt;
    if (_villagerCheckTimer >= 1.5) {
      _villagerCheckTimer = 0.0;
      _checkAndSpawnVillagers();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Zoom so the island covers the entire screen completely (no margins)
    double scaleX = size.x / village.worldSize.width;
    double scaleY = size.y / village.worldSize.height;
    camera.viewfinder.zoom = math.max(scaleX, scaleY);
    
    // Start with the camera centered near the bottom (where early buildings are)
    camera.viewfinder.position = Vector2(village.worldSize.width / 2, village.worldSize.height / 2);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Pan the camera viewfinder in the opposite direction of the drag
    final delta = info.delta.global;
    // Scale delta based on zoom
    camera.viewfinder.position -= delta / camera.viewfinder.zoom;
    
    // Constrain camera position to the background bounds
    double x = camera.viewfinder.position.x;
    double y = camera.viewfinder.position.y;
    
    double visibleWidth = size.x / camera.viewfinder.zoom;
    double visibleHeight = size.y / camera.viewfinder.zoom;
    
    double minX = visibleWidth / 2;
    double maxX = village.worldSize.width - visibleWidth / 2;
    double minY = visibleHeight / 2;
    double maxY = village.worldSize.height - visibleHeight / 2;
    
    // If screen is wider/taller than the world, center it
    x = maxX < minX ? village.worldSize.width / 2 : x.clamp(minX, maxX);
    y = maxY < minY ? village.worldSize.height / 2 : y.clamp(minY, maxY);
    
    camera.viewfinder.position = Vector2(x, y);
  }
}
