import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/spectra_sprint_game.dart';

class DeathSequence extends StatefulWidget {
  final SpectraSprintGame game;

  const DeathSequence({super.key, required this.game});

  @override
  State<DeathSequence> createState() => _DeathSequenceState();
}

class _DeathSequenceState extends State<DeathSequence> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 2; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 10),
                      Shadow(color: Colors.red, blurRadius: 20),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                ),
            const SizedBox(height: 20),
            Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate(key: ValueKey(_countdown))
                .scale(
                  begin: const Offset(1.5, 1.5),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(),
          ],
        ),
      ),
    );
  }
}
