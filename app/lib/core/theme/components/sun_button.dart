import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

enum SunButtonVariant { primary, secondary, danger }

class SunButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SunButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const SunButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SunButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50.0, // Touch target >= 48dp
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    BoxDecoration decoration;
    Color textColor = AppColors.textPrimary;

    switch (variant) {
      case SunButtonVariant.primary:
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
                  )
                ]
              : null,
        );
        textColor = Colors.white;
        break;

      case SunButtonVariant.secondary:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? AppColors.border : AppColors.borderLight),
        );
        textColor = enabled ? AppColors.textPrimary : AppColors.textDisabled;
        break;

      case SunButtonVariant.danger:
        decoration = BoxDecoration(
          color: enabled ? AppColors.rose.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? AppColors.rose : AppColors.border),
        );
        textColor = enabled ? AppColors.rose : AppColors.textDisabled;
        break;
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: decoration,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isLoading
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
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTypography.labelLarge.copyWith(color: textColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
