import 'package:flutter/material.dart';
import '../../utils/constants.dart';

// تعريف سمات المرحلة
class StageTheme {
  final String name;
  final String warningMessage; // رسالة تحذيرية مرعبة لليوزر
  final Color roadColor;
  final Color skyColorTop;
  final Color skyColorBottom;
  final Color laneLineColor;
  final List<ObstacleType> allowedObstacles;
  final double spawnRateMultiplier;
  final int obstaclesPerRow;
  final Color voidColorStart;
  final Color voidColorEnd;
  final bool isVanishingLane; // هل هناك حارة تختفي (تصبح بيضاء وخطيرة)؟
  final bool isFragmented; // هل الطريق متقطع (يظهر ويختفي)؟

  const StageTheme({
    required this.name,
    required this.warningMessage,
    required this.roadColor,
    required this.skyColorTop,
    required this.skyColorBottom,
    required this.laneLineColor,
    required this.allowedObstacles,
    this.spawnRateMultiplier = 1.0,
    this.obstaclesPerRow = 1,
    required this.voidColorStart,
    required this.voidColorEnd,
    this.isVanishingLane = false,
    this.isFragmented = false,
    this.isBossStage = false,
  });

  final bool isBossStage;
}
