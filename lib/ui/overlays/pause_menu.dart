import 'package:flutter/material.dart';
import '../../game/spectra_sprint_game.dart';
import '../../data/game_data.dart';
import '../../game/audio/audio_manager.dart';
import '../../services/ad_service.dart';

// قائمة الإيقاف المؤقت
class PauseMenu extends StatefulWidget {
  final SpectraSprintGame game;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const PauseMenu({
    super.key,
    required this.game,
    required this.onResume,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 80,
                ),
                child: Center(
                  child: _showSettings
                      ? _buildSettings()
                      : _buildPauseButtons(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPauseButtons() {
    return Container(
      width: 320, // تحديد عرض ثابت ليكون متناسقاً
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0033),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFB536FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB536FF).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // عنوان أصغر قليلاً لتوفير مساحة
          const Text(
            'PAUSED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),

          // زر الاستئناف
          _buildButton(
            'استئناف',
            const Color(0xFF00D9FF),
            widget.onResume,
            Icons.play_arrow,
          ),
          const SizedBox(height: 12),

          // --- خيارات القلوب الجديدة ---
          if (widget.game.lives < 3 && GameData().extraLives > 0) ...[
            _buildButton(
              'استخدام قلب احتياطي (${GameData().extraLives})',
              const Color(0xFFFF0054),
              () {
                widget.game.useReserveHeart();
                setState(() {});
              },
              Icons.favorite,
            ),
            const SizedBox(height: 12),
          ],

          _buildButton(
            'شراء قلب (100 عملة)',
            const Color(0xFFFFEC00),
            () async {
              final success = await widget.game.buyHeart();
              if (!success && mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'لا تملك عملات كافية لشراء قلب! ❌⭐',
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Color(0xFFFF0054),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              setState(() {});
            },
            Icons.stars,
          ),
          const SizedBox(height: 12),

          _buildButton('قلب مجاني (إعلان)', const Color(0xFF00FF88), () async {
            if (!AdService().isRewardedAdReady) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('الإعلان قيد التحميل... ⏳'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            AdService().showRewardedAd(
              onRewardEarned: () async {
                await widget.game.buyHeart(isAd: true);
                setState(() {});
              },
            );
          }, Icons.ondemand_video),
          const SizedBox(height: 12),
          // --------------------------

          // زر الإعدادات
          _buildButton('الإعدادات', const Color(0xFFAAAAAA), () {
            setState(() {
              _showSettings = true;
            });
          }, Icons.settings),
          const SizedBox(height: 12),

          // زر إعادة البدء
          _buildButton(
            'إعادة البدء',
            const Color(0xFF555555),
            widget.onRestart,
            Icons.refresh,
          ),
          const SizedBox(height: 12),

          // زر القائمة الرئيسية
          _buildButton(
            'القائمة الرئيسية',
            const Color(0xFF333333).withOpacity(0.5),
            widget.onMainMenu,
            Icons.home,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0033),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEC00), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFEC00).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // عنوان
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showSettings = false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'الإعدادات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48), // للتوازن
            ],
          ),
          const SizedBox(height: 32),

          // الموسيقى
          _buildSettingToggle(
            'الموسيقى',
            GameData().musicEnabled,
            Icons.music_note,
            (value) async {
              await GameData().toggleMusic();
              setState(() {});

              if (GameData().musicEnabled) {
                AudioManager().resumeMusic();
              } else {
                AudioManager().pauseMusic();
              }
            },
          ),
          const SizedBox(height: 24),

          // المؤثرات الصوتية
          _buildSettingToggle(
            'المؤثرات الصوتية',
            GameData().sfxEnabled,
            Icons.volume_up,
            (value) async {
              await GameData().toggleSfx();
              setState(() {});
            },
          ),
          const SizedBox(height: 32),

          // زر الرجوع
          _buildButton('رجوع', const Color(0xFF00D9FF), () {
            setState(() {
              _showSettings = false;
            });
          }, Icons.arrow_back),
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
      width: 280,
      height: 48,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
    String label,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: value ? const Color(0xFF00D9FF) : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFF00D9FF) : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D9FF),
            activeTrackColor: const Color(0xFF00D9FF).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
