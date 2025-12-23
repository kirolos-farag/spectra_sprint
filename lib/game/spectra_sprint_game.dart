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
import 'package:spectra_sprint/game/stages/stage_registry.dart';
import 'package:spectra_sprint/game/components/biome_warning.dart';
import 'package:spectra_sprint/game/components/boss_devil.dart';
import 'package:spectra_sprint/game/components/ufo_boss.dart';

// اللعبة الرئيسية
class SpectraSprintGame extends FlameGame
    with DragCallbacks, HasCollisionDetection {
  // حالة اللعبة
  GameState gameState = GameState.playing;

  // المكونات الرئيسية
  late Player player;
  late TrackManager trackManager;
  late DynamicBackground background;
  PositionComponent? currentBoss;

  // إحصائيات اللعبة
  double _scoreAccumulator = 0;
  int score = 0;
  double distance = 0;
  double currentSpeed = GameConstants.baseSpeed;
  int coinsCollected = 0;
  int combo = 0;
  int lives = GameConstants.maxLives;
  bool isNewHighScore = false;
  bool isInvulnerable = false; // حماية مؤقتة عند العودة

  // خاص بالمرحلة الرابعة (Vanishing Lane)
  int vanishingLaneIndex = -1;
  int warningLaneIndex = -1;
  double _vanishingTimer = 0;
  bool _isWarningPhase = true;

  // الوقت والكاميرا
  double elapsedTime = 0;
  double _shakeTimer = 0;
  final Random _random = Random();
  bool _hasSwiped = false; // قفل لمنع أكثر من حركة في لمسة واحدة
  Vector2 _swipeDelta = Vector2.zero();

  // إدارة المراحل
  int currentStageIndex = 0;
  double _lastStageTime = 0;
  final double secondsPerStage = 30.0;

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

    // تعيين المرحلة الأولى
    _updateStage();
  }

  void _updateStage() {
    final theme = StageRegistry.getStage(currentStageIndex);
    background.setStage(theme);

    // إظهار الرسالة التحذيرية "المرعبة" أثناء تغيير المرحلة
    // نستخدم الكاميرا (camera.viewport) لضمان بقاء الرسالة فوق كل شيء في الشاشة
    camera.viewport.add(
      BiomeWarning(message: theme.warningMessage, color: theme.laneLineColor)
        ..priority = 1000,
    );

    // إدارة الزعيم (Boss)
    if (theme.isBossStage) {
      // تحقق مما إذا كان الوحش الحالي هو النوع الخطأ لهذه المرحلة
      bool wrongBoss =
          (theme.name == 'INFERNAL ABYSS' && currentBoss is! BossDevil) ||
          (theme.name == 'GALACTIC BORDER' && currentBoss is! UfoBoss);

      if (wrongBoss && currentBoss != null) {
        currentBoss!.removeFromParent();
        currentBoss = null;
      }

      if (currentBoss == null) {
        if (theme.name == 'INFERNAL ABYSS') {
          currentBoss = BossDevil();
        } else if (theme.name == 'GALACTIC BORDER') {
          currentBoss = UfoBoss();
        }

        if (currentBoss != null) {
          world.add(currentBoss!);
        }
      }
    } else {
      if (currentBoss != null) {
        currentBoss!.removeFromParent();
        currentBoss = null;
      }
    }
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

    // التحقق من الانتقال للمرحلة التالية - كل 30 ثانية
    if (elapsedTime - _lastStageTime >= secondsPerStage) {
      currentStageIndex++;
      _lastStageTime = elapsedTime;
      _updateStage();
    }

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

    // التحقق من الحارة الخطيرة (المرحلة الرابعة)
    if (background.currentTheme.isVanishingLane &&
        background.safeStageTimer <= 0) {
      _vanishingTimer -= dt;
      if (_vanishingTimer <= 0) {
        if (_isWarningPhase) {
          // الانتقال من التحذير إلى الخطر
          _isWarningPhase = false;
          vanishingLaneIndex = warningLaneIndex;
          _vanishingTimer = 2.0;
        } else {
          // الانتقال من الخطر إلى تحذير جديد
          _isWarningPhase = true;
          vanishingLaneIndex = -1;
          warningLaneIndex = _random.nextInt(3);
          _vanishingTimer = 2.0;
        }
      }

      // إذا كان اللاعب في الحارة الخطيرة وليس في قفزة
      if (vanishingLaneIndex != -1 &&
          player.currentLane == vanishingLaneIndex &&
          !player.isJumping &&
          !isInvulnerable) {
        onPlayerCollision();
      }
    } else {
      vanishingLaneIndex = -1;
      warningLaneIndex = -1;
      _isWarningPhase = true;
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

  // التعامل مع السقوط في الفراغ
  void onPlayerFall() {
    if (gameState != GameState.playing) return;

    lives--;
    onLivesChanged?.call(lives);
    AudioManager().playCollisionSound(); // يمكن إضافة صوت سقوط لاحقاً

    if (lives <= 0) {
      gameOver();
    } else {
      respawnAtStage();
    }
  }

  // إعادة المحاولة من بداية المرحلة الحالية
  void respawnAtStage() {
    gameState = GameState.paused;
    pauseEngine();

    // إعادة تعيين وقت المرحلة الحالية لتبدأ من جديد
    elapsedTime = _lastStageTime;

    // تنظيف العوائق والمنصات
    trackManager.reset();
    player.reset(); // يعيده للمنتصف والحالة الطبيعية

    // إعادة السرعة لوضعها الطبيعي (مهم جداً لأنها قد تكون صفراً عند الموت)
    currentSpeed = GameConstants.baseSpeed;
    _shakeTimer = 0;

    // استئناف بعد ثانية (تأخير بسيط للراحة)
    Future.delayed(const Duration(seconds: 1), () {
      gameState = GameState.playing;
      resumeEngine();
      _updateStage();

      // تفعيل الحماية
      isInvulnerable = true;
      player.opacity = 0.5;
      Future.delayed(const Duration(seconds: 2), () {
        isInvulnerable = false;
        player.opacity = 1.0;
      });
    });
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
    if (gameState != GameState.playing || isInvulnerable) return;

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
    // إعادة تعيين الإحصائيات والمراحل
    score = 0;
    distance = 0;
    currentSpeed = GameConstants.baseSpeed;
    coinsCollected = 0;
    combo = 0;
    lives = GameConstants.maxLives;
    elapsedTime = 0;
    _scoreAccumulator = 0;
    isNewHighScore = false;
    isInvulnerable = false; // حماية مؤقتة عند العودة
    currentStageIndex = 0;
    _lastStageTime = 0;

    // إعادة تعيين المكونات
    player.reset();
    trackManager.reset();
    _updateStage(); // إرجاع المشهد للمرحلة الأولى

    // تغيير الحالة
    gameState = GameState.playing;
    resumeEngine();

    // إعادة تشغيل الموسيقى
    AudioManager().playBackgroundMusic();

    onGameStateChanged?.call(GameState.playing);
    onScoreChanged?.call(0);
  }

  // المتابعة بعد الموت (Continue)
  void continueGame() {
    if (GameData().extraLives > 0) {
      GameData().useExtraLife();
      lives = 1;
      onLivesChanged?.call(lives);

      overlays.remove('GameOver');
      gameState = GameState.playing;
      resumeEngine();
      AudioManager().playBackgroundMusic();

      onGameStateChanged?.call(GameState.playing);
      respawnAtStage();
    }
  }

  // المتابعة بمشاهدة إعلان
  void continueWithAd() {
    lives = 1;
    onLivesChanged?.call(lives);

    overlays.remove('GameOver');
    gameState = GameState.playing;
    resumeEngine();
    AudioManager().playBackgroundMusic();

    onGameStateChanged?.call(GameState.playing);
    respawnAtStage();
  }
}
