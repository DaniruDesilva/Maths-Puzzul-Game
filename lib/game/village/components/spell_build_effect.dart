import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ConfettiParticle extends CircleComponent {
  final double lifeTime;
  double age = 0;
  Vector2 velocity;
  final double gravity = 400.0;
  final Color baseColor;

  ConfettiParticle({
    required Vector2 position,
    required this.velocity,
    required this.lifeTime,
    required this.baseColor,
  }) : super(radius: 4, position: position, anchor: Anchor.center) {
    paint = Paint()..color = baseColor;
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (age > lifeTime) {
      removeFromParent();
      return;
    }

    velocity.y += gravity * dt;
    position += velocity * dt;
    
    double progress = age / lifeTime;
    if (progress > 0.7) {
      paint.color = baseColor.withValues(alpha: 1.0 - ((progress - 0.7) / 0.3));
    }
  }
}

class SpellBuildEffect extends PositionComponent {
  final Random _random = Random();
  final List<Color> colors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange
  ];

  SpellBuildEffect({required Vector2 position}) {
    this.position = position;
    priority = 2000;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Spawn confetti
    for (int i = 0; i < 50; i++) {
      double angle = _random.nextDouble() * pi * 2;
      double speed = 100 + _random.nextDouble() * 250;
      add(ConfettiParticle(
        position: Vector2.zero(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 200),
        lifeTime: 1.5 + _random.nextDouble(),
        baseColor: colors[_random.nextInt(colors.length)],
      ));
    }
    
    // Spawn letter tiles
    String word = "BUILD!";
    for (int i = 0; i < word.length; i++) {
      double angle = -pi/2 + (_random.nextDouble() - 0.5) * 1.5; // mostly upwards
      double speed = 200 + _random.nextDouble() * 150;
      add(FlyingLetter(
        letter: word[i],
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
      ));
    }
  }
  
  double _life = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life > 3.0) removeFromParent();
  }
}

class FlyingLetter extends TextComponent {
  Vector2 velocity;
  final double gravity = 500.0;
  double life = 0;
  
  FlyingLetter({required String letter, required this.velocity}) 
    : super(
        text: letter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
          ),
        ),
        anchor: Anchor.center,
      );
      
  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    velocity.y += gravity * dt;
    position += velocity * dt;
    angle += dt * 3.0; // spin!
  }
}
