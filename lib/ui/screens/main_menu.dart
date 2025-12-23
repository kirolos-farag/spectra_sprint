import 'package:flutter/material.dart';
import '../../data/game_data.dart';
import '../../services/ad_service.dart';
import '../../utils/constants.dart';

// شاشة القائمة الرئيسية
class MainMenu extends StatefulWidget {
  final VoidCallback onPlay;

  const MainMenu({super.key, required this.onPlay});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A001A),
              Color(0xFF1A0033),
              Color(0xFF2E0052),
              Color(0xFF4A0A7A),
            ],
          ),
        ),
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // شعار اللعبة
                          _buildLogo(),
                          const SizedBox(height: 40),
                          // زر اللعب
                          _buildPlayButton(context),
                          const SizedBox(height: 30),
                          // أعلى نتيجة
                          _buildHighScore(),
                          const SizedBox(height: 30),
                          // متجر القلوب
                          _buildHeartShop(),
                          const SizedBox(height: 20),
                          // وضع اللعب
                          _buildModeToggle(),
                          const SizedBox(height: 40),
                          // معلومات إضافية
                          _buildFooter(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // عرض العملات في أعلى اليسار
            Positioned(top: 40, left: 20, child: _buildCoinDisplay()),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEC00).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFEC00), size: 20),
          const SizedBox(width: 8),
          Text(
            '${GameData().totalCoins}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartShop() {
    final extraLives = GameData().extraLives;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFF0054), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'الأرواح الإضافية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'لديك: $extraLives',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _buyHeart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEC00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, size: 16),
                    const SizedBox(width: 4),
                    Text('${GameConstants.coinHeartCost}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _showRewardedAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill, size: 16),
                    SizedBox(width: 4),
                    Text('مجاني (إعلان)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRewardedAd() {
    if (!AdService().isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الإعلان جاري التحميل... يرجى المحاولة بعد لحظات ⏳'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    AdService().showRewardedAd(
      onRewardEarned: () async {
        // إضافة قلب مجاني
        await GameData().addFreeLife();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مبروك! حصلت على قلب إضافي مجاني ❤️'),
              backgroundColor: Color(0xFF00D9FF),
            ),
          );
        }
      },
    );
  }

  void _buyHeart() async {
    final success = await GameData().buyExtraLife();
    if (success) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم شراء قلب إضافي بنجاح! ❤️'),
            backgroundColor: Color(0xFF00D9FF),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا تملك عملات كافية! ⭐'),
            backgroundColor: Color(0xFFFF0054),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF0054),
              Color(0xFF00D9FF),
              Color(0xFFFFEC00),
              Color(0xFFB536FF),
            ],
          ).createShader(bounds),
          child: const Text(
            'SPECTRA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
        ),
        const Text(
          'SPRINT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w300,
            letterSpacing: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPlay,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0054), Color(0xFFB536FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0054).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 80),
      ),
    );
  }

  Widget _buildHighScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEC00), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFFEC00), size: 24),
          const SizedBox(width: 12),
          Text(
            'أعلى نتيجة: ${GameData().highScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const Text(
            'اسحب للقفز، ولليمين/اليسار للحركة',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    final isRandom = GameData().randomMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 60),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRandom ? const Color(0xFF00D9FF) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRandom ? 'وضع عشوائي 🎲' : 'وضع القصة 📖',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                isRandom ? 'مراحل غير مرتبة' : 'مراحل متتالية',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          Switch(
            value: isRandom,
            onChanged: (value) async {
              await GameData().toggleRandomMode();
              setState(() {});
            },
            activeColor: const Color(0xFF00D9FF),
          ),
        ],
      ),
    );
  }
}
