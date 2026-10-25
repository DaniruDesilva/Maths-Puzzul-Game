import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../data/village_data.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/sound_service.dart';

class RewardBubbleComponent extends PositionComponent with TapCallbacks {
  final BuildingDef def;
  final UserProvider userProvider;
  
  late TextComponent _content;
  
  double _time = 0;
  double _checkTimer = 0;
  final double _bobbingSpeed = 3.0;
  final double _bobbingAmount = 6.0;
  
  int _pendingStacks = 0;
  int _lastStage = -1;

  RewardBubbleComponent({
    required this.def,
    required this.userProvider,
  }) {
    size = Vector2(90, 46);
    anchor = Anchor.center;
    position = Vector2(def.spriteSize.width / 2, -40);
    priority = 1000;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (def.reward == null) return;

    _content = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2C3E35),
          letterSpacing: 1.0,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 + 2),
    );
    add(_content);
    
    _checkRewards();
  }
  
  void _checkRewards() {
    if (def.reward == null) {
      _pendingStacks = 0;
      return;
    }
    
    int currentStage = userProvider.villageBuildings[def.id] ?? 0;
    
    int newStacks = userProvider.getPendingRewards(
      def.id, 
      def.reward!.intervals, 
      def.reward!.maxStack
    );
    
    if (newStacks != _pendingStacks || currentStage != _lastStage) {
      _pendingStacks = newStacks;
      _lastStage = currentStage;
      
      if (_pendingStacks > 0 && currentStage > 0) {
        int amount = _pendingStacks * def.reward!.amounts[currentStage - 1];
        
        String icon = '💰';
        if (def.reward!.type == RewardType.hint) icon = '💡';
        if (def.reward!.type == RewardType.megaHint) icon = '🌟';
        
        _content.text = '$icon $amount';
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (def.reward == null) return;
    
    _time += dt;
    _checkTimer += dt;
    
    // Check for new rewards every second
    if (_checkTimer >= 1.0) {
      _checkTimer = 0;
      _checkRewards();
    }
    
    if (_pendingStacks > 0) {
      // Smooth bobbing
      position.y = -40 + math.sin(_time * _bobbingSpeed) * _bobbingAmount;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_pendingStacks <= 0 || def.reward == null) return;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.y / 2),
    );
    
    // Thick White Pill Background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(rect, bgPaint);
    
    // Premium Golden Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    super.render(canvas);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_pendingStacks <= 0 || def.reward == null) return;
    
    int currentStage = userProvider.villageBuildings[def.id] ?? 0;
    if (currentStage == 0) return;
    
    int amount = _pendingStacks * def.reward!.amounts[currentStage - 1];
    
    String typeStr = 'coins';
    if (def.reward!.type == RewardType.hint) typeStr = 'hint';
    if (def.reward!.type == RewardType.megaHint) typeStr = 'megaHint';
    
    userProvider.collectBuildingReward(def.id, amount, typeStr);
    
    // Play rewarding collection feedback
    SoundService.playBonus();
    HapticFeedback.mediumImpact();

    // Hide bubble instantly
    _pendingStacks = 0;
    
    // Stop event so the Build Sheet doesn't open
    event.continuePropagation = false;
  }
}
