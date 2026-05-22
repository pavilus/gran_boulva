import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Renders a display name with an optional username effect (glow / gradient)
/// and an optional cosmetic badge icon (👑 / 🔥) prepended to it.
///
/// Usage:
/// ```dart
/// CosmeticUsername(
///   name: user.fullName,
///   effectKey: equipped.usernameEffectKey,
///   badgeKey: equipped.cosmeticBadgeKey,
///   style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
/// )
/// ```
class CosmeticUsername extends StatelessWidget {
  final String name;
  final String? effectKey;
  final String? badgeKey;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow overflow;

  const CosmeticUsername({
    super.key,
    required this.name,
    this.effectKey,
    this.badgeKey,
    required this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  // ── Badge icons ──────────────────────────────────────────────────────────────

  Widget? _badgeWidget(double fontSize) {
    switch (badgeKey) {
      case 'badge_kouwon':
        return Text(
          '👑 ',
          style: TextStyle(fontSize: fontSize * 0.8),
        );
      case 'badge_dife':
        return Image.asset(
          'assets/images/fire.png',
          width: fontSize * 0.9,
          height: fontSize * 0.9,
        );
      default:
        return null;
    }
  }

  // ── Effect rendering ─────────────────────────────────────────────────────────

  Widget _buildText() {
    switch (effectKey) {
      // Bright white glow
      case 'effect_briyan':
        return Text(
          name,
          style: style.copyWith(
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          maxLines: maxLines,
          overflow: overflow,
        );

      // Purple→pink gradient text
      case 'effect_gradiyan':
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF60A5FA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            name,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
          ),
        );

      default:
        return Text(
          name,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 16;
    final badge = _badgeWidget(fontSize);

    if (badge == null) return _buildText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badge,
        const SizedBox(width: 3),
        Flexible(child: _buildText()),
      ],
    );
  }
}

/// A smaller variant used for `@username` handles with optional glow.
class CosmeticHandle extends StatelessWidget {
  final String handle;
  final String? effectKey;
  final TextStyle style;

  const CosmeticHandle({
    super.key,
    required this.handle,
    this.effectKey,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (effectKey) {
      case 'effect_briyan':
        return Text(
          handle,
          style: style.copyWith(
            shadows: [
              Shadow(
                color: AppColors.purpleLight.withValues(alpha: 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        );
      case 'effect_gradiyan':
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.purpleLight,
              Color(0xFFEC4899),
            ],
          ).createShader(bounds),
          child: Text(handle, style: style),
        );
      default:
        return Text(handle, style: style);
    }
  }
}
