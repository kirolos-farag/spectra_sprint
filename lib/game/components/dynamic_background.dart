import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';

import 'package:spectra_sprint/game/stages/stage_config.dart';
import 'package:spectra_sprint/game/stages/stage_registry.dart';

class DynamicBackground extends Component with HasGameRef<SpectraSprintGame> {
  // طبقات الخلفية
  late List<_BackgroundLayer> layers;

  // إدارة المراحل
  StageTheme currentTheme = StageRegistry.getStage(0);
  StageTheme? targetTheme;
  double themeTransitionProgress = 1.0; // 1.0 يعني اكتمال الانتقال
  double safeStageTimer = 0.0; // وقت حماية في بداية المرحلة (للطريق)

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // إنشاء طبقات parallax
    layers = [
      _BackgroundLayer(0.2, const Color(0xFF1A0033)),
      _BackgroundLayer(0.4, const Color(0xFF2E0052)),
      _BackgroundLayer(0.6, const Color(0xFF4A0A7A)),
    ];

    for (var layer in layers) {
      add(layer);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // تحديث مؤقت الحماية
    if (safeStageTimer > 0) {
      safeStageTimer -= dt;
    }

    // تحديث انتقال المراحل (نعومة الانتقال بين الألوان)
    if (themeTransitionProgress < 1.0) {
      themeTransitionProgress += dt * 0.5; // يستغرق الانتقال ثانيتين
      if (themeTransitionProgress >= 1.0) {
        themeTransitionProgress = 1.0;
        if (targetTheme != null) {
          currentTheme = targetTheme!;
          targetTheme = null;
        }
      }
    }
  }

  // تغيير المرحلة
  void setStage(StageTheme newTheme) {
    if (newTheme.name == currentTheme.name) return;
    targetTheme = newTheme;
    themeTransitionProgress = 0.0;

    // إذا كانت المرحلة الجديدة متقطعة، نعطي 5 ثواني طريق سليم كبداية آمنة
    if (newTheme.isFragmented) {
      safeStageTimer = 5.0;
    } else {
      safeStageTimer = 0.0;
    }
  }

  // تحديث السرعة
  void updateSpeed(double speed) {
    final speedRatio =
        (speed - GameConstants.baseSpeed) /
        (GameConstants.maxSpeed - GameConstants.baseSpeed);

    for (var layer in layers) {
      layer.updateSpeed(speedRatio);
    }
  }
}

// طبقة خلفية واحدة
class _BackgroundLayer extends PositionComponent
    with HasGameRef<SpectraSprintGame> {
  final double speedMultiplier;
  final Color baseColor;
  double currentSpeed = 0;
  final List<_Star> stars = [];
  final _random = Random();

  _BackgroundLayer(this.speedMultiplier, this.baseColor);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = gameRef.size;
    position = Vector2.zero();

    // توليد النجوم العشوائية
    for (int i = 0; i < 100; i++) {
      stars.add(
        _Star(
          position: Offset(_random.nextDouble(), _random.nextDouble()),
          size: 0.5 + _random.nextDouble() * 2.0,
          opacity: 0.2 + _random.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // تحريك النجوم ببطء لعمل تأثير Parallax
    final speed = (gameRef.currentSpeed / 1000.0) * speedMultiplier;
    for (var star in stars) {
      star.y += speed * dt;
      if (star.y > 1.1) {
        star.y = -0.1;
        star.x = _random.nextDouble();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sizeX = gameRef.size.x;
    final sizeY = gameRef.size.y;
    final vanishingPointY = sizeY * GameConstants.vanishingPointYFactor;

    if (!vanishingPointY.isFinite || vanishingPointY <= 0) return;

    // هامش أمان للهزة لمنع ظهور حواف سوداء
    const double margin = 50.0;

    // حساب الألوان الحالية بناءً على التقدم في الانتقال
    final background = gameRef.background;
    final theme = background.currentTheme;
    final t = background.themeTransitionProgress;

    // دالة مساعدة لخلط الألوان
    Color mix(Color c1, Color c2) => Color.lerp(c1, c2, t)!;

    final roadColor = background.targetTheme != null
        ? mix(theme.roadColor, background.targetTheme!.roadColor)
        : theme.roadColor;
    final skyColorTop = background.targetTheme != null
        ? mix(theme.skyColorTop, background.targetTheme!.skyColorTop)
        : theme.skyColorTop;
    final skyColorBottom = background.targetTheme != null
        ? mix(theme.skyColorBottom, background.targetTheme!.skyColorBottom)
        : theme.skyColorBottom;
    final voidColorStart = background.targetTheme != null
        ? mix(theme.voidColorStart, background.targetTheme!.voidColorStart)
        : theme.voidColorStart;
    final voidColorEnd = background.targetTheme != null
        ? mix(theme.voidColorEnd, background.targetTheme!.voidColorEnd)
        : theme.voidColorEnd;
    final lineLineColor = background.targetTheme != null
        ? mix(theme.laneLineColor, background.targetTheme!.laneLineColor)
        : theme.laneLineColor;

    // رسم فراغ ملون متدرج (Vibrant Gradient Void) بمساحة أكبر من الشاشة
    final voidRect = Rect.fromLTWH(
      -margin,
      -margin,
      sizeX + margin * 2,
      sizeY + margin * 2,
    );
    final voidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [voidColorStart, voidColorEnd],
      ).createShader(voidRect);
    canvas.drawRect(voidRect, voidPaint);

    // رسم الخلفية العلوية (السماء الملونة المتغيرة) - أوسع من الشاشة
    final skyRect = Rect.fromLTWH(
      -margin,
      -margin,
      sizeX + margin * 2,
      vanishingPointY + margin,
    );

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyColorTop, skyColorBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // رسم النجوم (فوق الخلفية وتحت الطريق)
    _renderStars(
      canvas,
      sizeX,
      sizeY,
      vanishingPointY,
      sizeX * GameConstants.trackHorizonWidthFactor,
    );

    // رسم الطريق والخطوط (إذا لم يكن متقطعاً أو كان بها حارة مختفية فقط)
    if (!theme.isVanishingLane ||
        background.safeStageTimer > 0 ||
        theme.name != 'SHATTERED REALITY') {
      // (نفس منطق رسم الطريق الحالي...)
      _renderSolidRoad(
        canvas,
        sizeX,
        vanishingPointY,
        roadColor,
        lineLineColor,
      );
    } else if (theme.isVanishingLane) {
      // رسم الطريق بالكامل مع تظليل الحارة الخطيرة
      _renderSolidRoad(
        canvas,
        sizeX,
        vanishingPointY,
        roadColor,
        lineLineColor,
      );
      // رسم حارة التحذير (حمراء)
      _renderGlitchLane(
        canvas,
        sizeX,
        vanishingPointY,
        gameRef.warningLaneIndex,
        Colors.red,
        true,
      );
      // رسم الحارة المختفية (بيضاء)
      _renderGlitchLane(
        canvas,
        sizeX,
        vanishingPointY,
        gameRef.vanishingLaneIndex,
        Colors.white,
        false,
      );
    }
  }

  void _renderSolidRoad(
    Canvas canvas,
    double sizeX,
    double vanishingPointY,
    Color roadColor,
    Color lineLineColor,
  ) {
    final trackHorizonWidth = sizeX * GameConstants.trackHorizonWidthFactor;
    final roadPaint = Paint()..color = roadColor;
    final roadPath = Path();
    roadPath.moveTo(0, gameRef.size.y);
    roadPath.lineTo(gameRef.size.x, gameRef.size.y);
    roadPath.lineTo(
      gameRef.size.x / 2 + trackHorizonWidth / 2,
      vanishingPointY,
    );
    roadPath.lineTo(
      gameRef.size.x / 2 - trackHorizonWidth / 2,
      vanishingPointY,
    );
    roadPath.close();
    canvas.drawPath(roadPath, roadPaint);

    final linePaint = Paint()
      ..color = lineLineColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i < GameConstants.numberOfLanes; i++) {
      final ratio = i / GameConstants.numberOfLanes;
      final startX =
          (gameRef.size.x / 2 - trackHorizonWidth / 2) +
          trackHorizonWidth * ratio;
      final endX = gameRef.size.x * ratio;
      canvas.drawLine(
        Offset(startX, vanishingPointY),
        Offset(endX, gameRef.size.y),
        linePaint,
      );
    }
  }

  void _renderGlitchLane(
    Canvas canvas,
    double sizeX,
    double vanishingPointY,
    int laneIndex,
    Color color,
    bool isWarning,
  ) {
    if (laneIndex < 0) return;

    final trackHorizonWidth = sizeX * GameConstants.trackHorizonWidthFactor;

    // تأثير وميض
    final flashOpacity = isWarning
        ? 0.2 +
              (sin(gameRef.elapsedTime * 15) * 0.1) // وميض أبطأ للتحذير
        : 0.3 + (sin(gameRef.elapsedTime * 20) * 0.2); // وميض سريع للخطر

    final glitchPaint = Paint()
      ..color = color.withOpacity(flashOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isWarning ? 5 : 10);

    final laneWidthStart = trackHorizonWidth / 3;
    final laneWidthEnd = sizeX / 3;

    final startX =
        (gameRef.size.x / 2 - trackHorizonWidth / 2) +
        (laneIndex * laneWidthStart);
    final endX = laneIndex * laneWidthEnd;

    final path = Path();
    path.moveTo(startX, vanishingPointY);
    path.lineTo(startX + laneWidthStart, vanishingPointY);
    path.lineTo(endX + laneWidthEnd, gameRef.size.y);
    path.lineTo(endX, gameRef.size.y);
    path.close();

    canvas.drawPath(path, glitchPaint);

    // رسم حدود ملونة
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isWarning ? 5 : 3; // حدود أعرض للتحذير

    // إذا كان تحذير، نضيف بريق أحمر خارجي
    if (isWarning) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawPath(path, borderPaint);
  }

  void updateSpeed(double speedRatio) {
    currentSpeed = speedRatio * speedMultiplier;
  }

  void _renderStars(
    Canvas canvas,
    double sizeX,
    double sizeY,
    double vanishingPointY,
    double trackHorizonWidth,
  ) {
    for (var star in stars) {
      final x = star.x * sizeX;
      final y = star.y * sizeY;

      // لا نرسم النجم إذا كان فوق خط الأفق
      if (y < vanishingPointY) continue;

      // تحقق مما إذا كان النجم يقع داخل نطاق الطريق
      final t = (y - vanishingPointY) / (sizeY - vanishingPointY);
      final currentTrackWidth =
          trackHorizonWidth + t * (sizeX - trackHorizonWidth);
      final leftBound = sizeX / 2 - currentTrackWidth / 2;
      final rightBound = sizeX / 2 + currentTrackWidth / 2;

      if (x < leftBound || x > rightBound) {
        final starPaint = Paint()
          ..color = Colors.white.withOpacity(star.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), star.size, starPaint);
      }
    }
  }
}

class _Star {
  double x;
  double y;
  final double size;
  final double opacity;

  _Star({required Offset position, required this.size, required this.opacity})
    : x = position.dx,
      y = position.dy;
}
