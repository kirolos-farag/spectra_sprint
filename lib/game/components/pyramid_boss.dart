import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import '../audio/audio_manager.dart';
import 'mummy_projectile.dart';

class PyramidBoss extends PositionComponent with HasGameRef<SpectraSprintGame> {
  double _attackTimer = 1.0;
  final _random = Random();
  double _hoverTime = 0;
  double _riseProgress = 0.0;
  bool _isRising = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(200, 150);
    anchor = Anchor.bottomCenter;
    _updatePosition();
  }

  void _updatePosition() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    // Start below the horizon to rise up
    position = Vector2(
      gameRef.size.x / 2,
      vanishingPointY + (1.0 - _riseProgress) * 100,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    if (_isRising) {
      _riseProgress += dt * 0.5;
      if (_riseProgress >= 1.0) {
        _riseProgress = 1.0;
        _isRising = false;
      }
    }

    _hoverTime += dt;
    _updatePosition();

    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _spawnMummies();
      _attackTimer = 2.0 + _random.nextDouble() * 1.5;
    }
  }

  void _spawnMummies() {
    // Determine safe lanes for mummies
    // Logic: In Stage 7, vanishing lane is active.
    // We should spawn mummies in lanes that are NOT currently the warning lane or vanishing lane if possible,
    // or at least ensure a "clean" lane exists for the player.

    final warningLane = gameRef.warningLaneIndex;
    final vanishingLane = gameRef.vanishingLaneIndex;

    List<int> availableLanes = [0, 1, 2];
    // Remove lanes that are currently dangerous due to glitches
    if (warningLane != -1) availableLanes.remove(warningLane);
    if (vanishingLane != -1) availableLanes.remove(vanishingLane);

    if (availableLanes.isEmpty) {
      // Fallback: spawn in any lane if glitch system is confusing,
      // but usually the glitch system only affects 1 lane.
      availableLanes = [0, 1, 2];
      if (vanishingLane != -1) availableLanes.remove(vanishingLane);
    }

    if (availableLanes.isNotEmpty) {
      final spawnLane = availableLanes[_random.nextInt(availableLanes.length)];
      gameRef.world.add(MummyProjectile(spawnLane));
      AudioManager().playMummyZombieSound();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pyramidPaint = Paint()..color = const Color(0xFFDAA520); // Golden Rod
    final shadowPaint = Paint()..color = const Color(0xFFB8860B);
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = Colors.blue.shade900;

    // 1. Pyramid Shape (Triangle)
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(0, size.y)
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(path, pyramidPaint);

    // Right side shadow
    final shadowPath = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.7, size.y)
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. The All-Seeing Eye (Illuminati)
    final eyeCenter = Offset(size.x / 2, size.y * 0.35);
    final eyeWidth = 40.0;
    final eyeHeight = 25.0;

    // Eye Shape
    final eyePath = Path()
      ..moveTo(eyeCenter.dx - eyeWidth / 2, eyeCenter.dy)
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeCenter.dy - eyeHeight,
        eyeCenter.dx + eyeWidth / 2,
        eyeCenter.dy,
      )
      ..quadraticBezierTo(
        eyeCenter.dx,
        eyeCenter.dy + eyeHeight,
        eyeCenter.dx - eyeWidth / 2,
        eyeCenter.dy,
      )
      ..close();

    canvas.drawPath(eyePath, eyeWhitePaint);

    // Glowing Pupil
    final pupilGlow = 0.7 + sin(_hoverTime * 4) * 0.3;
    canvas.drawCircle(
      eyeCenter,
      8,
      eyePupilPaint..color = Colors.blue.withOpacity(pupilGlow),
    );
    canvas.drawCircle(eyeCenter, 4, Paint()..color = Colors.black);

    // Rays of light
    final rayPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + _hoverTime * 0.5;
      canvas.drawLine(
        eyeCenter + Offset(cos(angle) * 25, sin(angle) * 20),
        eyeCenter + Offset(cos(angle) * 50, sin(angle) * 40),
        rayPaint,
      );
    }

    // 3. Hieroglyphics (Simple lines/dots)
    final symbolPaint = Paint()
      ..color = Colors.brown.withOpacity(0.4)
      ..strokeWidth = 1;
    for (int i = 0; i < 15; i++) {
      canvas.drawCircle(
        Offset(
          20 + _random.nextDouble() * (size.x - 40),
          50 + _random.nextDouble() * (size.y - 60),
        ),
        1,
        symbolPaint,
      );
    }
  }
}
