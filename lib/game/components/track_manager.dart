import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';

// مدير المسار - توليد العوائق والعملات بمنظور ثلاثي الأبعاد
class TrackManager extends Component with HasGameRef<SpectraSprintGame> {
  // قائمة العوائق والعملات
  final List<TrackObstacle> obstacles = [];
  final List<Coin> coins = [];

  // تتبع المسافة لظهور الأشياء (بالنسبة لـ Z)
  double nextObstacleZ = 0.5;
  double nextCoinZ = 0.3;

  final Random random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateInitialTrack();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    final speed = gameRef.currentSpeed / 500.0; // تحويل السرعة لمعدل Z

    // توليد عوائق جديدة
    nextObstacleZ -= speed * dt;
    if (nextObstacleZ <= 0) {
      _generateObstacle();
      nextObstacleZ = 0.5 + random.nextDouble() * 0.5;
    }

    // توليد عملات جديدة (تقليل التكرار)
    nextCoinZ -= speed * dt;
    if (nextCoinZ <= 0) {
      _generateCoin();
      nextCoinZ = 0.4 + random.nextDouble() * 0.5;
    }
  }

  void _generateInitialTrack() {
    nextObstacleZ = 1.0;
    nextCoinZ = 0.5;
  }

  void _generateObstacle() {
    // تحديد الحارات المشغولة بالعملات القريبة جداً من نقطة البداية
    final occupiedByCoins = coins
        .where((c) => c.z > 0.8)
        .map((c) => c.lane)
        .toSet();

    // إنشاء قائمة بالحارات المتاحة
    final availableLanes = List.generate(
      GameConstants.numberOfLanes,
      (i) => i,
    ).where((i) => !occupiedByCoins.contains(i)).toList();

    if (availableLanes.isEmpty) return; // نادراً ما يحدث

    final lane = availableLanes[random.nextInt(availableLanes.length)];
    final type =
        ObstacleType.values[random.nextInt(ObstacleType.values.length)];

    final obstacle = TrackObstacle(lane, type);
    add(obstacle);
    obstacles.add(obstacle);
  }

  void _generateCoin() {
    // تحديد الحارات المشغولة بالعوائق القريبة جداً من نقطة البداية
    final occupiedByObstacles = obstacles
        .where((o) => o.z > 0.8)
        .map((o) => o.lane)
        .toSet();

    // إنشاء قائمة بالحارات المتاحة
    final availableLanes = List.generate(
      GameConstants.numberOfLanes,
      (i) => i,
    ).where((i) => !occupiedByObstacles.contains(i)).toList();

    if (availableLanes.isEmpty) return; // نادراً ما يحدث

    final lane = availableLanes[random.nextInt(availableLanes.length)];

    final coin = Coin(lane);
    add(coin);
    coins.add(coin);
  }

  void reset() {
    for (var obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();

    for (var coin in coins) {
      coin.removeFromParent();
    }
    coins.clear();

    _generateInitialTrack();
  }
}

// عائق في المسار بمنظور ثلاثي الأبعاد
class TrackObstacle extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  final ObstacleType type;
  double z = 1.0; // العمق (1 = بعيد، 0 = قريب)

  TrackObstacle(this.lane, this.type);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final trackBottomWidth = gameRef.size.x;
    final width = (trackBottomWidth / GameConstants.numberOfLanes) * 0.8;
    final height = type == ObstacleType.high ? 60.0 : 40.0;
    size = Vector2(width, height);

    // جعل صندوق الاصطدام أصغر قليلاً من الأعلى لتسهيل القفز
    add(
      RectangleHitbox(
        size: Vector2(size.x, size.y * 0.8),
        position: Vector2(0, size.y * 0.2),
      ),
    );

    _updateTransform();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // رسم منطقة الظل (Shadow Zone)
    final shadowPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRRect(rrect, shadowPaint);

    // رسم البوردر الأبيض (الجوانب وفوق)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final borderPath = Path()
      ..moveTo(0, size.y)
      ..lineTo(0, 8) // بداية الانحناء
      ..arcToPoint(const Offset(8, 0), radius: const Radius.circular(8))
      ..lineTo(size.x - 8, 0)
      ..arcToPoint(Offset(size.x, 8), radius: const Radius.circular(8))
      ..lineTo(size.x, size.y);

    canvas.drawPath(borderPath, borderPaint);

    // توهج أرجواني غامق (Shadow Aura) في الأسفل
    final auraPaint = Paint()
      ..color = const Color(0xFFB536FF).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, auraPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    // التحرك من الخلف للأمام
    z -= (gameRef.currentSpeed / 500.0) * dt;

    if (z <= 0) {
      removeFromParent();
      (parent as TrackManager).obstacles.remove(this);
      return;
    }

    _updateTransform();
  }

  void _updateTransform() {
    final vanishingPointY =
        gameRef.size.y * GameConstants.vanishingPointYFactor;

    // حساب المقياس والموقع بناءً على Z
    final t = (1.0 - z).clamp(0.0, 1.0);
    final y = vanishingPointY + t * (gameRef.size.y - vanishingPointY);

    final currentScale =
        (GameConstants.minScale +
                t * (GameConstants.maxScale - GameConstants.minScale))
            .clamp(0.1, 1.0);
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      // إصلاح: لا يحدث الاصطدام إلا إذا كانت العقبة في نفس "العمق" (Z)
      // هذا يمنع الموت إذا كنت تقفز فوق عقبة لا تزال بعيدة
      if (z > 0.15) return;

      // تحقق من نوع العائق وحالة اللاعب
      bool hit = true;
      if (type == ObstacleType.low && other.isJumping) {
        hit = false;
      } else if (type == ObstacleType.high && other.isSliding) {
        hit = false;
      }

      if (hit) {
        gameRef.onPlayerCollision();
        removeFromParent();
      }
    }
  }
}

// عملة بمنظور ثلاثي الأبعاد
class Coin extends PositionComponent
    with HasGameRef<SpectraSprintGame>, CollisionCallbacks {
  final int lane;
  double z = 1.0;
  bool collected = false;

  Coin(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(30, 30);

    add(
      CircleComponent(
        radius: 15,
        paint: Paint()..color = Color(GameConstants.colorYellow),
      ),
    );
    add(CircleHitbox());

    _updateTransform();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    z -= (gameRef.currentSpeed / 500.0) * dt;

    if (z <= 0) {
      removeFromParent();
      (parent as TrackManager).coins.remove(this);
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
            .clamp(0.1, 1.0);
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !collected) {
      collected = true;
      gameRef.onCoinCollected();
      removeFromParent();
    }
  }
}
