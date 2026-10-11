import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SmokeParticle extends CircleComponent {
  final double lifeTime;
  double age = 0;
  final Vector2 velocity;

  SmokeParticle({
    required Vector2 position,
    required this.lifeTime,
    required this.velocity,
  }) : super(radius: 5, position: position, anchor: Anchor.center) {
    paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (age > lifeTime) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    radius += 3 * dt; // expand slowly
    
    // Fade out
    double progress = age / lifeTime;
    paint.color = Colors.white.withValues(alpha: 0.4 * (1 - progress));
  }
}

class ChimneySmokeComponent extends PositionComponent {
  final Random _random = Random();
  double _timer = 0;

  ChimneySmokeComponent({required Vector2 position}) {
    this.position = position;
    // Always render above the building
    priority = 1500;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    if (_timer > 0.4) {
      _timer = 0;
      add(SmokeParticle(
        position: Vector2.zero(),
        lifeTime: 2.5 + _random.nextDouble(),
        velocity: Vector2((_random.nextDouble() - 0.5) * 15, -25 - _random.nextDouble() * 10),
      ));
    }
  }
}
