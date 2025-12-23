import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import '../audio/audio_manager.dart';
import 'boss_laser_beam.dart';

class WarplaneBoss extends PositionComponent
    with HasGameRef<SpectraSprintGame> {
  double _attackTimer = 3.0;
  final _random = Random();
  double _hoverTime = 0;
  bool _isCharging = false;
  double _chargeTimer = 0;
  bool _isCenterAttack = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(200, 120);
    anchor = Anchor.center;
    _updatePosition();
  }

  void _updatePosition() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    position = Vector2(gameRef.size.x / 2, vanishingPointY - 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    _hoverTime += dt;
    // Side to side sway
    position.x = gameRef.size.x / 2 + sin(_hoverTime * 1.2) * 60;
    position.y =
        (gameRef.size.y * GameConstants.vanishingPointYFactor - 50) +
        cos(_hoverTime * 2) * 8;

    if (_isCharging) {
      _chargeTimer += dt;
      if (_chargeTimer >= 0.8) {
        _performAttack(); // Now fire after charging
        _isCharging = false;
        _chargeTimer = 0;
      }
    } else {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        _startCharging();
        _attackTimer = 3.0 + _random.nextDouble() * 2;
      }
    }
  }

  void _startCharging() {
    _isCharging = true;
    _chargeTimer = 0;
    _isCenterAttack = _random.nextBool();
    AudioManager().playLaserSound(); // Play sound during charge/start
  }

  void _performAttack() {
    if (_isCenterAttack) {
      // Center beam from nose
      gameRef.world.add(
        BossLaserBeam(
          lanes: [1],
          beamColor: Colors.redAccent,
          sourcePosition: position + Vector2(0, 10),
        ),
      );
    } else {
      // Side beams from wing pods
      gameRef.world.add(
        BossLaserBeam(
          lanes: [0, 2],
          beamColor: Colors.cyanAccent,
          sourcePosition: position + Vector2(0, 20), // Mid-wing height
          isDouble: true,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final metalPaint = Paint()
      ..color = const Color(0xFF1A1A1A); // Dark charcoal
    final detailPaint = Paint()..color = const Color(0xFF333333);
    final cockpitPaint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.6);
    final glowPaint = Paint()
      ..color = _isCharging ? Colors.red : const Color(0xFF00FFCC);

    // 1. Delta Wings (More aggressive)
    final wingPath = Path()
      ..moveTo(size.x * 0.1, size.y * 0.4)
      ..lineTo(size.x * 0.9, size.y * 0.4)
      ..lineTo(size.x, size.y * 0.7)
      ..lineTo(size.x * 0.7, size.y * 0.9)
      ..lineTo(size.x * 0.3, size.y * 0.9)
      ..lineTo(0, size.y * 0.7)
      ..close();
    canvas.drawPath(
      wingPath,
      metalPaint,
    ); // Changed to metalPaint for consistency

    // 2. Main Fuselage
    final bodyPath = Path()
      ..moveTo(size.x * 0.4, 0)
      ..lineTo(size.x * 0.6, 0)
      ..lineTo(size.x * 0.65, size.y * 0.8)
      ..lineTo(size.x * 0.35, size.y * 0.8)
      ..close();
    canvas.drawPath(bodyPath, metalPaint);

    // 3. Cockpit
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.45, size.y * 0.1, size.x * 0.1, size.y * 0.25),
      cockpitPaint,
    );

    // 4. Laser Pods (Under wings)
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.5, 10, 20),
      detailPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.8 - 10, size.y * 0.5, 10, 20),
      detailPaint,
    );

    // 5. Engine Glow
    final engineGlow = Paint()
      ..color = glowPaint.color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.8), 10, engineGlow);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.8), 10, engineGlow);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.8), 5, glowPaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.8), 5, glowPaint);

    // 6. Charging Pulse
    if (_isCharging) {
      final pulse = (sin(_chargeTimer * 50) * 0.5 + 0.5);
      final chargePaint = Paint()
        ..color = (_isCenterAttack ? Colors.red : Colors.cyan).withOpacity(
          0.6 * pulse,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      if (_isCenterAttack) {
        canvas.drawCircle(
          Offset(size.x / 2, size.y * 0.1),
          15 * pulse,
          chargePaint,
        );
      } else {
        canvas.drawCircle(
          Offset(size.x * 0.2, size.y * 0.6),
          12 * pulse,
          chargePaint,
        );
        canvas.drawCircle(
          Offset(size.x * 0.8, size.y * 0.6),
          12 * pulse,
          chargePaint,
        );
      }
    }
  }
}
