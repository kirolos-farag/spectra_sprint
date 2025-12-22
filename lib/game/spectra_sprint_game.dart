import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:ui';
import 'dart:math';
import '../utils/constants.dart';
import 'components/player.dart';
import 'components/track_manager.dart';
import 'components/dynamic_background.dart';
import 'audio/audio_manager.dart';
import '../data/game_data.dart';

// اللعبة الرئيسية
class SpectraSprintGame extends FlameGame
    with DragCallbacks, HasCollisionDetection {
  // حالة اللعبة
  GameState gameState = GameState.playing;

  // المكونات الرئيسية
  late Player player;
  late TrackManager trackManager;
  late DynamicBackground background;

  // إحصائيات اللعبة
  double _scoreAccumulator = 0;
  int score = 0;
  double distance = 0;
  double currentSpeed = GameConstants.baseSpeed;
  int coinsCollected = 0;
  int combo = 0;
  int lives = GameConstants.maxLives;
  bool isNewHighScore = false;

  // الوقت والكاميرا
  double elapsedTime = 0;
  double _shakeTimer = 0;
  final Random _random = Random();
  bool _hasSwiped = false; // قفل لمنع أكثر من حركة في لمسة واحدة
  Vector2 _swipeDelta = Vector2.zero();

  // متغيرات السحب (Swipe)

  // callbacks للواجهة
  Function(int)? onScoreChanged;
  Function(double)? onDistanceChanged;
  Function(GameState)? onGameStateChanged;
  Function(int)? onLivesChanged;
  Function()? onGameOver;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // إعداد الكاميرا لتكون متوافقة مع إحداثيات الشاشة (Top-Left)
    camera.viewfinder.anchor = Anchor.topLeft;

    // إضافة نظام الجزيئات (Particles) إلى العالم
    world.add(ParticleSystemComponent());

    // إضافة الخلفية إلى العالم
    background = DynamicBackground();
    world.add(background);

    // إضافة مدير المسار إلى العالم
    trackManager = TrackManager();
    world.add(trackManager);

    // إضافة اللاعب إلى العالم
    player = Player();
    world.add(player);

    // تهيئة وتشغيل الموسيقى
    await AudioManager().init();
    await AudioManager().playBackgroundMusic();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // تحديث الوقت
    elapsedTime += dt;

    // تحديث المسافة
    distance += currentSpeed * dt;
    onDistanceChanged?.call(distance);

    // تحديث النقاط - استخدام مجمع لتجنب فقدان النقاط بسبب تقريب الوقت
    _scoreAccumulator += GameConstants.pointsPerSecond * dt;
    if (_scoreAccumulator >= 1.0) {
      final pointsToAdd = _scoreAccumulator.toInt();
      score += pointsToAdd;
      _scoreAccumulator -= pointsToAdd;

      // تحقق من الرقم القياسي أثناء اللعب
      if (score > GameData().highScore) {
        isNewHighScore = true;
      }

      onScoreChanged?.call(score);
    }

    // زيادة السرعة تدريجياً
    if (currentSpeed < GameConstants.maxSpeed) {
      currentSpeed += GameConstants.speedIncrement * dt;

      // تحديث سرعة الموسيقى
      final speedRatio =
          (currentSpeed - GameConstants.baseSpeed) /
          (GameConstants.maxSpeed - GameConstants.baseSpeed);
      AudioManager().updateMusicSpeed(speedRatio);
    }

    // تحديث الخلفية حسب السرعة
    background.updateSpeed(currentSpeed);

    // تحديث اهتزاز الشاشة (أفقي فقط - هزة خفيفة)
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final jolt =
          (_random.nextDouble() * 2 - 1) * 15; // تقليل القوة لـ 15 بكسل فقط
      camera.viewfinder.position = Vector2(jolt, 0);
    } else {
      camera.viewfinder.position = Vector2.zero();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _swipeDelta = Vector2.zero();
    _hasSwiped = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (gameState != GameState.playing || _hasSwiped) return;

    _swipeDelta += event.localDelta;

    if (_swipeDelta.length > 40.0) {
      if (_swipeDelta.y.abs() > _swipeDelta.x.abs()) {
        // سحب رأسي
        if (_swipeDelta.y < -40.0) {
          player.jump();
          _hasSwiped = true;
          _swipeDelta = Vector2.zero();
        } else if (_swipeDelta.y > 40.0) {
          player.slide();
          _hasSwiped = true;
          _swipeDelta = Vector2.zero();
        }
      } else {
        // سحب أفقي
        if (_swipeDelta.x > 40.0) {
          player.moveRight();
          _hasSwiped = true;
          _swipeDelta = Vector2.zero();
        } else if (_swipeDelta.x < -40.0) {
          player.moveLeft();
          _hasSwiped = true;
          _swipeDelta = Vector2.zero();
        }
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _swipeDelta = Vector2.zero();
    _hasSwiped = false;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _swipeDelta = Vector2.zero();
    _hasSwiped = false;
  }

  // التعامل مع تجميع العملات
  void onCoinCollected() {
    coinsCollected++;
    score += GameConstants.coinValue;
    combo++;

    // نقاط إضافية للكومبو
    if (combo > 3) {
      score += GameConstants.coinValue * GameConstants.comboMultiplier;
    }

    AudioManager().playCollectSound();
    onScoreChanged?.call(score);
  }

  // استخدام قلب من الرصيد
  void useReserveHeart() {
    if (lives < GameConstants.maxLives && GameData().extraLives > 0) {
      GameData().useExtraLife();
      lives++;
      onLivesChanged?.call(lives);
      AudioManager().playCollectSound(); // صوت كـ تغذية راجعة
    }
  }

  // شراء قلب أثناء اللعب
  Future<bool> buyHeart({bool isAd = false}) async {
    bool success = false;
    if (isAd) {
      // محاكاة إعلان
      success = true; // نفترض النجاح دائماً في المحاكاة
    } else {
      // شراء بالعملات (نفس العملات التي يجمعها الآن أو الرصيد الدائم)
      if (GameData().totalCoins >= GameConstants.coinHeartCost) {
        success = await GameData().buyExtraLife();
      }
    }

    if (success) {
      AudioManager().playCollectSound();
      onLivesChanged?.call(lives); // لتحديث الواجهة بالرصيد الجديد
    }
    return success;
  }

  // التعامل مع الإصطدام
  void onPlayerCollision() {
    if (gameState != GameState.playing) return;

    lives--;
    onLivesChanged?.call(lives);
    combo = 0; // إعادة تعيين الكومبو

    // اهتزاز الشاشة (بشكل أقوى)
    _shakeTimer = 0.5;

    // إنشاء انفجار جزيئات صغير
    createExplosion(player.position + player.size / 2);

    if (lives <= 0) {
      // بدء تسلسل النهاية (3 ثواني)
      gameState = GameState.gameOverSequence;
      onGameStateChanged?.call(GameState.gameOverSequence);

      // توقف الحركة تماماً
      currentSpeed = 0;
      background.updateSpeed(0);

      // تأخير الانتقال لصفحة النتائج
      Future.delayed(const Duration(seconds: 3), () {
        if (gameState == GameState.gameOverSequence) {
          gameOver();
        }
      });
    } else {
      // وميض للاعب (فترة حماية قصيرة)
      player.opacity = 0.5;
      Future.delayed(const Duration(milliseconds: 500), () {
        player.opacity = 1.0;
      });
    }
  }

  void createExplosion(Vector2 position) {
    final random = Random();
    world.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 20,
          lifespan: 0.8,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 200),
            speed: Vector2(
              (random.nextDouble() - 0.5) * 400,
              (random.nextDouble() - 0.5) * 400,
            ),
            position: position.clone(),
            child: CircleParticle(
              radius: 2 + random.nextDouble() * 3,
              paint: Paint()..color = Color(GameConstants.colorShadow),
            ),
          ),
        ),
      ),
    );
  }

  // نهاية اللعبة
  void gameOver() {
    gameState = GameState.gameOver;
    onGameStateChanged?.call(GameState.gameOver);

    // حفظ البيانات
    if (score > GameData().highScore) {
      isNewHighScore = true;
      GameData().saveHighScore(score);
    }
    GameData().updateGameStats(distance, coinsCollected);

    // إيقاف الموسيقى
    AudioManager().stopMusic();

    // تنبيه الواجهة
    onGameOver?.call();
  }

  // إيقاف مؤقت
  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      pauseEngine();
      AudioManager().pauseMusic();
      onGameStateChanged?.call(GameState.paused);
    }
  }

  // استئناف اللعبة
  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      resumeEngine();
      AudioManager().resumeMusic();
      onGameStateChanged?.call(GameState.playing);
    }
  }

  // إعادة بدء اللعبة
  void restartGame() {
    // إعادة تعيين الإحصائيات
    score = 0;
    distance = 0;
    currentSpeed = GameConstants.baseSpeed;
    coinsCollected = 0;
    combo = 0;
    lives = GameConstants.maxLives;
    elapsedTime = 0;
    _scoreAccumulator = 0;
    isNewHighScore = false;

    // إعادة تعيين المكونات
    player.reset();
    trackManager.reset();

    // لم نعد نستهلك الأرواح تلقائياً، اللاعب يقرر متى يستخدمها
    lives = GameConstants.maxLives;

    // تغيير الحالة
    gameState = GameState.playing;
    resumeEngine();

    // إعادة تشغيل الموسيقى
    AudioManager().playBackgroundMusic();

    onGameStateChanged?.call(GameState.playing);
    onScoreChanged?.call(0);
  }
}
