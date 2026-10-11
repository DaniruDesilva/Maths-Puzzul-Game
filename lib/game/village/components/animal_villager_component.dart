import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../../data/village_data.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/sound_service.dart';

class SpeechBubbleComponent extends PositionComponent {
  final String text;
  
  SpeechBubbleComponent({required this.text}) {
    // Dynamic width based on text length (rough estimation)
    double w = (text.length * 8.0) + 20.0;
    if (w < 60) w = 60;
    size = Vector2(w, 40);
    anchor = Anchor.bottomCenter;
  }
  
  @override
  void render(Canvas canvas) {
    // Draw white pill
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    
    // Draw tiny triangle pointing down
    final path = Path()
      ..moveTo(size.x / 2 - 5, size.y)
      ..lineTo(size.x / 2 + 5, size.y)
      ..lineTo(size.x / 2, size.y + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    
    // Outline
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);
    
    // Draw text
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFF2C3E35), // Dark green text
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
    textPaint.render(canvas, text, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }
}

class AnimalVillagerComponent extends SpriteComponent with TapCallbacks {
  final VillagerDef def;
  final VillageDef village;
  final UserProvider userProvider;
  
  int _currentNode;
  int? _previousNode;
  int _nextNode;
  double _progress = 0;
  final double _speed = 32.0; // Smooth strolling speed
  final Random _random = Random();
  
  bool _isIdling = false;
  double _idleTimer = 0;
  double _walkCycle = 0;
  double _idleTime = 0;
  double _tapReactionTimer = 0;
  bool _facingRight = false;

  SpeechBubbleComponent? _speechBubble;
  double _speechTimer = 0;

  // Key landmarks/destinations where villagers pause and observe
  static const Set<int> _poiNodes = {0, 1, 7, 12, 13, 14, 16, 17};

  AnimalVillagerComponent({
    required this.def,
    required this.village,
    required this.userProvider,
    required int startNode,
  }) : _currentNode = startNode, _nextNode = startNode {
    anchor = Anchor.bottomCenter;
    final startPos = village.waypoints[startNode];
    position = Vector2(startPos.dx, startPos.dy);
    size = Vector2(60, 60); // Base size for the villager
    priority = startPos.dy.toInt() + 10; // Dynamic Y-based priority
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load sprite
    try {
      sprite = await Sprite.load('village/villagers/${def.id}.webp');
    } catch (e) {
      debugPrint('Villager sprite not found for ${def.id}');
    }
    
    _pickNextNode();
  }

  void _pickNextNode() {
    List<int> neighbors = village.neighbours(_currentNode);
    if (neighbors.isEmpty) return;
    
    // Pick an adjacent neighbor, preferring not to turn 180 degrees backwards if alternatives exist
    int next = neighbors[_random.nextInt(neighbors.length)];
    if (neighbors.length > 1 && _previousNode != null && neighbors.contains(_previousNode)) {
      if (_random.nextDouble() > 0.15) {
        final candidates = neighbors.where((n) => n != _previousNode).toList();
        if (candidates.isNotEmpty) {
          next = candidates[_random.nextInt(candidates.length)];
        }
      }
    }
    
    _previousNode = _currentNode;
    _nextNode = next;
    _progress = 0;
    
    _updateFacingDirection();
  }

  void _updateFacingDirection() {
    double dxDiff = village.waypoints[_nextNode].dx - village.waypoints[_currentNode].dx;
    if (dxDiff > 1.0) {
      _facingRight = true;
    } else if (dxDiff < -1.0) {
      _facingRight = false;
    }
    scale = Vector2(_facingRight ? -1.0 : 1.0, 1.0);
  }

  @override
  void onTapUp(TapUpEvent event) {
    SoundService.playClick();
    _tapReactionTimer = 0.5; // Joyful hop
    
    // Immediate friendly response
    if (_speechBubble == null && def.lines.isNotEmpty) {
      String text = def.lines[_random.nextInt(def.lines.length)];
      _speechBubble = SpeechBubbleComponent(text: text);
      _speechBubble!.position = Vector2(size.x / 2, -10);
      _speechBubble!.scale = Vector2(_facingRight ? -1.0 : 1.0, 1.0);
      add(_speechBubble!);
      _speechTimer = 3.5;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Tap reaction timer
    if (_tapReactionTimer > 0) {
      _tapReactionTimer -= dt;
      if (_tapReactionTimer < 0) _tapReactionTimer = 0;
    }

    // --- IDLE STATE ---
    if (_isIdling) {
      _idleTime += dt;
      _idleTimer -= dt;
      
      // Gentle breathing animation
      double breath = sin(_idleTime * 3.0);
      double squashY = 1.0 + breath * 0.025;
      double squashX = 1.0 - breath * 0.015;
      double hop = 0.0;
      double sway = 0.0;

      // Add joyful bounce if tapped
      if (_tapReactionTimer > 0) {
        double tapProgress = (0.5 - _tapReactionTimer) / 0.5;
        hop = sin(tapProgress * pi) * 12.0;
        squashY += (hop / 12.0) * 0.12;
        squashX -= (hop / 12.0) * 0.08;
      }

      angle = sway;
      scale = Vector2((_facingRight ? -1.0 : 1.0) * squashX, squashY);
      
      Offset currentPos = village.waypoints[_currentNode];
      position = Vector2(currentPos.dx, currentPos.dy - hop);
      priority = currentPos.dy.toInt() + 10;

      if (_idleTimer <= 0) {
        _isIdling = false;
        _pickNextNode();
      }
      _updateSpeechBubble(dt);
      return;
    }

    // --- WALKING STATE ---
    Offset start = village.waypoints[_currentNode];
    Offset end = village.waypoints[_nextNode];
    double distance = (end - start).distance;
    
    if (distance > 0) {
      _progress += (_speed * dt) / distance;
    } else {
      _progress = 1.0;
    }
    
    if (_progress >= 1.0) {
      _progress = 1.0;
      position = Vector2(end.dx, end.dy);
      _currentNode = _nextNode;
      
      // Determine if villager should pause and take in the view
      bool isPoi = _poiNodes.contains(_currentNode);
      bool isDeadEnd = village.neighbours(_currentNode).length <= 1;
      bool shouldPause = isDeadEnd || (isPoi && _random.nextDouble() < 0.85) || (_random.nextDouble() < 0.15);
      
      if (shouldPause) {
        _isIdling = true;
        _idleTimer = 1.6 + _random.nextDouble() * 1.8; // 1.6s to 3.4s relaxing pause
      } else {
        _pickNextNode();
      }
    } else {
      // Natural smoothstep curve for fluid momentum
      double smoothT = _progress * _progress * (3.0 - 2.0 * _progress);
      double x = start.dx + (end.dx - start.dx) * smoothT;
      double y = start.dy + (end.dy - start.dy) * smoothT;
      
      _walkCycle += dt;

      double hop = 0.0;
      double squashY = 1.0;
      double squashX = 1.0;
      double sway = 0.0;

      // Character-specific locomotion physics
      switch (def.kind) {
        case VillagerKind.bunny:
          // Energetic bunny hop with squash on landing
          double hopPhase = sin(_walkCycle * 15.0);
          if (hopPhase > 0) {
            hop = hopPhase * 5.5;
            squashY = 1.0 + (hop / 5.5) * 0.07;
            squashX = 1.0 - (hop / 5.5) * 0.05;
          } else {
            hop = 0;
            double land = (-hopPhase) * 0.06;
            squashY = 1.0 - land;
            squashX = 1.0 + land;
          }
          break;

        case VillagerKind.fox:
          // Confident fox trot with body stride sway
          hop = (sin(_walkCycle * 12.0).abs()) * 3.2;
          sway = sin(_walkCycle * 6.0) * 0.045;
          squashY = 1.0 + sin(_walkCycle * 12.0) * 0.03;
          squashX = 1.0 - sin(_walkCycle * 12.0) * 0.02;
          break;

        case VillagerKind.owl:
          // Endearing waddle from side to side
          hop = (sin(_walkCycle * 9.0).abs()) * 2.2;
          sway = sin(_walkCycle * 9.0) * 0.06;
          squashY = 1.0 + sin(_walkCycle * 18.0) * 0.025;
          squashX = 1.0 - sin(_walkCycle * 18.0) * 0.02;
          break;
      }

      // Add joyful bounce if tapped
      if (_tapReactionTimer > 0) {
        double tapProgress = (0.5 - _tapReactionTimer) / 0.5;
        double tapHop = sin(tapProgress * pi) * 10.0;
        hop += tapHop;
      }

      angle = sway;
      scale = Vector2((_facingRight ? -1.0 : 1.0) * squashX, squashY);
      position = Vector2(x, y - hop);
      priority = y.toInt() + 10;
    }
    
    _updateSpeechBubble(dt);
  }

  void _updateSpeechBubble(double dt) {
    if (_speechBubble != null) {
      _speechBubble!.scale = Vector2(_facingRight ? -1.0 : 1.0, 1.0);
      _speechBubble!.angle = -angle; // Keep bubble text level
      
      _speechTimer -= dt;
      if (_speechTimer <= 0) {
        remove(_speechBubble!);
        _speechBubble = null;
      }
    } else {
      // Occasional spontaneous speech
      if (_random.nextDouble() < 0.003) { 
        String text = def.lines[_random.nextInt(def.lines.length)];
        _speechBubble = SpeechBubbleComponent(text: text);
        _speechBubble!.position = Vector2(size.x / 2, -10);
        _speechBubble!.scale = Vector2(_facingRight ? -1.0 : 1.0, 1.0);
        add(_speechBubble!);
        _speechTimer = 3.5;
      }
    }
  }
}
