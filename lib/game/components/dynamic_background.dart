import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';

class DynamicBackground extends Component with HasGameRef<SpectraSprintGame> {
  // طبقات الخلفية
  late List<_BackgroundLayer> layers;

  // اللون الحالي
  Color currentColor = const Color(0xFF0A001A);
  double colorTransition = 0;

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

    // تحديث انتقال الألوان - يتأثر بسرعة اللاعب
    final speedMultiplier = gameRef.currentSpeed / GameConstants.baseSpeed;
    colorTransition += dt * 0.3 * speedMultiplier;
    if (colorTransition > 1) colorTransition = 0;
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

    // رسم فراغ ملون متدرج (Vibrant Gradient Void) بمساحة أكبر من الشاشة
    final baseHue = (gameRef.elapsedTime * 30) % 360;
    final color1 = HSVColor.fromAHSV(1.0, baseHue, 0.8, 0.4).toColor();
    final color2 = HSVColor.fromAHSV(
      1.0,
      (baseHue + 40) % 360,
      0.8,
      0.3,
    ).toColor();
    final color3 = HSVColor.fromAHSV(
      1.0,
      (baseHue + 80) % 360,
      0.8,
      0.2,
    ).toColor();

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
        colors: [color1, color2, color3],
      ).createShader(voidRect);
    canvas.drawRect(voidRect, voidPaint);

    // رسم الخلفية العلوية (السماء الملونة المتغيرة) - أوسع من الشاشة
    final skyRect = Rect.fromLTWH(
      -margin,
      -margin,
      sizeX + margin * 2,
      vanishingPointY + margin,
    );

    final hue = (gameRef.elapsedTime * 20) % 360;
    final skyColor1 = HSVColor.fromAHSV(1.0, hue, 0.9, 0.4).toColor();
    final skyColor2 = HSVColor.fromAHSV(
      1.0,
      (hue + 60) % 360,
      0.9,
      0.2,
    ).toColor();

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyColor1, skyColor2],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // رسم الطريق (شبه منحرف) - مع توسيع القاعدة لتغطية الهزة
    final trackHorizonWidth = sizeX * GameConstants.trackHorizonWidthFactor;
    final roadPath = Path();
    roadPath.moveTo(sizeX / 2 - trackHorizonWidth / 2, vanishingPointY);
    roadPath.lineTo(sizeX / 2 + trackHorizonWidth / 2, vanishingPointY);
    roadPath.lineTo(sizeX + margin, sizeY + margin); // توسيع لليمين
    roadPath.lineTo(-margin, sizeY + margin); // توسيع لليسار
    roadPath.close();

    // رسم النجوم (فوق الخلفية وتحت الطريق)
    _renderStars(canvas, sizeX, sizeY, vanishingPointY, trackHorizonWidth);

    // رسم الطريق (لون أسفلت غامق واقعي)
    final roadPaint = Paint()
      ..color = const Color(0xFF1A1A1A); // رمادي غامق جداً (أسفلت)
    canvas.drawPath(roadPath, roadPaint);

    // رسم خطوط المسارات (خطوط بيضاء ناصعة)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (int i = 1; i <= 2; i++) {
      final xTop =
          (sizeX / 2 - trackHorizonWidth / 2) + i * (trackHorizonWidth / 3);
      final xBottom = i * (sizeX / 3);

      canvas.drawLine(
        Offset(xTop, vanishingPointY),
        Offset(xBottom, sizeY + margin), // زيادة الطول لتجنب الفراغات
        linePaint,
      );
    }
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
