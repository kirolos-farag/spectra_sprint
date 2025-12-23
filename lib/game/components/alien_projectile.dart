import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';

class AlienProjectile extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  double z = 1.0;

  AlienProjectile(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Aliens are tall, making them non-jumpable
    size = Vector2(50, 100);

    add(RectangleHitbox());
    _updateTransform();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    z -= (gameRef.currentSpeed / 450.0) * dt;

    if (z <= 0) {
      removeFromParent();
      return;
    }

    _updateTransform();
  }

  void _updateTransform() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    final t = (1.0 - z).clamp(0.0, 1.0);
    final y = vanishingPointY + t * (gameRef.size.y - vanishingPointY);

    final currentScale =
        (GameConstants.minScale +
                t * (GameConstants.maxScale - GameConstants.minScale))
            .clamp(0.1, 1.2);
    scale = Vector2.all(currentScale);

    final trackHorizonWidth =
        gameRef.size.x * GameConstants.trackHorizonWidthFactor;
    final trackBottomWidth = gameRef.size.x;
    final currentTrackWidth =
        trackHorizonWidth + t * (trackBottomWidth - trackHorizonWidth);

    final laneWidth = currentTrackWidth / 3;
    final laneOffset = (lane - 1) * laneWidth;
    final centerX = gameRef.size.x / 2 + laneOffset;

    position = Vector2(
      centerX - (size.x * currentScale) / 2,
      y - size.y * currentScale,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()..color = const Color(0xFF2ECC71); // Emerald Green
    final headPaint = Paint()..color = const Color(0xFF27AE60);
    final eyePaint = Paint()..color = Colors.black;
    final pupilPaint = Paint()..color = Colors.greenAccent.withOpacity(0.5);

    // 1. Body (Slim alien shape)
    final bodyPath = Path()
      ..moveTo(size.x * 0.3, size.y)
      ..lineTo(size.x * 0.2, size.y * 0.4)
      ..lineTo(size.x * 0.8, size.y * 0.4)
      ..lineTo(size.x * 0.7, size.y)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // 2. Head (Large bulbous head)
    final headRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.45);
    canvas.drawOval(headRect, headPaint);

    // 3. Large Alien Eyes (Classic almond shape)
    final leftEye = Path()
      ..moveTo(size.x * 0.15, size.y * 0.15)
      ..quadraticBezierTo(
        size.x * 0.3,
        size.y * 0.05,
        size.x * 0.45,
        size.y * 0.25,
      )
      ..quadraticBezierTo(
        size.x * 0.3,
        size.y * 0.35,
        size.x * 0.15,
        size.y * 0.15,
      )
      ..close();
    canvas.drawPath(leftEye, eyePaint);

    final rightEye = Path()
      ..moveTo(size.x * 0.85, size.y * 0.15)
      ..quadraticBezierTo(
        size.x * 0.7,
        size.y * 0.05,
        size.x * 0.55,
        size.y * 0.25,
      )
      ..quadraticBezierTo(
        size.x * 0.7,
        size.y * 0.35,
        size.x * 0.85,
        size.y * 0.15,
      )
      ..close();
    canvas.drawPath(rightEye, eyePaint);

    // Pupil glints
    canvas.drawCircle(Offset(size.x * 0.25, size.y * 0.18), 3, pupilPaint);
    canvas.drawCircle(Offset(size.x * 0.75, size.y * 0.18), 3, pupilPaint);

    // 4. Glow around head
    canvas.drawOval(
      headRect,
      Paint()
        ..color = Colors.greenAccent.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      if (z > 0.15) return;

      // Critical check: Collision happens even if jumping because aliens are tall
      gameRef.onPlayerCollision();
      removeFromParent();
    }
  }
}
