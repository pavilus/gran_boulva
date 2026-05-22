import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/badge_unlock_events.dart';
import '../common/app_interactions.dart';

class BadgeUnlockOverlayHost extends StatefulWidget {
  final Widget child;

  const BadgeUnlockOverlayHost({super.key, required this.child});

  @override
  State<BadgeUnlockOverlayHost> createState() => _BadgeUnlockOverlayHostState();
}

class _BadgeUnlockOverlayHostState extends State<BadgeUnlockOverlayHost> {
  StreamSubscription<BadgeEventResult>? _subscription;
  BadgeEventResult? _badge;

  @override
  void initState() {
    super.initState();
    _subscription = BadgeUnlockEvents.stream.listen((badge) {
      if (!mounted) return;
      AppHaptics.tap(AppHaptic.success);
      setState(() => _badge = badge);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_badge != null)
          Positioned.fill(
            child: _BadgeUnlockOverlay(
              key: ValueKey('${_badge!.badgeKey}-${_badge!.level}'),
              badge: _badge!,
              onClose: () => setState(() => _badge = null),
            ),
          ),
      ],
    );
  }
}

class _BadgeUnlockOverlay extends StatefulWidget {
  final BadgeEventResult badge;
  final VoidCallback onClose;

  const _BadgeUnlockOverlay({
    super.key,
    required this.badge,
    required this.onClose,
  });

  @override
  State<_BadgeUnlockOverlay> createState() => _BadgeUnlockOverlayState();
}

class _BadgeUnlockOverlayState extends State<_BadgeUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_UnlockParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    final random = math.Random(widget.badge.badgeKey.hashCode);
    final theme = _badgeTheme(widget.badge.badgeKey);
    _particles = List.generate(50, (index) {
      return _UnlockParticle(
        x: random.nextDouble(),
        startY: random.nextDouble(),
        size: 4 + random.nextDouble() * 6,
        delay: random.nextDouble() * 0.45,
        speed: 0.45 + random.nextDouble() * 0.6,
        color: theme.particleColors[index % theme.particleColors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _badgeAsset(widget.badge.badgeKey);
    final theme = _badgeTheme(widget.badge.badgeKey);
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final time = _controller.value;
          final entrance = Curves.easeOutBack.transform(
            ((time * 3.6) / 1).clamp(0, 1).toDouble(),
          );
          final textReveal = Curves.easeOut.transform(
            (((time * 3.6) - 1.05) / 0.65).clamp(0, 1).toDouble(),
          );
          final floatY = math.sin(time * math.pi * 2) * -12;
          final glow = 18 + ((math.sin(time * math.pi * 4) + 1) * 18);
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1,
                    colors: [theme.backgroundCenter, theme.backgroundEdge],
                    stops: const [0, 0.72],
                  ),
                ),
              ),
              for (final particle in _particles)
                _ParticleDot(particle: particle, time: time),
              Center(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 420,
                          height: 420,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _PulseRing(time: time, color: theme.ringColor),
                              _PulseRing(
                                time: (time + 0.22) % 1,
                                color: theme.ringColor,
                              ),
                              if (theme.hasSweep)
                                _BadgeSweep(
                                  time: time,
                                  colors: theme.sweepColors,
                                ),
                              _BadgeHeat(time: time, theme: theme),
                              Transform.translate(
                                offset: Offset(0, floatY),
                                child: Transform.rotate(
                                  angle: (1 - entrance) * -0.26,
                                  child: Transform.scale(
                                    scale: 0.2 + (entrance * 0.8),
                                    child: Opacity(
                                      opacity: entrance.clamp(0, 1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.glowColor
                                                  .withValues(alpha: 0.72),
                                              blurRadius: glow,
                                              spreadRadius: glow * 0.16,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          image,
                                          width: 300,
                                          height: 300,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.workspace_premium_rounded,
                                            color: AppColors.warning,
                                            size: 180,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, 30 * (1 - textReveal)),
                          child: Opacity(
                            opacity: textReveal,
                            child: Column(
                              children: [
                                Text(
                                  'BADJ DEBLOKE!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.titleColor,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: theme.glowColor,
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _subtitle(widget.badge),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.subtitleColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 28),
                                AppPressable(
                                  onTap: widget.onClose,
                                  haptic: AppHaptic.selection,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.purple
                                              .withValues(alpha: 0.34),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Kontinye',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double time;
  final Color color;

  const _PulseRing({required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = Curves.easeOut.transform(time);
    return Transform.scale(
      scale: 0.7 + (progress * 0.8),
      child: Opacity(
        opacity: (1 - progress).clamp(0, 1),
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 5,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeSweep extends StatelessWidget {
  final double time;
  final List<Color> colors;

  const _BadgeSweep({required this.time, required this.colors});

  @override
  Widget build(BuildContext context) {
    final entrance = Curves.easeOut.transform((time * 3.4).clamp(0, 1));
    return Transform.rotate(
      angle: (-1.9 + entrance * 6.3),
      child: Transform.scale(
        scale: 0.4 + entrance * 0.6,
        child: Opacity(
          opacity: 0.18 + ((1 - entrance) * 0.74),
          child: Container(
            width: 390,
            height: 390,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: colors),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeHeat extends StatelessWidget {
  final double time;
  final _BadgeUnlockTheme theme;

  const _BadgeHeat({required this.time, required this.theme});

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(time * math.pi * 4) + 1) / 2;
    return Transform.scale(
      scale: 0.92 + pulse * 0.16,
      child: Opacity(
        opacity: 0.52 + pulse * 0.28,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                theme.glowColor.withValues(alpha: 0.35),
                theme.glowColor.withValues(alpha: 0.12),
                Colors.transparent,
              ],
              stops: const [0, 0.42, 0.76],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  final _UnlockParticle particle;
  final double time;

  const _ParticleDot({required this.particle, required this.time});

  @override
  Widget build(BuildContext context) {
    final progress = ((time - particle.delay) * particle.speed * 2) % 1;
    final opacity = (1 - progress).clamp(0, 1).toDouble();
    return Positioned(
      left: MediaQuery.sizeOf(context).width * particle.x,
      top: MediaQuery.sizeOf(context).height *
          (particle.startY - (progress * 1.15)),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 1 - (progress * 0.85),
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: particle.color,
              boxShadow: [
                BoxShadow(color: particle.color, blurRadius: particle.size * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockParticle {
  final double x;
  final double startY;
  final double size;
  final double delay;
  final double speed;
  final Color color;

  const _UnlockParticle({
    required this.x,
    required this.startY,
    required this.size,
    required this.delay,
    required this.speed,
    required this.color,
  });
}

class _BadgeUnlockTheme {
  final Color backgroundCenter;
  final Color backgroundEdge;
  final Color ringColor;
  final Color glowColor;
  final Color titleColor;
  final Color subtitleColor;
  final List<Color> particleColors;
  final List<Color> sweepColors;
  final bool hasSweep;

  const _BadgeUnlockTheme({
    required this.backgroundCenter,
    required this.backgroundEdge,
    required this.ringColor,
    required this.glowColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.particleColors,
    this.sweepColors = const [],
    this.hasSweep = false,
  });
}

_BadgeUnlockTheme _badgeTheme(String key) {
  switch (key) {
    case 'hot_streak':
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF3A0C00),
        backgroundEdge: Color(0xFF0B0300),
        ringColor: Color(0xFFFF9900),
        glowColor: Color(0xFFFF8C00),
        titleColor: Color(0xFFFFF6D5),
        subtitleColor: Color(0xFFFFD27A),
        particleColors: [
          Color(0xFFFFB700),
          Color(0xFFFF8C00),
          Color(0xFFFF6500),
          Color(0xFFFFD27A),
        ],
        sweepColors: [
          Colors.transparent,
          Color(0xFFFFB700),
          Color(0xCCFF5000),
          Colors.transparent,
          Colors.transparent,
        ],
        hasSweep: true,
      );
    case 'top_voter':
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF231164),
        backgroundEdge: Color(0xFF070315),
        ringColor: Color(0xFF9A7CFF),
        glowColor: Color(0xFFA78BFA),
        titleColor: Color(0xFFFFFFFF),
        subtitleColor: Color(0xFFE0D7FF),
        particleColors: [
          Color(0xFFE9DDFF),
          Color(0xFFA78BFA),
          Color(0xFF7DD3FC),
          Color(0xFFC4B5FD),
        ],
      );
    case 'debater':
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF003A58),
        backgroundEdge: Color(0xFF001018),
        ringColor: Color(0xFF38BDF8),
        glowColor: Color(0xFF22D3EE),
        titleColor: Color(0xFFE8FBFF),
        subtitleColor: Color(0xFFB7EEFF),
        particleColors: [
          Color(0xFF67E8F9),
          Color(0xFF38BDF8),
          Color(0xFFBAE6FD),
          Color(0xFF0EA5E9),
        ],
      );
    case 'consistent':
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF063A2C),
        backgroundEdge: Color(0xFF02110D),
        ringColor: Color(0xFF34D399),
        glowColor: Color(0xFF10B981),
        titleColor: Color(0xFFECFFF6),
        subtitleColor: Color(0xFFA7F3D0),
        particleColors: [
          Color(0xFF6EE7B7),
          Color(0xFF34D399),
          Color(0xFFD1FAE5),
          Color(0xFF2DD4BF),
        ],
      );
    case 'community':
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF4B1037),
        backgroundEdge: Color(0xFF12030D),
        ringColor: Color(0xFFF472B6),
        glowColor: Color(0xFFEC4899),
        titleColor: Color(0xFFFFF1F7),
        subtitleColor: Color(0xFFFBCFE8),
        particleColors: [
          Color(0xFFF9A8D4),
          Color(0xFFF472B6),
          Color(0xFFFBCFE8),
          Color(0xFFF0ABFC),
        ],
      );
    case 'founder':
    case 'founding_member':
    case 'fondate':
    default:
      return const _BadgeUnlockTheme(
        backgroundCenter: Color(0xFF2D0057),
        backgroundEdge: Color(0xFF0B0017),
        ringColor: Color(0xFFBA55FF),
        glowColor: Color(0xFFBB66FF),
        titleColor: Colors.white,
        subtitleColor: Color(0xFFD9B3FF),
        particleColors: [
          Color(0xFFD86FFF),
          Color(0xFFBB66FF),
          Color(0xFFFF9DFF),
          Color(0xFFD9B3FF),
        ],
      );
  }
}

String _badgeAsset(String key) {
  switch (key) {
    case 'founder':
    case 'founding_member':
    case 'fondate':
      return 'assets/images/fondatè.png';
    case 'top_voter':
      return 'assets/images/topvote.png';
    case 'hot_streak':
      return 'assets/images/sankanpe.png';
    case 'debater':
      return 'assets/images/grandebate.png';
    case 'consistent':
      return 'assets/images/konsistan.png';
    case 'community':
      return 'assets/images/sipote.png';
    default:
      return 'assets/images/fondatè.png';
  }
}

String _subtitle(BadgeEventResult badge) {
  if (badge.badgeKey == 'founder' ||
      badge.badgeKey == 'founding_member' ||
      badge.badgeKey == 'fondate') {
    return 'Ou se yon Manm Fondatè';
  }
  final name =
      badge.badgeName.trim().isEmpty ? 'yon nouvo badj' : badge.badgeName;
  return 'Ou debloke $name - Nivo ${badge.level}';
}
