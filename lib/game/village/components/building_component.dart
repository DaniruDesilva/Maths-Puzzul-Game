import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../../data/village_data.dart';
import '../../../../providers/user_provider.dart';
import 'reward_bubble_component.dart';
import 'chimney_smoke_component.dart';
import 'spell_build_effect.dart';
import 'windmill_blades_component.dart';
import 'signboard_component.dart';

class BuildingComponent extends PositionComponent with TapCallbacks {
  final BuildingDef def;
  final UserProvider userProvider;
  final VoidCallback? onTapped;
  
  SpriteComponent? _spriteComponent;
  late SignboardComponent _signboard;
  ChimneySmokeComponent? _smoke;
  WindmillBladesComponent? _blades;

  BuildingComponent({
    required this.def,
    required this.userProvider,
    this.onTapped,
  }) {
    position = Vector2(def.plot.dx, def.plot.dy);
    // Anchor at bottomCenter so def.plot represents the exact bottom-center footprint on the dirt patch.
    anchor = Anchor.bottomCenter;
    
    // Pre-initialize size so hitboxes and text align immediately
    size = Vector2(def.spriteSize.width, def.spriteSize.height);
    
    // Y-sorting: objects lower on screen are drawn in front
    // Adjust priority for buildings with large grass patches at the bottom
    // so villagers walking in front of the grass don't get drawn behind the building.
    int priorityOffset = 0;
    if (def.id == 'tower') priorityOffset = -60;
    if (def.id == 'library') priorityOffset = -40;
    if (def.id == 'windmill') priorityOffset = -30;
    
    priority = position.y.toInt() + priorityOffset; 
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    int currentStage = userProvider.villageBuildings[def.id] ?? 0;
    _lastStage = currentStage;

    _signboard = SignboardComponent();
    _signboard.priority = 100; // Force it to draw IN FRONT of the building sprite
    add(_signboard);

    await _loadSpriteForStage(currentStage, isInitial: true);
    _updateCostText(currentStage);

    if (def.reward != null) {
      add(RewardBubbleComponent(
        def: def, 
        userProvider: userProvider,
      ));
    }
  }
  
  int _lastStage = -1;
  int _lastUserLevel = -1;

  @override
  void update(double dt) {
    super.update(dt);
    int currentStage = userProvider.villageBuildings[def.id] ?? 0;
    int currentUserLevel = userProvider.currentLevel;
    if (currentStage != _lastStage || currentUserLevel != _lastUserLevel) {
      if (_lastStage != -1 && currentStage > _lastStage) {
        // Upgraded! Spawn SpellBuildEffect
        // We add it to the parent (World) so it's not clipped and renders on top easily
        parent?.add(SpellBuildEffect(position: absolutePosition - Vector2(0, size.y / 2)));
      }
      
      _lastStage = currentStage;
      _lastUserLevel = currentUserLevel;
      _loadSpriteForStage(currentStage, isInitial: false);
      _updateCostText(currentStage);
      _updateSmoke(currentStage);
    }
  }

  void _updateSmoke(int currentStage) {
    if (def.chimney == null) return;
    
    // Smoke usually appears when building is fully built (e.g. stage >= 1 or 2)
    // We will show smoke if stage > 0
    if (currentStage > 0) {
      if (_smoke == null) {
        // Calculate chimney local position
        bool shouldFlip = def.flipHorizontal;
        if (def.flipStages != null && def.flipStages!.length == def.sprites.length) {
          int idx = currentStage == 0 ? 0 : (currentStage - 1).clamp(0, def.sprites.length - 1);
          shouldFlip = def.flipStages![idx];
        }
        
        double cx = def.chimney!.dx;
        if (shouldFlip) cx = 1.0 - cx; // mirror
        
        Vector2 smokePos = Vector2(size.x * cx, size.y * def.chimney!.dy);
        
        _smoke = ChimneySmokeComponent(position: smokePos);
        add(_smoke!);
      }
    } else {
      if (_smoke != null) {
        remove(_smoke!);
        _smoke = null;
      }
    }
  }

  Future<void> _loadSpriteForStage(int currentStage, {required bool isInitial}) async {
    String spriteName = '';
    bool isGhost = false;
    
    if (currentStage == 0) {
      if (def.sprites.isNotEmpty) {
         spriteName = def.sprites[0]; // Show stage 1 as a ghost
         isGhost = true;
      }
    } else {
      int idx = (currentStage - 1).clamp(0, def.sprites.length - 1);
      spriteName = def.sprites[idx];
    }
    
    if (spriteName.isNotEmpty) {
      try {
        final sprite = await Sprite.load(spriteName);
        if (_spriteComponent == null) {
          _spriteComponent = SpriteComponent(
            sprite: sprite,
            anchor: Anchor.topCenter,
          );
          // Insert the sprite so it renders correctly within the component
          add(_spriteComponent!);
        } else {
          _spriteComponent!.sprite = sprite;
        }
        
        final isLocked = currentStage == 0 && userProvider.currentLevel < def.requiredLevel;
        _spriteComponent!.setOpacity(isGhost ? (isLocked ? 0.22 : 0.35) : 1.0);
        
        // Scale the sprite to the defined plot size
        _spriteComponent!.size = size;
        _spriteComponent!.position = Vector2(size.x / 2, 0); // Center horizontally
        
        // Apply horizontal flip if needed
        bool shouldFlip = def.flipHorizontal;
        if (def.flipStages != null && def.flipStages!.length == def.sprites.length) {
          int idx = currentStage == 0 ? 0 : (currentStage - 1).clamp(0, def.sprites.length - 1);
          shouldFlip = def.flipStages![idx];
        }

        if (shouldFlip) {
          _spriteComponent!.scale = Vector2(-1, 1);
        } else {
          _spriteComponent!.scale = Vector2(1, 1);
        }
        
        // Handle Windmill Blades
        if (def.id == 'windmill' && currentStage > 0) {
          if (_blades == null) {
            final bladeSprite = await Sprite.load('village/meadow/windmill_blades.webp');
            _blades = WindmillBladesComponent(
              sprite: bladeSprite,
              position: Vector2(size.x / 2, size.y * 0.4), 
              size: Vector2(size.x * 0.65, size.x * 0.65), 
            );
            add(_blades!); // Add to BuildingComponent
          }
          
          double cx = size.x / 2;
          if (currentStage == 1) {
            // Unflipped (dome on left): -10. Flipped (dome on right): +10.
            double hubOffset = shouldFlip ? 10 : -10;
            _blades!.position = Vector2(cx + hubOffset, size.y * 0.35);
          } else if (currentStage == 2) {
            _blades!.position = Vector2(cx, size.y * 0.45);
          } else if (currentStage == 3) {
            _blades!.position = Vector2(cx, size.y * 0.25);
          }
          
          if (shouldFlip) {
            _blades!.scale = Vector2(-1, 1);
          } else {
            _blades!.scale = Vector2(1, 1);
          }
          
          _blades!.setOpacity(isGhost ? 0.3 : 1.0);
        } else if (def.id == 'windmill' && currentStage == 0) {
           if (_blades != null) {
             _blades!.removeFromParent();
             _blades = null;
           }
        }
        
        if (isInitial) {
           _updateCostText(currentStage);
        }
      } catch (e) {
        debugPrint('Error loading sprite $spriteName: $e');
      }
    }
  }

  void _updateCostText(int currentStage) {
    if (currentStage >= def.maxStage) {
      if (_signboard.parent != null) {
        remove(_signboard);
      }
      return;
    }
    
    // Make sure it's added if not max stage
    if (_signboard.parent == null) {
      add(_signboard);
    }

    final isLocked = currentStage == 0 && userProvider.currentLevel < def.requiredLevel;
    if (isLocked) {
      _signboard.setSign(icon: '🔒', text: 'Lv.${def.requiredLevel}');
    } else {
      int cost = def.costs[currentStage];
      _signboard.setSign(icon: '💰', text: '$cost');
    }
    
    if (currentStage == 0) {
      // Unbuilt: Place the signboard perfectly centered on the isometric dirt patch.
      // Since the component is anchored at bottomCenter to the bottom tip of the dirt patch,
      // going up by ~40 pixels puts it right in the visual center of the dirt ellipse.
      _signboard.position = Vector2(size.x / 2, size.y - 40);
    } else {
      // Built: Use the precise safe yard positions
      if (def.signboardPos != null) {
        _signboard.position = Vector2(def.signboardPos!.dx, def.signboardPos!.dy);
      } else {
        _signboard.position = Vector2(size.x / 2, size.y - 20); // Fallback
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (onTapped != null) {
      onTapped!();
      return;
    }
    
    // Fallback logic if no callback is provided
    int currentStage = userProvider.villageBuildings[def.id] ?? 0;
    if (currentStage >= def.maxStage) {
      // Fully upgraded
      return;
    }
    
    int cost = def.costs[currentStage];
    
    // Check if user has enough coins
    if (userProvider.coins >= cost) {
      userProvider.spendCoins(cost);
      userProvider.upgradeBuilding(def.id);
    }
  }
}
