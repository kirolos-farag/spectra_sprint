import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'stage_config.dart';

class StageRegistry {
  static final List<StageTheme> stages = [
    // المرحلة 1: الفراغ الكلاسيكي (The Void)
    const StageTheme(
      name: 'THE VOID',
      warningMessage: 'INFINITE EMPTY',
      roadColor: Color(0xFF1A1A1A),
      skyColorTop: Color(0xFF1A0033),
      skyColorBottom: Color(0xFF0A001A),
      laneLineColor: Colors.white,
      allowedObstacles: [
        ObstacleType.low,
        ObstacleType.high,
        ObstacleType.barrier,
      ],
      voidColorStart: Color(0xFF1A0033),
      voidColorEnd: Color(0xFF000000),
      obstaclesPerRow: 1,
    ),

    // المرحلة 2: نيون سايبر (Cyber City)
    const StageTheme(
      name: 'CYBER CITY',
      warningMessage: 'SYSTEM CRITICAL!',
      roadColor: Color(0xFF001A33),
      skyColorTop: Color(0xFF00D9FF),
      skyColorBottom: Color(0xFF002244),
      laneLineColor: Color(0xFF00D9FF),
      allowedObstacles: [ObstacleType.low, ObstacleType.barrier],
      spawnRateMultiplier: 1.1,
      voidColorStart: Color(0xFF00D9FF),
      voidColorEnd: Color(0xFF001A33),
      obstaclesPerRow: 2,
    ),

    // المرحلة 3: الجحيم القرمزي (Crimson Peak)
    const StageTheme(
      name: 'CRIMSON PEAK',
      warningMessage: 'CRIMSON HEAT',
      roadColor: Color(0xFF330000),
      skyColorTop: Color(0xFFFF0054),
      skyColorBottom: Color(0xFF1A0000),
      laneLineColor: Color(0xFFFFEC00),
      allowedObstacles: [ObstacleType.high, ObstacleType.barrier],
      spawnRateMultiplier: 1.2,
      voidColorStart: Color(0xFFFF0054),
      voidColorEnd: Color(0xFF330000),
      obstaclesPerRow: 2,
    ),

    // المرحلة الجديدة: الواقع المحطم (Shattered Reality) - طريق متقطع
    const StageTheme(
      name: 'SHATTERED REALITY',
      warningMessage: 'AVOID THE WHITE GLITCH!',
      roadColor: Color(0xFF1A1A1A),
      skyColorTop: Color(0xFFB536FF),
      skyColorBottom: Color(0xFF1A1A1A),
      laneLineColor: Color(0xFFB536FF),
      allowedObstacles: [],
      spawnRateMultiplier: 1.0,
      obstaclesPerRow: 0,
      voidColorStart: Color(0xFF4A0033),
      voidColorEnd: Color(0xFF000000),
      isVanishingLane: true, // تفعيل الحارة البيضاء الخطيرة
      isFragmented: true, // الطريق متقطع أيضاً في هذه المرحلة
    ),

    // المرحلة 5: الهاوية الشيطانية (Infernal Abyss)
    const StageTheme(
      name: 'INFERNAL ABYSS',
      warningMessage: 'THE DEVIL AWAKES!',
      roadColor: Color(0xFF330000),
      skyColorTop: Color(0xFFFF0054),
      skyColorBottom: Color(0xFF1A0000),
      laneLineColor: Color(0xFFFFEC00),
      allowedObstacles: [],
      spawnRateMultiplier: 1.0,
      voidColorStart: Color(0xFFFF0054),
      voidColorEnd: Color(0xFF330000),
      obstaclesPerRow: 0,
      isBossStage: true,
    ),

    // المرحلة 6: الحدود الخضراء (Emerald Border)
    const StageTheme(
      name: 'GALACTIC BORDER',
      warningMessage: 'UFO SIGHTED!',
      roadColor: Color(0xFF001A00),
      skyColorTop: Color(0xFF00FF88),
      skyColorBottom: Color(0xFF000D00),
      laneLineColor: Color(0xFF00FF88),
      allowedObstacles: [],
      spawnRateMultiplier: 1.0,
      voidColorStart: Color(0xFF00FF88),
      voidColorEnd: Color(0xFF001A00),
      obstaclesPerRow: 0,
      isBossStage: true,
    ),

    // المرحلة 7: رمال الفراعنة (Pharaoh's Sands) - هرم ومومياوات
    const StageTheme(
      name: 'PHARAOH\'S SANDS',
      warningMessage: 'PYRAMID RISING!',
      roadColor: Color(0xFFC2B280), // Sand color
      skyColorTop: Color(0xFFFFD700), // Golden sky
      skyColorBottom: Color(0xFF8B4513), // Brown horizon
      laneLineColor: Color(0xFF00FFFF), // Cyan magical lines
      allowedObstacles: [],
      spawnRateMultiplier: 1.0,
      voidColorStart: Color(0xFFFFD700),
      voidColorEnd: Color(0xFF8B4513),
      obstaclesPerRow: 0,
      isBossStage: true,
      isVanishingLane: true, // تفعيل الحارة المتلاشية مع الوحش
      vanishingLaneColor: Colors.yellow, // لون الخطر أصفر كما طلب المستخدم
    ),
    // المرحلة 8: خليج القراصنة (Pirate's Cove)
    const StageTheme(
      name: 'PIRATE\'S COVE',
      warningMessage: 'PIRATE SHIP AHEAD!',
      roadColor: Color(0xFF004040), // Deep sea blue
      skyColorTop: Color(0xFFFF8C00), // Sunset orange
      skyColorBottom: Color(0xFF001F3F), // Dark midnight blue
      laneLineColor: Color(0xFF00FFFF), // Cyan water sparkle
      allowedObstacles: [ObstacleType.low], // بقايا سفن مكسورة
      spawnRateMultiplier: 1.2,
      voidColorStart: Color(0xFF003366),
      voidColorEnd: Color(0xFF001A33),
      obstaclesPerRow: 1,
      isBossStage: true,
    ),
    // المرحلة 9: حصن السماء (Sky Fortress)
    const StageTheme(
      name: 'SKY FORTRESS',
      warningMessage: 'AC-130 ABOVE!',
      roadColor: Color(0xFF2B2B2B), // Metallic grey
      skyColorTop: Color(0xFF000033), // Deep space
      skyColorBottom: Color(0xFF00FFFF), // Cyan horizon
      laneLineColor: Color(0xFF00D9FF),
      allowedObstacles: [ObstacleType.low], // عوائق صغيرة فقط للتمكن من الهرب
      spawnRateMultiplier: 1.3,
      voidColorStart: Color(0xFF000022),
      voidColorEnd: Color(0xFF001133),
      obstaclesPerRow: 1,
      isBossStage: true,
    ),
  ];

  static StageTheme getStage(int index) {
    return stages[index % stages.length];
  }
}
