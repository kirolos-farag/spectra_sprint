import 'package:flutter/material.dart';
import '../../game/spectra_sprint_game.dart';
import '../../data/game_data.dart';

// شاشة نهاية اللعبة
class GameOverOverlay extends StatelessWidget {
  final SpectraSprintGame game;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.isNewHighScore;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 32,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0033),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNewHighScore
                            ? const Color(0xFFFFEC00)
                            : const Color(0xFFFF0054),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isNewHighScore
                                      ? const Color(0xFFFFEC00)
                                      : const Color(0xFFFF0054))
                                  .withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // عنوان
                        Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: isNewHighScore
                                ? const Color(0xFFFFEC00)
                                : const Color(0xFFFF0054),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        if (isNewHighScore) ...[
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFFFFEC00),
                                size: 32,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'رقم قياسي جديد!',
                                style: TextStyle(
                                  color: Color(0xFFFFEC00),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                color: Color(0xFFFFEC00),
                                size: 32,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 40),
                        // النتيجة
                        _buildStatRow(
                          'النقاط',
                          '${game.score}',
                          const Color(0xFF00D9FF),
                          Icons.stars,
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow(
                          'المسافة',
                          '${game.distance.toInt()} م',
                          const Color(0xFFB536FF),
                          Icons.straighten,
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow(
                          'العملات',
                          '${game.coinsCollected}',
                          const Color(0xFFFFEC00),
                          Icons.monetization_on,
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow(
                          'أعلى نتيجة',
                          '${GameData().highScore}',
                          const Color(0xFFFF0054),
                          Icons.emoji_events,
                        ),
                        const SizedBox(height: 40),
                        // أزرار
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildButton(
                              'إعادة',
                              const Color(0xFF00D9FF),
                              onRestart,
                              Icons.refresh,
                            ),
                            const SizedBox(width: 16),
                            _buildButton(
                              'القائمة',
                              const Color(0xFFB536FF),
                              onMainMenu,
                              Icons.home,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color color,
    VoidCallback onPressed,
    IconData icon,
  ) {
    return SizedBox(
      width: 130,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
