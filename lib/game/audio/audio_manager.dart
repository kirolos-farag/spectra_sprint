import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import '../../data/game_data.dart';

// إدارة الصوتيات التفاعلية باستخدام FlameAudio
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // حالة الصوت
  bool _initialized = false;
  double _currentSpeed = 1.0;

  // نظام خنق الأصوات (Throttling) لمنع الضغط العالي
  final Map<String, int> _lastPlayTime = {};
  static const int _sfxCooldownMs = 50; // الحد الأدنى بين كل صوتين من نفس النوع

  // تهيئة نظام الصوت
  Future<void> init() async {
    if (_initialized) return;

    // تحميل المؤثرات الصوتية مسبقاً في الذاكرة لتجنب التأخير
    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/jump.wav',
        'sfx/collect.wav',
        'sfx/collision.wav',
        'sfx/color_change.wav',
      ]);
    } catch (e) {
      debugPrint('Error preloading SFX: $e');
    }

    _initialized = true;
  }

  // تشغيل الموسيقى الخلفية
  Future<void> playBackgroundMusic() async {
    if (!GameData().musicEnabled) return;

    try {
      // استخدام FlameAudio.bgm للبدء والتكرار تلقائياً
      if (!FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.play('music/background.mp3', volume: 0.4);
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  // إيقاف الموسيقى
  Future<void> stopMusic() async {
    if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.stop();
    }
  }

  // إيقاف مؤقت للموسيقى
  Future<void> pauseMusic() async {
    if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.pause();
    }
  }

  // استئناف الموسيقى
  Future<void> resumeMusic() async {
    if (!GameData().musicEnabled) return;
    await FlameAudio.bgm.resume();
  }

  // تغيير سرعة الموسيقى حسب سرعة اللعبة
  Future<void> updateMusicSpeed(double gameSpeed) async {
    // تحويل سرعة اللعبة إلى معدل تشغيل (1.0 - 1.5)
    final playbackRate = 1.0 + (gameSpeed * 0.5);

    if (playbackRate != _currentSpeed) {
      _currentSpeed = playbackRate;
      // FlameAudio.bgm.audioPlayer يتيح الوصول المباشر للمشغل الأساسي
      try {
        await FlameAudio.bgm.audioPlayer.setPlaybackRate(_currentSpeed);
      } catch (e) {
        debugPrint('Error updating music speed: $e');
      }
    }
  }

  // تشغيل مؤثر صوتي (يسمح بتعدد الأصوات المتزامنة)
  Future<void> playSfx(String sfxName, {String extension = 'wav'}) async {
    if (!GameData().sfxEnabled) return;

    // التحقق من نظام الخنق (Throttling)
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastPlayTime[sfxName] ?? 0;

    if (now - lastTime < _sfxCooldownMs) {
      return; // تجاهل الصوت إذا كان سريعاً جداً
    }
    _lastPlayTime[sfxName] = now;

    try {
      // FlameAudio.play يقوم بإنشاء مشغل جديد تلقائياً لكل صوت (Pooling)
      await FlameAudio.play('sfx/$sfxName.$extension');
    } catch (e) {
      debugPrint('Error playing SFX ($sfxName): $e');
    }
  }

  // مؤثرات صوتية محددة
  Future<void> playJumpSound() => playSfx('jump');
  Future<void> playCollectSound() => playSfx('collect');
  Future<void> playCollisionSound() => playSfx('collision');
  Future<void> playColorChangeSound() => playSfx('color_change');
  Future<void> playAbilityActivateSound() => playSfx('ability_activate');

  // أصوات المراحل الجديدة
  Future<void> playLaserSound() async {
    // الليزر يحتاج مهلة أطول (ثانيتين) لمنع التكرار المزعج
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastPlayTime['laser-beams'] ?? 0;
    if (now - lastTime < 2000) return;

    return playSfx('laser-beams', extension: 'mp3');
  }

  Future<void> playFireBreathSound() => playSfx('fire-breath');
  Future<void> playAliensSound() => playSfx('aliens');
  Future<void> playMummyZombieSound() => playSfx('mummy-zombie');

  // أصوات المرحلة الثامنة (Pirate's Cove)
  Future<void> playCannonSound() => playSfx('cannon-fire');

  // صوت بداية المشهد الجديد
  Future<void> playStageStartSound() =>
      playSfx('color_change', extension: 'mp3');

  // تنظيف الموارد
  void dispose() {
    FlameAudio.bgm.dispose();
  }
}
