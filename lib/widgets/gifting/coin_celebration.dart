import 'dart:math';
import 'package:flutter/material.dart';

/// Animated coin burst that overlays on success.
/// Intensity 1–5 controls particle count + scale.
class CoinCelebration extends StatefulWidget {
  final int intensity;      // 1–5
  final String emoji;
  final String colorHex;
  final VoidCallback? onComplete;

  const CoinCelebration({
    super.key,
    required this.intensity,
    this.emoji = '💙',
    this.colorHex = '#3B82F6',
    this.onComplete,
  });

  @override
  State<CoinCelebration> createState() => _CoinCelebrationState();
}

class _CoinCelebrationState extends State<CoinCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _burstCtrl;
  late final AnimationController _labelCtrl;
  late final List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    final count = _particleCount(widget.intensity);

    _particles = List.generate(count, (_) => _Particle(_rng, widget.intensity));

    _burstCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.intensity * 120),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete?.call();
      });

    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _burstCtrl.forward();
    _labelCtrl.forward();
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  int _particleCount(int intensity) {
    switch (intensity) {
      case 1: return 6;
      case 2: return 10;
      case 3: return 16;
      case 4: return 22;
      case 5: return 30;
      default: return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _burstCtrl,
      builder: (context, _) {
        final t = _burstCtrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Particles
            ..._particles.map((p) {
              final px = p.dx * t * 130.0 * (widget.intensity * 0.5 + 0.5);
              final py = p.dy * t * 130.0 * (widget.intensity * 0.5 + 0.5);
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              final scale = (1.0 - t * 0.6).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(px, py),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      widget.emoji,
                      style: TextStyle(fontSize: 12.0 + widget.intensity * 2),
                    ),
                  ),
                ),
              );
            }),

            // Central label pop
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _labelCtrl,
                curve: Curves.elasticOut,
              ),
              child: FadeTransition(
                opacity: _labelCtrl,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _hexToColor(widget.colorHex).withAlpha(30),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _hexToColor(widget.colorHex).withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hexToColor(widget.colorHex).withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.emoji,
                          style: TextStyle(fontSize: 22.0 + widget.intensity * 2)),
                      const SizedBox(width: 8),
                      Text(
                        'Voye!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0 + widget.intensity,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  return const Color(0xFF3B82F6);
}

class _Particle {
  final double dx;
  final double dy;

  _Particle(Random rng, int intensity) :
    dx = (rng.nextDouble() * 2 - 1),
    dy = (rng.nextDouble() * 2 - 1);
}
