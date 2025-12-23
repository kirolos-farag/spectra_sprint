import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../spectra_sprint_game.dart';

class BiomeWarning extends PositionComponent
    with HasGameRef<SpectraSprintGame> {
  final String message;
  final Color color;
  double _timer = 0;
  final double duration = 3.0;
  late TextComponent _textComponent;
  late TextPaint _textPaint;
  final Random _random = Random();

  BiomeWarning({required this.message, required this.color});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // نضع الرسالة في منتصف الفيو بورت (Viewport)
    anchor = Anchor.center;
    final viewportSize = gameRef.camera.viewport.size;
    position = Vector2(viewportSize.x / 2, viewportSize.y / 2);

    _textPaint = TextPaint(
      style: TextStyle(
        color: color,
        fontSize: 14, // تصغير كبير لضمان عدم الخروج عن الشاشة أبداً
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 2,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 15, offset: Offset(3, 3)),
          Shadow(color: color.withOpacity(0.8), blurRadius: 25),
        ],
      ),
    );

    _textComponent = TextComponent(
      text: message,
      textRenderer: _textPaint,
      anchor: Anchor.center,
    );

    add(_textComponent);

    // سطر للتأكد من أن الكومبوننت تم تحميله (للمطور)
    debugPrint('BiomeWarning loaded: $message');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // تأثير اهتزاز (Glitch) محسن
    if (_random.nextDouble() > 0.85) {
      _textComponent.position = Vector2(
        (_random.nextDouble() - 0.5) * 15,
        (_random.nextDouble() - 0.5) * 15,
      );
      // تغيير عشوائي للشفافية لخلق تأثير وميض (Flicker)
      _textComponent.textRenderer = TextPaint(
        style: _textPaint.style.copyWith(
          color: color.withOpacity(_random.nextDouble() > 0.5 ? 1.0 : 0.5),
        ),
      );
    } else {
      _textComponent.position = Vector2.zero();
      // إعادة الشفافية العادية
      if (_timer <= duration - 1.0) {
        _textComponent.textRenderer = _textPaint;
      }
    }

    // تأثير التلاشي النهائي (Fade out)
    if (_timer > duration - 1.0) {
      final alpha = (duration - _timer).clamp(0.0, 1.0);
      _textComponent.textRenderer = TextPaint(
        style: _textPaint.style.copyWith(color: color.withOpacity(alpha)),
      );
    }

    if (_timer >= duration) {
      removeFromParent();
    }
  }
}
