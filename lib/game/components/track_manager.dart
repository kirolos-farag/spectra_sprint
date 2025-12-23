import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import '../spectra_sprint_game.dart';
import 'player.dart';
import 'package:spectra_sprint/game/stages/stage_config.dart';

// مدير المسار - توليد العوائق والعملات بمنظور ثلاثي الأبعاد
class TrackManager extends Component with HasGameRef<SpectraSprintGame> {
  // قائمة العوائق والعملات
  final List<TrackObstacle> obstacles = [];
  final List<Coin> coins = [];
  final List<Platform> platforms = [];

  // تتبع المسافة لظهور الأشياء (بالنسبة لـ Z)
  double nextObstacleZ = 0.5;
  double nextCoinZ = 0.3;
  double nextPlatformZ = 0.0;

  final Random random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateInitialTrack();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || gameRef.isVictorySequence)
      return;

    final speed = gameRef.currentSpeed / 500.0; // تحويل السرعة لمعدل Z

    // توليد عوائق جديدة - مع مراعاة مضاعف المرحلة
    final theme = gameRef.background.currentTheme;
    nextObstacleZ -= speed * dt * theme.spawnRateMultiplier;
    if (nextObstacleZ <= 0) {
      _generateObstacle(theme);
      nextObstacleZ = 0.5 + random.nextDouble() * 0.5;
    }

    // توليد عملات جديدة (تقليل التكرار)
    nextCoinZ -= speed * dt;
    if (nextCoinZ <= 0) {
      _generateCoin();
      nextCoinZ = 0.4 + random.nextDouble() * 0.5;
    }

    // (تم تعطيل المنصات الفيزيائية بطلب من المستخدم واستبدالها بالحارة البيضاء الخطيرة)
  }

  void _generateInitialTrack() {
    nextObstacleZ = 0.0; // توليد فوري عند البداية
    nextCoinZ = 0.5;
    nextPlatformZ = 0.0; // توليد فوري للمنصات
  }

  void _generateObstacle(StageTheme theme) {
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

    if (availableLanes.isEmpty) return;

    // خلط الحارات المتاحة واختيار عدد العوائق المطلوب لهذه المرحلة
    availableLanes.shuffle(random);

    // التأكد من عدم إغلاق كل الحارات (نترك حارة واحدة على الأقل)
    int count = theme.obstaclesPerRow;
    if (count >= GameConstants.numberOfLanes) {
      count = GameConstants.numberOfLanes - 1;
    }

    final lanesToSpawn = availableLanes.take(count).toList();
    final allowedTypes = theme.allowedObstacles;
    if (allowedTypes.isEmpty) return;

    for (var lane in lanesToSpawn) {
      final type = allowedTypes[random.nextInt(allowedTypes.length)];
      final obstacle = TrackObstacle(lane, type);
      add(obstacle);
      obstacles.add(obstacle);
    }
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

  void _generatePlatform() {
    // منطق "2 حارات موجودة و1 مخفية":
    // نختار حارة واحدة لتكون "المخفية" (الفراغ)
    final hiddenLane = random.nextInt(3);

    for (int i = 0; i < 3; i++) {
      if (i != hiddenLane) {
        final platform = Platform(i);
        add(platform);
        platforms.add(platform);
      }
    }
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

    for (var platform in platforms) {
      platform.removeFromParent();
    }
    platforms.clear();

    _generateInitialTrack();
  }

  // التحقق مما إذا كان اللاعب يقف على منصة
  bool isPlayerOnPlatform(int playerLane) {
    // نبحث عن أي منصة قريبة جداً من اللاعب (z < 0.1) وفي نفس الحارة
    return platforms.any(
      (p) => p.lane == playerLane && p.z < 0.15 && p.z > -0.05,
    );
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
    final height = type == ObstacleType.high ? 160.0 : 40.0;
    size = Vector2(width, height);

    // للمنخفضة فقط نترك مساحة بسيطة للتسهيل، العالية يجب أن تكون مستحيلة القفز
    final hitboxHeight = type == ObstacleType.high ? size.y : size.y * 0.8;
    final hitboxY = type == ObstacleType.high ? 0.0 : size.y * 0.2;

    add(
      RectangleHitbox(
        size: Vector2(size.x, hitboxHeight),
        position: Vector2(0, hitboxY),
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

    // توهج بلون المرحلة (Shadow Aura) في الأسفل
    final theme = gameRef.background.currentTheme;

    // إذا كانت المرحلة هي خليج القراصنة، نرسم "حطام سفن" بدلاً من العقبات العادية
    if (theme.name == 'PIRATE\'S COVE') {
      _renderPirateDebris(canvas, rrect);
      return;
    }

    final auraPaint = Paint()
      ..color = theme.laneLineColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, auraPaint);
  }

  void _renderPirateDebris(Canvas canvas, RRect rrect) {
    final woodPaint = Paint()..color = const Color(0xFF5D4037); // Brown wood
    final lightWoodPaint = Paint()..color = const Color(0xFF795548);

    // Draw main plank
    canvas.drawRRect(rrect, woodPaint);

    // Draw some wooden grain/lines
    final grainPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.y * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grainPaint);
    }

    // Draw some "shattered" edges or extra planks
    final extraPlankRect = Rect.fromLTWH(
      size.x * 0.1,
      -5,
      size.x * 0.3,
      size.y * 0.5,
    );
    canvas.drawRect(extraPlankRect, lightWoodPaint);
    canvas.drawRect(extraPlankRect, grainPaint);

    // Draw some rope or metal bands
    final metalPaint = Paint()..color = Colors.grey;
    canvas.drawRect(Rect.fromLTWH(size.x * 0.2, 0, 5, size.y), metalPaint);
    canvas.drawRect(Rect.fromLTWH(size.x * 0.7, 0, 5, size.y), metalPaint);
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
    add(CircleHitbox());
    _updateTransform();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // رسم الدائرة الصفراء الأساسية
    final paint = Paint()..color = Color(GameConstants.colorYellow);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    // رسم النجمة السوداء في المنتصف
    final starPaint = Paint()..color = Colors.black;
    final path = Path();
    final double centerX = size.x / 2;
    final double centerY = size.y / 2;
    final double radius = size.x * 0.35;
    final double innerRadius = radius * 0.4;

    for (int i = 0; i < 10; i++) {
      final double angle = i * pi / 5 - pi / 2;
      final double r = (i % 2 == 0) ? radius : innerRadius;
      final double x = centerX + r * cos(angle);
      final double y = centerY + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);
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

// منصة في الطريق المتقطع
class Platform extends PositionComponent with HasGameRef<SpectraSprintGame> {
  final int lane;
  double z = 1.0;

  Platform(this.lane);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final trackBottomWidth = gameRef.size.x;
    final width = (trackBottomWidth / GameConstants.numberOfLanes) * 0.95;
    size = Vector2(width, 300); // زيادة طول المنصة لتشكل طريقاً مستمراً

    _updateTransform();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final theme = gameRef.background.currentTheme;

    // رسم سطح المنصة
    final platformPaint = Paint()..color = theme.roadColor;
    final rect = size.toRect();
    canvas.drawRect(rect, platformPaint);

    // رسم تأثير نيون حول المنصة
    final auraPaint = Paint()
      ..color = theme.laneLineColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(rect, auraPaint);

    // رسم حواف المنصة باللون الأبيض للوضوح
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState != GameState.playing) return;

    z -= (gameRef.currentSpeed / 500.0) * dt;

    if (z <= -0.2) {
      // تختفي المنصة بعد تجاوز اللاعب بفارق بسيط
      removeFromParent();
      (parent as TrackManager).platforms.remove(this);
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
    scale = Vector2(currentScale, currentScale);

    final trackHorizonWidth =
        gameRef.size.x * GameConstants.trackHorizonWidthFactor;
    final trackBottomWidth = gameRef.size.x;
    final currentTrackWidth =
        trackHorizonWidth + t * (trackBottomWidth - trackHorizonWidth);

    final laneWidth = currentTrackWidth / 3;
    final laneOffset = (lane - 1) * laneWidth;
    final centerX = gameRef.size.x / 2 + laneOffset;

    position = Vector2(centerX - (size.x * currentScale) / 2, y);
  }
}
