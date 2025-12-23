import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';

class MummyProjectile extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  double z = 1.0;

  MummyProjectile(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 90);
    add(RectangleHitbox());
    _updateTransform();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    z -= (gameRef.currentSpeed / 550.0) * dt; // Slowed down from 400.0

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
            .clamp(0.1, 1.3);
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

    final bandagePaint = Paint()..color = const Color(0xFFF5F5DC); // Beige
    final shadowPaint = Paint()..color = Colors.brown.withOpacity(0.5);
    final eyePaint = Paint()..color = Colors.red;

    // Body (Simplified Mummy)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 20, size.x - 20, size.y - 20),
        const Radius.circular(5),
      ),
      bandagePaint,
    );

    // Head
    canvas.drawOval(Rect.fromLTWH(15, 0, size.x - 30, 30), bandagePaint);

    // Bandage lines
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(10, 30 + i * 10),
        Offset(size.x - 10, 25 + i * 10),
        linePaint,
      );
    }

    // Glowing Red Eyes
    canvas.drawCircle(Offset(22, 15), 3, eyePaint);
    canvas.drawCircle(Offset(size.x - 22, 15), 3, eyePaint);

    // Shadow under
    canvas.drawRect(Rect.fromLTWH(10, size.y - 5, size.x - 20, 5), shadowPaint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      if (z > 0.15) return;
      gameRef.onPlayerCollision();
      removeFromParent();
    }
  }
}
