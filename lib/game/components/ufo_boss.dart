import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import '../audio/audio_manager.dart';
import 'alien_projectile.dart';

class UfoBoss extends PositionComponent with HasGameRef<SpectraSprintGame> {
  int currentLane = 1;
  double _attackTimer = 1.5;
  final _random = Random();
  double _hoverTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(160, 80);
    anchor = Anchor.center;
    _updatePosition();
  }

  void _updatePosition() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    position = Vector2(gameRef.size.x / 2, vanishingPointY - 60);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    _hoverTime += dt;
    // UFO wavy movement
    position.y += sin(_hoverTime * 2) * 0.7;
    position.x =
        gameRef.size.x / 2 + sin(_hoverTime * 1.5) * (gameRef.size.x * 0.2);

    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attack();
      _attackTimer = 2.0 + _random.nextDouble() * 1.0;
    }
  }

  void _attack() {
    // Determine which lanes to drop aliens in (1 or 2 lanes, never all 3)
    final numAliens = _random.nextBool() ? 1 : 2;
    final lanes = [0, 1, 2];
    lanes.shuffle(_random);

    for (int i = 0; i < numAliens; i++) {
      gameRef.world.add(AlienProjectile(lanes[i]));
    }
    AudioManager().playAliensSound();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()..color = Colors.grey.shade400;
    final glassPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade700],
          ).createShader(
            Rect.fromLTWH(size.x * 0.25, 0, size.x * 0.5, size.y * 0.6),
          );

    // 1. UFO Body (Saucer - Metallic look)
    final saucerPath = Path()
      ..moveTo(0, size.y * 0.5)
      ..quadraticBezierTo(size.x * 0.5, size.y * 0.2, size.x, size.y * 0.5)
      ..quadraticBezierTo(size.x * 0.5, size.y * 0.8, 0, size.y * 0.5)
      ..close();
    canvas.drawPath(saucerPath, bodyPaint);

    // Internal rim
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.1, size.y * 0.45, size.x * 0.8, size.y * 0.1),
      Paint()..color = Colors.grey.shade600,
    );

    // 2. Glass Dome
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.3, 5, size.x * 0.4, size.y * 0.5),
      glassPaint,
    );

    // 3. Bottom Tractor Beam Hole (Glowing)
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.6, size.x * 0.3, size.y * 0.15),
      Paint()
        ..color = Colors.greenAccent.withOpacity(
          0.5 + sin(_hoverTime * 8) * 0.3,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 4. Peripheral Lights (Flashing)
    final lightColors = [
      Colors.greenAccent,
      Colors.limeAccent,
      Colors.cyanAccent,
    ];
    for (int i = 0; i < 6; i++) {
      final x = (size.x * 0.15) + (i * size.x * 0.14);
      final colorIdx = (i + (_hoverTime * 5).toInt()) % lightColors.length;
      final glow = 0.5 + sin(_hoverTime * 10 + i) * 0.5;

      canvas.drawCircle(
        Offset(x, size.y * 0.5),
        5,
        Paint()
          ..color = lightColors[colorIdx].withOpacity(glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // 5. Outer Glow
    canvas.drawPath(
      saucerPath,
      Paint()
        ..color = Colors.blueAccent.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
}
