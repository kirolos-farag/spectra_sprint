import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';

class FireProjectile extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  double z = 1.0;
  final _random = Random();

  FireProjectile(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 60);

    add(CircleHitbox());
    _updateTransform();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    z -=
        (gameRef.currentSpeed / 400.0) *
        dt; // slightly faster than normal obstacles

    if (z <= 0) {
      removeFromParent();
      return;
    }

    _updateTransform();
    _addTrail();
  }

  void _addTrail() {
    gameRef.world.add(
      ParticleSystemComponent(
        particle: TranslatedParticle(
          lifespan: 0.3,
          offset: position + size / 2,
          child: AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 50,
              (_random.nextDouble() - 0.5) * 50,
            ),
            child: CircleParticle(
              radius: 2 + _random.nextDouble() * 3,
              paint: Paint()..color = Colors.orange.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _updateTransform() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;
    final t = (1.0 - z).clamp(0.0, 1.0);
    final y = vanishingPointY + t * (gameRef.size.y - vanishingPointY);

    final currentScale =
        (GameConstants.minScale +
                t * (GameConstants.maxScale - GameConstants.minScale))
            .clamp(0.1, 1.5);
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
    final center = (size / 2).toOffset();

    // Core of fireball
    canvas.drawCircle(center, size.x * 0.4, Paint()..color = Colors.yellow);

    // Outer glow
    canvas.drawCircle(
      center,
      size.x * 0.5,
      Paint()
        ..color = Colors.orange
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Inner core
    canvas.drawCircle(center, size.x * 0.2, Paint()..color = Colors.white);
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
