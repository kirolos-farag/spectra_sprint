import 'package:flutter/material.dart';
import '../../game/spectra_sprint_game.dart';
import '../../data/game_data.dart';

// شاشة نهاية اللعبة
class GameOverOverlay extends StatefulWidget {
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
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  bool _isContinuing = false;

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = widget.game.isNewHighScore;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: Container(
                    width: 340,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0033),
                      borderRadius: BorderRadius.circular(25),
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
                            fontSize: 40,
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
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'رقم قياسي جديد!',
                                style: TextStyle(
                                  color: Color(0xFFFFEC00),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                color: Color(0xFFFFEC00),
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),

                        // --- خيارات المتابعة (Continue) ---
                        if (!_isContinuing) ...[
                          const Text(
                            'هل تريد المتابعة؟',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // استخدام قلب احتياطي
                              if (GameData().extraLives > 0)
                                Expanded(
                                  child: _buildContinueButton(
                                    'استخدم قلب (${GameData().extraLives})',
                                    const Color(0xFFFF0054),
                                    () {
                                      setState(() => _isContinuing = true);
                                      widget.game.continueGame();
                                    },
                                    Icons.favorite,
                                  ),
                                ),
                              if (GameData().extraLives > 0)
                                const SizedBox(width: 12),

                              // مشاهدة إعلان
                              Expanded(
                                child: _buildContinueButton(
                                  'إعلان مجاني',
                                  const Color(0xFF00FF88),
                                  () {
                                    setState(() => _isContinuing = true);
                                    widget.game.continueWithAd();
                                  },
                                  Icons.ondemand_video,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 24),
                        ],

                        // النتيجة
                        _buildStatRow(
                          'النقاط',
                          '${widget.game.score}',
                          const Color(0xFF00D9FF),
                          Icons.stars,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'المسافة',
                          '${widget.game.distance.toInt()} م',
                          const Color(0xFFB536FF),
                          Icons.straighten,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'العملات',
                          '${widget.game.coinsCollected}',
                          const Color(0xFFFFEC00),
                          Icons.monetization_on,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'أعلى نتيجة',
                          '${GameData().highScore}',
                          const Color(0xFFFF0054),
                          Icons.emoji_events,
                        ),
                        const SizedBox(height: 32),

                        // أزرار التحكم الأساسية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              'إعادة',
                              const Color(0xFF00D9FF),
                              widget.onRestart,
                              Icons.refresh,
                            ),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              'القائمة',
                              const Color(0xFFB536FF),
                              widget.onMainMenu,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(
    String text,
    Color color,
    VoidCallback onPressed,
    IconData icon,
  ) {
    return SizedBox(
      width: 140,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed,
    IconData icon,
  ) {
    return SizedBox(
      width: 120,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
