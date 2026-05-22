import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppHaptic {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  none,
}

class AppHaptics {
  const AppHaptics._();

  static void tap([AppHaptic haptic = AppHaptic.light]) {
    switch (haptic) {
      case AppHaptic.light:
        HapticFeedback.lightImpact();
      case AppHaptic.medium:
        HapticFeedback.mediumImpact();
      case AppHaptic.heavy:
        HapticFeedback.heavyImpact();
      case AppHaptic.selection:
        HapticFeedback.selectionClick();
      case AppHaptic.success:
        HapticFeedback.mediumImpact();
      case AppHaptic.warning:
        HapticFeedback.heavyImpact();
      case AppHaptic.none:
        break;
    }
  }
}

class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppHaptic haptic;
  final double pressedScale;
  final HitTestBehavior behavior;
  final Duration duration;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = AppHaptic.light,
    this.pressedScale = 0.97,
    this.behavior = HitTestBehavior.opaque,
    this.duration = const Duration(milliseconds: 110),
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              AppHaptics.tap(widget.haptic);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
