import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'data/game_data.dart';
import 'game/audio/audio_manager.dart';
import 'game/spectra_sprint_game.dart';
import 'services/ad_service.dart';
import 'ui/screens/main_menu.dart';
import 'ui/overlays/game_hud.dart';
import 'ui/overlays/pause_menu.dart';
import 'ui/overlays/game_over.dart';
import 'ui/overlays/death_sequence.dart';
import 'ui/overlays/victory_overlay.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // قفل الاتجاه لوضع Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة البيانات والصوت والإعلانات
  await GameData().init();
  await AudioManager().init();
  await AdService().init();

  // تفعيل وضع الشاشة الكاملة الحقيقي (Immersive Mode) لإخفاء أي شريط علوي
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const SpectraSprintApp());
}

class SpectraSprintApp extends StatelessWidget {
  const SpectraSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spectra Sprint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFB536FF),
        scaffoldBackgroundColor: const Color(0xFF0A001A),
        fontFamily: 'Roboto',
      ),
      home: const GameWrapper(),
    );
  }
}

class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  bool _isPlaying = false;
  late SpectraSprintGame game;

  @override
  void initState() {
    super.initState();
    _initializeGame();

    // إعداد الكول باك لإظهار الإعلان بمجرد تحميله في المرة الأولى
    AdService().onAppOpenAdLoaded = () {
      if (mounted && !_isPlaying) {
        AdService().showAppOpenAd();
        // تصفير الكول باك بعد العرض الأول لتجنب تكراره في أوقات غير مناسبة
        AdService().onAppOpenAdLoaded = null;
      }
    };

    // محاولة عرض الإعلان فوراً إذا كان جاهزاً (نادراً ما يحدث في الثانية الأولى)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AdService().isAppOpenAdReady) {
        AdService().showAppOpenAd();
      }
    });
  }

  void _initializeGame() {
    game = SpectraSprintGame();

    // ربط callbacks - استخدام Future.microtask لتجنب استدعاء setState أثناء البناء
    game.onScoreChanged = (score) {
      Future.microtask(() {
        if (mounted) setState(() {});
      });
    };

    game.onGameStateChanged = (state) {
      Future.microtask(() {
        if (mounted) setState(() {});
      });
    };

    game.onDistanceChanged = (distance) {
      Future.microtask(() {
        if (mounted) setState(() {});
      });
    };

    game.onGameOver = () {
      Future.microtask(() {
        if (mounted) setState(() {});
      });
    };
  }

  void _startGame() {
    AdService().showInterstitialAd(
      onAdDismissed: () {
        setState(() {
          _isPlaying = true;
        });
      },
    );
  }

  void _returnToMenu() {
    setState(() {
      _isPlaying = false;
      _initializeGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying) {
      return MainMenu(onPlay: _startGame);
    }

    return Scaffold(
      body: Stack(
        children: [
          // اللعبة
          GameWidget(game: game),

          // عرض الـ overlays بناءً على حالة اللعبة
          if (game.gameState == GameState.paused)
            PauseMenu(
              game: game,
              onResume: () {
                game.resumeGame();
                setState(() {});
              },
              onRestart: () {
                game.restartGame();
                setState(() {});
              },
              onMainMenu: _returnToMenu,
            ),

          if (game.gameState == GameState.gameOver)
            GameOverOverlay(
              game: game,
              onRestart: () {
                game.restartGame();
                setState(() {});
              },
              onMainMenu: _returnToMenu,
            ),

          if (game.gameState == GameState.playing)
            GameHUD(
              game: game,
              onPause: () {
                game.pauseGame();
                setState(() {});
              },
            ),

          if (game.gameState == GameState.gameOverSequence)
            DeathSequence(game: game),

          if (game.gameState == GameState.victory)
            VictoryOverlay(
              game: game,
              onRestart: () {
                game.restartGame();
                setState(() {});
              },
              onMainMenu: _returnToMenu,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
