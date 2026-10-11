import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SignboardComponent extends SpriteComponent {
  late TextComponent _iconComponent;
  late TextComponent _numberComponent;
  String _initialText = '';

  SignboardComponent() {
    size = Vector2(80, 80); 
    anchor = Anchor.bottomCenter;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('village/meadow/signboard.webp');
    
    _iconComponent = TextComponent(
      text: '💰',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2 - 16, size.y * 0.35),
    );
    
    _numberComponent = TextComponent(
      text: _initialText.replaceAll('💰 ', ''),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))],
        ),
      ),
      anchor: Anchor.centerLeft,
      position: Vector2(size.x / 2 - 4, size.y * 0.35),
    );
    
    add(_iconComponent);
    add(_numberComponent);
  }

  String get text => isLoaded ? '💰 ${_numberComponent.text}' : _initialText;
  
  set text(String value) {
    if (isLoaded) {
      _numberComponent.text = value.replaceAll('💰 ', '');
    } else {
      _initialText = value;
    }
  }
}
