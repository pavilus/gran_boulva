import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../common/user_avatar.dart';

/// Renders a user avatar with their equipped profile frame cosmetic.
/// Pass [frameKey] from EquippedCosmetics.profileFrameKey.
/// Gracefully falls back to the default purple gradient if null.
class CosmeticAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? gender;
  final String? frameKey;

  /// Outer circle diameter (total including ring).
  final double size;

  /// Ring thickness in logical pixels.
  final double ringWidth;

  const CosmeticAvatar({
    super.key,
    this.avatarUrl,
    this.gender,
    this.frameKey,
    this.size = 80,
    this.ringWidth = 3,
  });

  // ── Frame configs ────────────────────────────────────────────────────────────

  static const _frames = <String, _FrameConfig>{
    'frame_neon_violet': _FrameConfig(
      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
      glowColor: Color(0xFFA855F7),
    ),
    'frame_kade_lo': _FrameConfig(
      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
      glowColor: Color(0xFFFBBF24),
    ),
    'frame_fon_ayiti': _FrameConfig(
      colors: [Color(0xFF003087), Color(0xFF0051D5), Color(0xFFD21034)],
      glowColor: Color(0xFF6A5DB0),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'frame_fondate': _FrameConfig(
      colors: [Color(0xFFEC4899), Color(0xFF9333EA), Color(0xFFEC4899)],
      glowColor: Color(0xFFEC4899),
    ),
    'frame_glorye': _FrameConfig(
      colors: [
        Color(0xFFFF6B6B),
        Color(0xFFFBBF24),
        Color(0xFF4ADE80),
        Color(0xFF60A5FA),
        Color(0xFFA855F7),
        Color(0xFFFF6B6B),
      ],
      glowColor: Color(0xFFA855F7),
    ),
  };

  // Default gradient when no frame is equipped (matches app's existing style)
  static const _defaultGradient = LinearGradient(
    colors: [Color(0xFF6F2BFF), Color(0xFFFF2DAA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final config = frameKey != null ? _frames[frameKey] : null;

    final gradient = config != null
        ? LinearGradient(
            colors: config.colors,
            begin: config.begin,
            end: config.end,
          )
        : _defaultGradient;

    final glowColor = config?.glowColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.purpleLight.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      padding: EdgeInsets.all(ringWidth),
      child: CircleAvatar(
        backgroundColor: AppColors.bg1,
        backgroundImage: avatarUrl != null
            ? CachedNetworkImageProvider(avatarUrl!)
            : UserAvatar.defaultImageProvider(gender),
      ),
    );
  }
}

// ── Internal config ───────────────────────────────────────────────────────────

class _FrameConfig {
  final List<Color> colors;
  final Color glowColor;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const _FrameConfig({
    required this.colors,
    required this.glowColor,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });
}
