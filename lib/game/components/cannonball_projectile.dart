import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';

class CannonballProjectile extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  double z = 1.0;
  final _random = Random();

  CannonballProjectile(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(50, 50);
    add(CircleHitbox());
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
    _addTrail();
  }

  void _addTrail() {
    gameRef.world.add(
      ParticleSystemComponent(
        particle: TranslatedParticle(
          lifespan: 0.2,
          offset: position + size / 2,
          child: AcceleratedParticle(
            acceleration: Vector2(0, 50),
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 30,
              (_random.nextDouble() - 0.5) * 30,
            ),
            child: CircleParticle(
              radius: 1 + _random.nextDouble() * 2,
              paint: Paint()..color = Colors.grey.withOpacity(0.5),
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

    // Simulating a slight arc for the cannonball
    final arcHeight = sin(t * pi) * 40;
    final y =
        vanishingPointY + t * (gameRef.size.y - vanishingPointY) - arcHeight;

    final currentScale =
        (GameConstants.minScale +
                t * (GameConstants.maxScale - GameConstants.minScale))
            .clamp(0.1, 1.4);
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

    // Dark grey/black cannonball
    canvas.drawCircle(
      center,
      size.x * 0.45,
      Paint()..color = const Color(0xFF202020),
    );

    // Subtle metallic highlight
    canvas.drawCircle(
      center - const Offset(5, 5),
      size.x * 0.15,
      Paint()..color = Colors.white24,
    );

    // Rim for definition
    canvas.drawCircle(
      center,
      size.x * 0.45,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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
