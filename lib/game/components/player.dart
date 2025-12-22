import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' hide TextStyle;
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import '../audio/audio_manager.dart';

// الشخصية الرئيسية
class Player extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  // حالة اللاعب
  PlayerColor currentColor = PlayerColor.red;
  bool isJumping = false;
  bool isSliding = false;
  double verticalVelocity = 0;

  // المسار الحالي (0, 1, 2)
  int currentLane = 1;
  double targetX = 0;

  // نظام القدرات
  bool abilityActive = false;
  double abilityTimer = 0;
  double cooldownTimer = 0;
  double opacity = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // تحديد الحجم والموضع الأولي
    size = Vector2(GameConstants.playerWidth, GameConstants.playerHeight);

    // الموضع الابتدائي (Y ثابت في الأسفل قليلاً)
    final initialY = gameRef.size.y - size.y - 50;
    position = Vector2(0, initialY);
    _updatePositionAndScale();

    // إضافة collision box
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // تطبيق الجاذبية والقفز
    if (isJumping) {
      verticalVelocity += GameConstants.gravity * dt;
      position.y += verticalVelocity * dt;

      // حساب الـ groundY بناءً على الحجم الحالي
      final groundY = gameRef.size.y - size.y * scale.y - 50;
      if (position.y >= groundY) {
        position.y = groundY;
        isJumping = false;
        verticalVelocity = 0;
      }
    }

    // تحديث الموقع والمقياس بناءً على Y للمنظور
    _updatePositionAndScale();

    // تحديث timer القدرة
    if (abilityActive) {
      abilityTimer -= dt;
      if (abilityTimer <= 0) {
        deactivateAbility();
      }
    }

    // تحديث cooldown
    if (cooldownTimer > 0) {
      cooldownTimer -= dt;
    }
  }

  void _updatePositionAndScale() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;

    // حساب المقياس بناءً على موضع الأرض الافتراضي
    final groundY = gameRef.size.y - GameConstants.playerHeight - 50;

    final t = ((groundY - vanishingPointY) / (gameRef.size.y - vanishingPointY))
        .clamp(0.0, 1.0);

    final currentScale =
        (GameConstants.minScale +
                t * (GameConstants.maxScale - GameConstants.minScale))
            .clamp(0.1, 1.0);
    scale = Vector2.all(currentScale);

    // حساب عرض المسار عند هذا العمق
    final trackHorizonWidth =
        gameRef.size.x * GameConstants.trackHorizonWidthFactor;
    final trackBottomWidth = gameRef.size.x;

    final currentTrackWidth =
        trackHorizonWidth + t * (trackBottomWidth - trackHorizonWidth);

    // حساب الموضع X بناءً على المسار والمنظور
    final laneWidth = currentTrackWidth / 3;
    final laneOffset = (currentLane - 1) * laneWidth;
    final centerX = gameRef.size.x / 2 + laneOffset;

    position.x = centerX - (size.x * currentScale) / 2;
  }

  @override
  void render(Canvas canvas) {
    if (!size.x.isFinite || !size.y.isFinite || !scale.x.isFinite) return;
    super.render(canvas);

    final playerWidth = size.x * scale.x;
    final playerHeight = size.y * scale.y;

    // حساب ارتفاع القفزة لتعديل الظل
    final groundYPosition =
        gameRef.size.y - GameConstants.playerHeight * scale.y - 50;
    final jumpDisplacement = (groundYPosition - position.y).clamp(0.0, 500.0);
    final jumpRatio = (jumpDisplacement / 200.0).clamp(0.0, 1.0);

    // رسم الظل الأسود (Shadow)
    final shadowPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.4 * (1.0 - jumpRatio * 0.7)) // يبهت مع الارتفاع
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final shadowPath = Path();
    // إزاحة الظل للأسفل بمقدار القفزة ليبقى على الأرض
    final shadowYOffset = playerHeight + jumpDisplacement;

    // تصغير الظل قليلاً مع الارتفاع
    final shadowScale = 1.0 - (jumpRatio * 0.2);
    final sWidth = playerWidth * shadowScale;
    final sLeft = (playerWidth - sWidth) / 2;

    shadowPath.moveTo(sLeft, shadowYOffset);
    shadowPath.lineTo(sLeft + sWidth, shadowYOffset);
    shadowPath.lineTo(sLeft + sWidth * 1.5, shadowYOffset + 20);
    shadowPath.lineTo(sLeft - sWidth * 0.5, shadowYOffset + 20);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);

    // رسم الشخصية الـ Voxel
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white.withOpacity(opacity),
    );
    _renderVoxelCharacter(canvas, playerWidth, playerHeight);
    canvas.restore();

    // إضافة وميض محيطي (Aura)
    final auraPaint = Paint()
      ..color = _getCharacterBaseColor().withOpacity(
        0.15 * (1.0 - jumpRatio) * opacity,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      Offset(playerWidth / 2, playerHeight / 2),
      playerWidth * 0.9,
      auraPaint,
    );
  }

  Color _getCharacterBaseColor() {
    final colors = {
      PlayerColor.red: Color(GameConstants.colorRed),
      PlayerColor.blue: Color(GameConstants.colorBlue),
      PlayerColor.yellow: Color(GameConstants.colorYellow),
      PlayerColor.purple: Color(GameConstants.colorPurple),
    };
    return colors[currentColor] ?? Colors.white;
  }

  void _renderVoxelCharacter(Canvas canvas, double width, double height) {
    // حساب الأنيميشن بناءً على الوقت والسرعة
    final animSpeed = 10.0 + (gameRef.currentSpeed / 100.0);
    final oscillation = sin(gameRef.elapsedTime * animSpeed);

    // وضعيات القفز
    final jumpFactor = isJumping ? 1.0 : 0.0;

    // الألوان الأساسية بناءً على الصورة
    final baseBlue = const Color(0xFF2B3A8C); // أزرق غامق للجسم
    final strokePaint = Paint()
      ..color = const Color(0xFF5CC0F8)
          .withOpacity(0.5) // حدود نيون زرقاء
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bodyPaint = Paint()..color = baseBlue;

    // 1. رسم الجسم الرئيسي (مكعب)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.15, height * 0.2, width * 0.7, height * 0.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, strokePaint);

    // 2. رسم الأطراف (أذرع وأرجل) مع أنيميشن
    final limbPaint = Paint()..color = baseBlue;

    // أرجل (تتحرك بشكل تبادلي)
    final legSwing = oscillation * height * 0.1 * (1.0 - jumpFactor);
    final leftLegY = height * 0.8 + legSwing;
    final rightLegY = height * 0.8 - legSwing;

    // في حالة القفز، الأرجل تنثني قليلاً
    final jumpLegOffset = jumpFactor * height * 0.05;

    canvas.drawRect(
      Rect.fromLTWH(
        width * 0.3,
        leftLegY - jumpLegOffset,
        width * 0.15,
        height * 0.2,
      ),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        width * 0.55,
        rightLegY - jumpLegOffset,
        width * 0.15,
        height * 0.2,
      ),
      limbPaint,
    );

    // أذرع
    final armSwing = oscillation * height * 0.1 * (1.0 - jumpFactor);
    // في القفز، الأذرع ترتفع للأعلى
    final leftArmY = isJumping ? height * 0.1 : height * 0.4 + armSwing;
    final rightArmY = isJumping ? height * 0.1 : height * 0.4 - armSwing;

    canvas.drawRect(
      Rect.fromLTWH(width * 0.05, leftArmY, width * 0.1, height * 0.3),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(width * 0.85, rightArmY, width * 0.1, height * 0.3),
      limbPaint,
    );

    // تم إزالة الوجه (العيون والفم) لكي يبدو اللاعب وكأنه يواجه الطريق للأمام
  }

  // القفز
  void jump() {
    if (!isJumping && !isSliding) {
      isJumping = true;
      if (currentColor == PlayerColor.blue && abilityActive) {
        verticalVelocity = GameConstants.jumpVelocity * 1.5;
      } else {
        verticalVelocity = GameConstants.jumpVelocity;
      }
      AudioManager().playJumpSound();
    }
  }

  // الانتقال لليمين
  void moveRight() {
    if (currentLane < GameConstants.numberOfLanes - 1) {
      currentLane++;
    }
  }

  // الانتقال لليسار
  void moveLeft() {
    if (currentLane > 0) {
      currentLane--;
    }
  }

  // الانزلاق (تم تعطيله بناءً على طلب المستخدم)
  void slide() {
    // تم إلغاء التزحلق لتبسيط أسلوب اللعب
  }

  // تغيير اللون
  void changeColor(PlayerColor newColor) {
    if (currentColor != newColor) {
      currentColor = newColor;
      AudioManager().playColorChangeSound();
    }
  }

  // تفعيل القدرة
  void activateAbility() {
    if (cooldownTimer <= 0) {
      abilityActive = true;
      abilityTimer = GameConstants.abilityDuration;
      cooldownTimer = GameConstants.abilityCooldown;
      AudioManager().playAbilityActivateSound();
      switch (currentColor) {
        case PlayerColor.red:
          gameRef.currentSpeed *= 1.5;
          break;
        case PlayerColor.blue:
          break;
        case PlayerColor.yellow:
          break;
        case PlayerColor.purple:
          gameRef.currentSpeed *= 0.5;
          break;
      }
    }
  }

  // إلغاء تفعيل القدرة
  void deactivateAbility() {
    abilityActive = false;
    if (currentColor == PlayerColor.red || currentColor == PlayerColor.purple) {
      gameRef.currentSpeed =
          GameConstants.baseSpeed +
          (gameRef.elapsedTime * GameConstants.speedIncrement);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
  }

  // إعادة تعيين اللاعب
  void reset() {
    currentColor = PlayerColor.red;
    isJumping = false;
    isSliding = false;
    verticalVelocity = 0;
    currentLane = 1;
    abilityActive = false;
    abilityTimer = 0;
    cooldownTimer = 0;
    position = Vector2(0, gameRef.size.y - size.y - 50);
    _updatePositionAndScale();
  }
}
