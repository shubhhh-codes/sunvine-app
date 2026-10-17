import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

enum SunButtonVariant { primary, secondary, danger }

class SunButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SunButtonVariant variant;
  final bool isLoading;
  final bool isSubdued;
  final IconData? icon;
  final double? width;
  final double height;

  const SunButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SunButtonVariant.primary,
    this.isLoading = false,
    this.isSubdued = false,
    this.icon,
    this.width,
    this.height = 50.0, // Touch target >= 48dp
  });

  @override
  State<SunButton> createState() => _SunButtonState();
}

class _SunButtonState extends State<SunButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;

    BoxDecoration decoration;
    Color textColor = AppColors.textPrimary;

    switch (widget.variant) {
      case SunButtonVariant.primary:
        if (widget.isSubdued && enabled) {
          decoration = BoxDecoration(
            color: AppColors.surfaceHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          );
          textColor = AppColors.textSecondary;
        } else {
          decoration = BoxDecoration(
            gradient: enabled ? AppColors.energyGradient : null,
            color: enabled ? null : AppColors.surfaceHover,
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          );
          textColor = enabled ? Colors.white : AppColors.textDisabled;
        }
        break;

      case SunButtonVariant.secondary:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.border : AppColors.borderLight,
          ),
        );
        textColor = enabled ? AppColors.textPrimary : AppColors.textDisabled;
        break;

      case SunButtonVariant.danger:
        decoration = BoxDecoration(
          color: enabled
              ? AppColors.rose.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.rose : AppColors.border,
          ),
        );
        textColor = enabled ? AppColors.rose : AppColors.textDisabled;
        break;
    }

    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled
              ? () => setState(() => _isPressed = false)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedScale(
            scale: (_isPressed && !disableAnimations) ? 0.98 : 1.0,
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: decoration,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: AppTypography.labelLarge.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
