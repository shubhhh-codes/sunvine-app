import 'package:flutter/material.dart';

import '../app_colors.dart';

class SunCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const SunCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 12.0,
  });

  @override
  State<SunCard> createState() => _SunCardState();
}

class _SunCardState extends State<SunCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border:
            widget.border ??
            Border.all(
              color: _isPressed
                  ? AppColors.emerald.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: _isPressed
                ? AppColors.emerald.withValues(alpha: 0.1)
                : AppColors.cardShadow,
            blurRadius: _isPressed ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
