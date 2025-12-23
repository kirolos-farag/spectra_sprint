import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import '../audio/audio_manager.dart';
import 'cannonball_projectile.dart';

class PirateShipBoss extends PositionComponent
    with HasGameRef<SpectraSprintGame> {
  int currentLane = 1;
  double _attackTimer = 2.5;
  final _random = Random();
  double _waveTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(160, 140);
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

    position = Vector2(gameRef.size.x / 2 + laneOffset, vanishingPointY - 30);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    _waveTime += dt;
    // Rocking motion like a ship on water
    position.y += sin(_waveTime * 2) * 0.3;
    angle = sin(_waveTime * 1.5) * 0.05;

    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _fireCannons();
      _attackTimer = 2.0 + _random.nextDouble() * 2.0;

      // Move to a new lane
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

    position.x += (targetX - position.x) * dt * 3;
  }

  void _fireCannons() {
    final numShots = _random.nextBool() ? 1 : 2;
    final lanes = [0, 1, 2];
    lanes.shuffle(_random);

    for (int i = 0; i < numShots; i++) {
      gameRef.world.add(CannonballProjectile(lanes[i]));
    }
    AudioManager().playCannonSound();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final shipPaint = Paint()..color = const Color(0xFF5D4037); // Brown hull
    final sailPaint = Paint()..color = Colors.white;
    final detailPaint = Paint()..color = Colors.black87;

    // 1. Hull
    final hullPath = Path()
      ..moveTo(20, size.y * 0.7)
      ..lineTo(size.x - 20, size.y * 0.7)
      ..lineTo(size.x - 40, size.y)
      ..lineTo(40, size.y)
      ..close();
    canvas.drawPath(hullPath, shipPaint);

    // Hull outline
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 2. Masts
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 5, 20, 10, size.y * 0.6),
      detailPaint,
    );

    // 3. Sails (Large triangle)
    final sailPath = Path()
      ..moveTo(size.x / 2, 25)
      ..lineTo(size.x * 0.2, 80)
      ..lineTo(size.x * 0.8, 80)
      ..close();
    canvas.drawPath(sailPath, sailPaint);

    // Jolly Roger (Simplified star for consistency?) Or just a black dot
    canvas.drawCircle(Offset(size.x / 2, 60), 10, detailPaint);
    canvas.drawPoints(
      PointMode.points,
      [Offset(size.x / 2, 60)],
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // 4. Cannon holes
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(40 + i * 40, size.y * 0.85), 6, detailPaint);
    }
  }
}
