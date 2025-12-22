import 'package:flutter/material.dart';
import '../../game/spectra_sprint_game.dart';
import '../../utils/constants.dart';
import '../../data/game_data.dart';

// واجهة اللعبة (HUD)
class GameHUD extends StatelessWidget {
  final SpectraSprintGame game;
  final VoidCallback onPause;

  const GameHUD({super.key, required this.game, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // المسافة في أعلى اليسار
        Positioned(
          top: 10,
          left: 10,
          child: _buildMetric(
            '${game.distance.toInt()} m',
            Icons.straighten,
            const Color(0xFF00D9FF),
          ),
        ),

        // العملات (التي يجمعها اللاعب) في المنتصف مع زر إضافة
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMetric(
                  '${game.coinsCollected}',
                  Icons.stars,
                  const Color(0xFFFFEC00),
                  large: true,
                ),
                const SizedBox(width: 8),
                // زر شراء سريع
                _buildCircularButton(
                  Icons.add,
                  const Color(0xFFFFEC00),
                  () async {
                    final success = await game.buyHeart();
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لا تملك عملات كافية! ⭐'),
                          backgroundColor: Color(0xFFFF0054),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // القلوب في أعلى اليمين (تحت زر الإيقاف والقلوب الأساسية)
        Positioned(
          top: 45,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // القلوب الأساسية
              Row(
                children: List.generate(GameConstants.maxLives, (index) {
                  final isFull = index < game.lives;
                  return Icon(
                    isFull ? Icons.favorite : Icons.favorite_border,
                    color: isFull ? const Color(0xFFFF0054) : Colors.white30,
                    size: 24,
                  );
                }),
              ),
              const SizedBox(height: 8),
              // القلوب الاحتياطية (مشتراة)
              if (GameData().extraLives > 0)
                GestureDetector(
                  onTap: () => game.useReserveHeart(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0054).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFF0054).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF0054),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'x${GameData().extraLives}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // زر الإيقاف في أعلى اليمين
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            onPressed: onPause,
            icon: const Icon(
              Icons.pause_circle_outline,
              color: Colors.white70,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    String value,
    IconData icon,
    Color color, {
    bool large = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 20 : 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: large ? 20 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // تم حذف الطرق غير المستخدمة (النقاط والمؤشرات) بناءً على طلب المستخدم
}
