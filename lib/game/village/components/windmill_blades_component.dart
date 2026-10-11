import 'package:flame/components.dart';

class WindmillBladesComponent extends SpriteComponent {
  final double rotationSpeed;

  WindmillBladesComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    this.rotationSpeed = 1.0, // radians per second
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center) {
    // We want the blades to be rendered in front of the windmill base
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle += rotationSpeed * dt;
  }
}
