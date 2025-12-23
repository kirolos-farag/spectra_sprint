// ثوابت اللعبة الأساسية
class GameConstants {
  GameConstants._();

  // إعدادات الشاشة (سيتم تحديثها ديناميكياً)
  static double vanishingPointYFactor =
      0.10; // رفع الأفق لتقليل "الشريط" العلوي

  // سرعة اللعبة
  static const double baseSpeed = 300.0;
  static const double maxSpeed = 600.0;
  static const double speedIncrement = 2.0; // زيادة السرعة تدريجياً

  // إعدادات اللاعب
  static const double playerWidth = 80.0;
  static const double playerHeight = 110.0;
  static const double jumpVelocity = -500.0;
  static const double gravity = 1200.0;
  static const double slideHeight = 40.0;

  // مسارات الجري (lanes)
  static const int numberOfLanes = 3;

  // إعدادات المسار
  static const double segmentHeight = 200.0;
  static const int initialSegments = 5;

  // إعدادات النقاط والعملات
  static const int pointsPerSecond = 10;
  static const int coinValue = 1; // تقليل قيمة العملة الواحدة للواقعية
  static const int comboMultiplier = 2;
  static const int coinHeartCost = 100; // تكلفة شراء قلب إضافي

  // إعدادات الصحة
  static const int maxLives = 3;

  // إعدادات القدرات
  static const double abilityDuration = 5.0; // بالثواني
  static const double abilityCooldown = 10.0; // بالثواني

  // إعدادات المنظور (Pseudo-3D)
  static const double minScale = 0.3;
  static const double maxScale = 1.0;
  static const double trackHorizonWidthFactor = 0.2; // نسبة من عرض الشاشة

  // إعدادات السحب (Swipe)
  static const double swipeThreshold = 20.0;

  // ألوان اللعبة
  static const int colorRed = 0xFFFF0054;
  static const int colorBlue = 0xFF00D9FF;
  static const int colorYellow = 0xFFFFEC00;
  static const int colorPurple = 0xFFB536FF;
  static const int colorShadow = 0xFFFF00FF; // فوشيا نيون ليكون واضحاً جداً
  static const int colorLight = 0xFFFFFBE6;
  static const int colorRoad = 0xFF1A1033; // لون طريق أفتح قليلاً للوضوح

  // ميزة المطور: ابدأ من مرحلة معينة (0 = البداية)
  static const int debugStartStage = 0;
}

// أنواع الألوان/القدرات
enum PlayerColor {
  red, // سرعة مضاعفة
  blue, // قفزة مضاعفة
  yellow, // مغناطيس للعملات
  purple, // بطء الوقت
}

// حالة اللعبة
enum GameState {
  mainMenu,
  playing,
  paused,
  gameOverSequence,
  gameOver,
  victory,
}

// أنواع العوائق
enum ObstacleType {
  low, // يمكن القفز فوقه
  high, // يمكن الانزلاق تحته
  barrier, // يجب تجنبه تماماً
}
