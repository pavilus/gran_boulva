import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class VerificationBadge extends StatelessWidget {
  final String? type;
  final String? status;
  final String? badgeStyle;
  final double size;
  final bool showLabel;

  const VerificationBadge({
    super.key,
    required this.type,
    this.status,
    this.badgeStyle,
    this.size = 16,
    this.showLabel = false,
  });

  factory VerificationBadge.user(
    dynamic user, {
    Key? key,
    double size = 16,
    bool showLabel = false,
  }) {
    return VerificationBadge(
      key: key,
      type: user.verificationType,
      status: user.verificationStatus,
      badgeStyle: user.verificationBadgeStyle,
      size: size,
      showLabel: showLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == null || (status != null && status != 'approved')) {
      return const SizedBox.shrink();
    }

    final asset = _assetForStyle;
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.verified_rounded,
        color: _colorForType,
        size: size,
      ),
    );

    if (!showLabel) return image;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.45, vertical: 4),
      decoration: BoxDecoration(
        color: _colorForType.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _colorForType.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          image,
          SizedBox(width: size * 0.3),
          Text(
            label,
            style: TextStyle(
              color: _colorForType,
              fontSize: (size * 0.72).clamp(10, 13),
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String get label {
    switch (type) {
      case 'public_figure':
        return 'Pèsonalite';
      case 'organization':
        return 'Òganizasyon';
      case 'trusted_creator':
        return 'Kreyatè';
      case 'admin':
        return 'Ekip';
      default:
        return 'Verifye';
    }
  }

  String get _assetForStyle {
    switch (badgeStyle ?? type) {
      case 'business':
      case 'organization':
        return 'assets/images/business_verif.png';
      case 'gold':
      case 'public_figure':
        return 'assets/images/gold_verif.png';
      case 'silver':
      case 'trusted_creator':
        return 'assets/images/silver_verif.png';
      default:
        return 'assets/images/verified.png';
    }
  }

  Color get _colorForType {
    switch (type) {
      case 'organization':
        return const Color(0xFFE5B942);
      case 'public_figure':
        return const Color(0xFFFFC857);
      case 'trusted_creator':
        return const Color(0xFF94A3B8);
      case 'admin':
        return AppColors.pink;
      default:
        return AppColors.purpleLight;
    }
  }
}
