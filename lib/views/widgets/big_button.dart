import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Botão base de ergonomia automotiva: alvo grande, cantos amplos, long-press opcional.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.width,
    this.height = 80,
    this.filled = false,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double? width; // null = expande (use dentro de Expanded)
  final double height;
  final bool filled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.accent
        : selected
            ? AppColors.accent.withValues(alpha: .28)
            : AppColors.surfaceHigh;
    final fg = filled ? Colors.black : AppColors.text;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: fg),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
