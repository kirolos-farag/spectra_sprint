import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';

class BossLaserBeam extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final List<int> lanes;
  double lifeTime = 0.0;
  final double warningTime = 2.0; // مدة التحذير كما طلب المستخدم
  final double activeTime = 0.8; // مدة الإطلاق الفعلي
  late final double maxLifeTime;

  final Color beamColor;
  final Vector2 sourcePosition;
  final bool isDouble;

  BossLaserBeam({
    required this.lanes,
    required this.sourcePosition,
    this.beamColor = Colors.cyanAccent,
    this.isDouble = false,
  }) {
    maxLifeTime = warningTime + activeTime;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Non-physics based collision check in update
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifeTime += dt;
    if (lifeTime >= maxLifeTime) {
      removeFromParent();
    }

    // الضرب فقط بعد انتهاء الوجقت التحذيري (2 ثانية)
    if (lifeTime >= warningTime && lifeTime < maxLifeTime) {
      final player = gameRef.player;
      if (lanes.contains(player.currentLane) && !player.isJumping) {
        gameRef.onPlayerCollision();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final sizeX = gameRef.size.x;
    final sizeY = gameRef.size.y;
    final vanishingPointY = sizeY * GameConstants.vanishingPointYFactor;
    final trackHorizonWidth = sizeX * GameConstants.trackHorizonWidthFactor;

    final bool isWarning = lifeTime < warningTime;

    // حساب الـ Opacity بناءً على المرحلة
    double opacity;
    if (isWarning) {
      // وميض تحذيري يتسارع مع اقتراب الإطلاق
      final progress = lifeTime / warningTime;
      opacity = 0.2 + (sin(lifeTime * (10 + progress * 30)) * 0.15);
    } else {
      // وميض الإطلاق الفعلي (قوي)
      opacity = 0.5 + (sin(lifeTime * 50) * 0.3);
    }

    final paint = Paint()
      ..color = (isWarning ? Colors.red : beamColor).withOpacity(
        opacity.clamp(0, 1),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (int i = 0; i < lanes.length; i++) {
      final laneIndex = lanes[i];

      // Ground quad
      final laneWidthStart = trackHorizonWidth / 3;
      final laneWidthEnd = sizeX / 3;
      final roadStartX =
          (sizeX / 2 - trackHorizonWidth / 2) + (laneIndex * laneWidthStart);
      final roadEndX = laneIndex * laneWidthEnd;

      // Draw the "Volumetric" beam from boss to ground
      // We calculate the point at the horizon for this lane

      // Determine beam source for this specific lane if double
      Offset beamSource;
      if (isDouble) {
        // Lane 0 from left pod, Lane 2 from right pod
        final sideOffset = laneIndex == 0
            ? -gameRef.size.x * 0.3
            : gameRef.size.x * 0.3;
        beamSource = sourcePosition.toOffset() + Offset(sideOffset, 0);
      } else {
        beamSource = sourcePosition.toOffset();
      }

      // 1. رسم منطقة التحذير على الأرض دائماً
      final groundPath = Path()
        ..moveTo(roadStartX, vanishingPointY)
        ..lineTo(roadStartX + laneWidthStart, vanishingPointY)
        ..lineTo(roadEndX + laneWidthEnd, sizeY)
        ..lineTo(roadEndX, sizeY)
        ..close();
      canvas.drawPath(groundPath, paint);

      // 2. رسم الشعاع العمودي (فقط في وضع الإطلاق النشط)
      if (!isWarning) {
        final airPath = Path()
          ..moveTo(beamSource.dx - 15, beamSource.dy)
          ..lineTo(beamSource.dx + 15, beamSource.dy)
          ..lineTo(roadEndX + laneWidthEnd, sizeY)
          ..lineTo(roadEndX, sizeY)
          ..close();

        final airPaint = Paint()
          ..color = beamColor.withOpacity(opacity * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawPath(airPath, airPaint);

        // Solid core line
        canvas.drawLine(
          beamSource,
          Offset(roadEndX + laneWidthEnd / 2, sizeY),
          corePaint,
        );
      }
    }
  }
}
