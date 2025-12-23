import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'fire_projectile.dart';

class BossDevil extends PositionComponent with HasGameRef<SpectraSprintGame> {
  double targetLaneX = 0;
  int currentLane = 1;
  double _attackTimer = 2.0;
  final _random = Random();
  double _hoverTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(120, 120);
    anchor = Anchor.center;
    _updatePosition();
  }

  void _updatePosition() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    final trackHorizonWidth =
        gameRef.size.x * GameConstants.trackHorizonWidthFactor;

    final laneWidth = trackHorizonWidth / 3;
    final laneOffset = (currentLane - 1) * laneWidth;

    position = Vector2(gameRef.size.x / 2 + laneOffset, vanishingPointY - 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    _hoverTime += dt;
    // vertical floating motion
    position.y += sin(_hoverTime * 3) * 0.5;

    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _shootFire();
      _attackTimer = 1.5 + _random.nextDouble() * 1.5;

      // Move to a new lane after shooting
      currentLane = _random.nextInt(3);
    }

    _updateMovement(dt);
  }

  void _updateMovement(double dt) {
    final trackHorizonWidth =
        gameRef.size.x * GameConstants.trackHorizonWidthFactor;
    final laneWidth = trackHorizonWidth / 3;
    final laneOffset = (currentLane - 1) * laneWidth;
    final targetX = gameRef.size.x / 2 + laneOffset;

    // Smooth horizontal movement
    position.x += (targetX - position.x) * dt * 5;
  }

  void _shootFire() {
    // Determine which lanes to drop fireballs in (1 or 2 lanes, never all 3)
    final numFireballs = _random.nextBool() ? 1 : 2;
    final lanes = [0, 1, 2];
    lanes.shuffle(_random);

    for (int i = 0; i < numFireballs; i++) {
      gameRef.world.add(FireProjectile(lanes[i]));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()
      ..color = const Color(0xFF800000); // Deep blood red
    final facePaint = Paint()..color = const Color(0xFFB00000);
    final eyePaint = Paint()..color = Colors.yellowAccent;
    final hornPaint = Paint()..color = const Color(0xFF202020);
    final toothPaint = Paint()..color = Colors.white;

    // 1. Draw Horns (More detailed)
    final leftHorn = Path()
      ..moveTo(30, 40)
      ..relativeQuadraticBezierTo(-20, -30, -10, -50)
      ..relativeQuadraticBezierTo(10, 20, 20, 40)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);

    final rightHorn = Path()
      ..moveTo(size.x - 30, 40)
      ..relativeQuadraticBezierTo(20, -30, 10, -50)
      ..relativeQuadraticBezierTo(-10, 20, -20, 40)
      ..close();
    canvas.drawPath(rightHorn, hornPaint);

    // 2. Head Shape (Rect with rounded top)
    final headRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(20, 20, size.x - 40, size.y - 40),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
    );
    canvas.drawRRect(headRect, bodyPaint);

    // Face inner area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 30, size.x - 60, size.y - 60),
        const Radius.circular(10),
      ),
      facePaint,
    );

    // 3. Glowing Eyes (Anger shape)
    final leftEyePath = Path()
      ..moveTo(35, 45)
      ..lineTo(55, 55)
      ..lineTo(35, 60)
      ..close();
    canvas.drawPath(leftEyePath, eyePaint);

    final rightEyePath = Path()
      ..moveTo(size.x - 35, 45)
      ..lineTo(size.x - 55, 55)
      ..lineTo(size.x - 35, 60)
      ..close();
    canvas.drawPath(rightEyePath, eyePaint);

    // 4. Mouth & Teeth
    final mouthRect = Rect.fromLTWH(40, 70, size.x - 80, 25);
    canvas.drawRect(mouthRect, Paint()..color = Colors.black);

    // Upper Teeth
    for (int i = 0; i < 4; i++) {
      final tx = 45 + (i * ((size.x - 90) / 3));
      canvas.drawPath(
        Path()
          ..moveTo(tx, 70)
          ..lineTo(tx + 5, 80)
          ..lineTo(tx + 10, 70)
          ..close(),
        toothPaint,
      );
    }
    // Lower Teeth
    for (int i = 0; i < 4; i++) {
      final tx = 45 + (i * ((size.x - 90) / 3));
      canvas.drawPath(
        Path()
          ..moveTo(tx, 95)
          ..lineTo(tx + 5, 85)
          ..lineTo(tx + 10, 95)
          ..close(),
        toothPaint,
      );
    }

    // 5. Glowing aura (Red)
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = Colors.red.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }
}
