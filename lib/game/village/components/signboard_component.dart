import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SignboardComponent extends SpriteComponent {
  late TextComponent _iconComponent;
  late TextComponent _numberComponent;
  String _initialIcon = '💰';
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
      text: _initialIcon,
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
      text: _initialText,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
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

  void setSign({required String icon, required String text}) {
    if (isLoaded) {
      _iconComponent.text = icon;
      _numberComponent.text = text;
    } else {
      _initialIcon = icon;
      _initialText = text;
    }
  }

  String get text => isLoaded ? '${_iconComponent.text} ${_numberComponent.text}' : '$_initialIcon $_initialText';
  
  set text(String value) {
    if (value.startsWith('🔒')) {
      setSign(icon: '🔒', text: value.replaceAll('🔒 ', '').replaceAll('🔒', ''));
    } else {
      setSign(icon: '💰', text: value.replaceAll('💰 ', '').replaceAll('💰', ''));
    }
  }
}

