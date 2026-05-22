import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import 'app_interactions.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Border? border;
  final double borderRadius;

  const AppBackButton({
    super.key,
    required this.onTap,
    this.margin = const EdgeInsets.all(8),
    this.size = 40,
    this.iconSize = 18,
    this.backgroundColor = AppColors.card,
    this.iconColor = AppColors.textPrimary,
    this.border = const Border.fromBorderSide(
      BorderSide(color: AppColors.border, width: 1),
    ),
    this.borderRadius = 12,
  });

  const AppBackButton.homeStyle({
    super.key,
    required this.onTap,
    this.margin = const EdgeInsets.all(10),
  })  : size = 36,
        iconSize = 18,
        backgroundColor = AppColors.secondary,
        iconColor = Colors.white,
        border = null,
        borderRadius = 10;

  const AppBackButton.matchupStyle({
    super.key,
    required this.onTap,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 8, 8),
  })  : size = 44,
        iconSize = 18,
        backgroundColor = AppColors.bg1,
        iconColor = Colors.white,
        border = const Border.fromBorderSide(
          BorderSide(color: AppColors.border, width: 1),
        ),
        borderRadius = 14;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: Container(
        width: size,
        height: size,
        margin: margin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
