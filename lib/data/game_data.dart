import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// إدارة بيانات اللعبة والإعدادات
class GameData {
  static final GameData _instance = GameData._internal();
  factory GameData() => _instance;
  GameData._internal();

  late SharedPreferences _prefs;

  // مفاتيح التخزين
  static const String _keyHighScore = 'high_score';
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keySfxEnabled =
      'sfx_enabled_v3'; // تغيير المفتاح لفرض الإيقاف الافتراضي للجميع
  static const String _keyTotalGames = 'total_games';
  static const String _keyTotalDistance = 'total_distance';
  static const String _keyTotalCoins = 'total_coins';
  static const String _keyExtraLives = 'extra_lives';
  static const String _keyRandomMode = 'random_mode';

  // القيم الافتراضية
  int _highScore = 0;
  bool _musicEnabled = true;
  bool _sfxEnabled = false; // معطل افتراضياً بناءً على طلب المستخدم
  int _totalGames = 0;
  double _totalDistance = 0;
  int _totalCoins = 0;
  int _extraLives = 0;
  bool _randomMode = false;

  // Getters
  int get highScore => _highScore;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  int get totalGames => _totalGames;
  double get totalDistance => _totalDistance;
  int get totalCoins => _totalCoins;
  int get extraLives => _extraLives;
  bool get randomMode => _randomMode;

  // تهيئة البيانات
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  // تحميل البيانات
  void _loadData() {
    _highScore = _prefs.getInt(_keyHighScore) ?? 0;
    _musicEnabled = _prefs.getBool(_keyMusicEnabled) ?? true;
    _sfxEnabled = _prefs.getBool(_keySfxEnabled) ?? false;
    _totalGames = _prefs.getInt(_keyTotalGames) ?? 0;
    _totalDistance = _prefs.getDouble(_keyTotalDistance) ?? 0;
    _totalCoins = _prefs.getInt(_keyTotalCoins) ?? 0;
    _extraLives = _prefs.getInt(_keyExtraLives) ?? 0;
    _randomMode = _prefs.getBool(_keyRandomMode) ?? false;
  }

  // حفظ أعلى نتيجة
  Future<void> saveHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      await _prefs.setInt(_keyHighScore, _highScore);
    }
  }

  // تبديل الموسيقى
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _prefs.setBool(_keyMusicEnabled, _musicEnabled);
  }

  // تبديل المؤثرات الصوتية
  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
    await _prefs.setBool(_keySfxEnabled, _sfxEnabled);
  }

  // تبديل وضع اللعب العشوائي
  Future<void> toggleRandomMode() async {
    _randomMode = !_randomMode;
    await _prefs.setBool(_keyRandomMode, _randomMode);
  }

  // تحديث إحصائيات اللعبة
  Future<void> updateGameStats(double distance, int coins) async {
    _totalGames++;
    _totalDistance += distance;
    _totalCoins += coins;
    await _prefs.setInt(_keyTotalGames, _totalGames);
    await _prefs.setDouble(_keyTotalDistance, _totalDistance);
    await _prefs.setInt(_keyTotalCoins, _totalCoins);
  }

  // شراء قلب إضافي
  Future<bool> buyExtraLife() async {
    if (_totalCoins >= GameConstants.coinHeartCost) {
      _totalCoins -= GameConstants.coinHeartCost;
      _extraLives++;
      await _prefs.setInt(_keyTotalCoins, _totalCoins);
      await _prefs.setInt(_keyExtraLives, _extraLives);
      return true;
    }
    return false;
  }

  // إضافة قلب مجاني (عن طريق إعلان)
  Future<void> addFreeLife() async {
    _extraLives++;
    await _prefs.setInt(_keyExtraLives, _extraLives);
  }

  // استخدام قلب إضافي
  Future<void> useExtraLife() async {
    if (_extraLives > 0) {
      _extraLives--;
      await _prefs.setInt(_keyExtraLives, _extraLives);
    }
  }

  // إعادة تعيين جميع البيانات
  Future<void> resetAll() async {
    _highScore = 0;
    _totalGames = 0;
    _totalDistance = 0;
    _totalCoins = 0;
    _extraLives = 0;
    await _prefs.setInt(_keyHighScore, 0);
    await _prefs.setInt(_keyTotalGames, 0);
    await _prefs.setDouble(_keyTotalDistance, 0);
    await _prefs.setInt(_keyTotalCoins, 0);
    await _prefs.setInt(_keyExtraLives, 0);
  }

  // استهلاك كل القلوب الإضافية عند بدء اللعبة
  Future<void> consumeAllExtraLives() async {
    _extraLives = 0;
    await _prefs.setInt(_keyExtraLives, 0);
  }
}
