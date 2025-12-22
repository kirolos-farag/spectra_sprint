import 'package:audioplayers/audioplayers.dart';
import '../../data/game_data.dart';

// إدارة الصوتيات التفاعلية
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // مشغلات الصوت
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // حالة الصوت
  bool _initialized = false;
  double _currentSpeed = 1.0;

  // تهيئة نظام الصوت
  Future<void> init() async {
    if (_initialized) return;

    // إعداد مشغل الموسيقى للتكرار
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    _initialized = true;
  }

  // تشغيل الموسيقى الخلفية
  Future<void> playBackgroundMusic() async {
    if (!GameData().musicEnabled) return;

    try {
      // تم إلغاء التعليق لتشغيل الموسيقى
      await _musicPlayer.play(AssetSource('audio/music/background.mp3'));
      await _musicPlayer.setVolume(0.4);
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  // إيقاف الموسيقى
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  // إيقاف مؤقت للموسيقى
  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  // استئناف الموسيقى
  Future<void> resumeMusic() async {
    if (!GameData().musicEnabled) return;
    await _musicPlayer.resume();
  }

  // تغيير سرعة الموسيقى حسب سرعة اللعبة
  Future<void> updateMusicSpeed(double gameSpeed) async {
    // تحويل سرعة اللعبة إلى معدل تشغيل (1.0 - 1.5)
    final playbackRate = 1.0 + (gameSpeed * 0.5);

    if (playbackRate != _currentSpeed) {
      _currentSpeed = playbackRate;
      await _musicPlayer.setPlaybackRate(_currentSpeed);
    }
  }

  // تشغيل مؤثر صوتي
  Future<void> playSfx(String sfxName) async {
    if (!GameData().sfxEnabled) return;

    try {
      // سيتم استبدال هذا بملفات صوتية حقيقية لاحقاً
      // await _sfxPlayer.play(AssetSource('audio/sfx/$sfxName.wav'));
    } catch (e) {
      print('Error playing SFX: $e');
    }
  }

  // مؤثرات صوتية محددة
  Future<void> playJumpSound() => playSfx('jump');
  Future<void> playCollectSound() => playSfx('collect');
  Future<void> playCollisionSound() => playSfx('collision');
  Future<void> playColorChangeSound() => playSfx('color_change');
  Future<void> playAbilityActivateSound() => playSfx('ability_activate');

  // تنظيف الموارد
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
