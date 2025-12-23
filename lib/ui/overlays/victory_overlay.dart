import 'package:flutter/material.dart';
import '../../game/spectra_sprint_game.dart';

class VictoryOverlay extends StatelessWidget {
  final SpectraSprintGame game;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const VictoryOverlay({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0033),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFFEC00), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFEC00).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFEC00),
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'VICTORY!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'لقد أكملت جميع المراحل!',
                style: TextStyle(color: Color(0xFF00D9FF), fontSize: 18),
              ),
              const SizedBox(height: 32),
              _buildStatRow('النقاط', '${game.score.toInt()}'),
              _buildStatRow('المسافة', '${game.distance.toInt()}m'),
              _buildStatRow('العملات', '${game.coinsCollected}'),
              const SizedBox(height: 40),
              _buildButton('العب مرة أخرى', const Color(0xFFB536FF), onRestart),
              const SizedBox(height: 12),
              _buildButton('القائمة الرئيسية', Colors.white24, onMainMenu),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
