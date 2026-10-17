import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

enum SunBadgeVariant { emerald, amber, rose, cyan, slate }

class SunBadge extends StatelessWidget {
  final String label;
  final SunBadgeVariant variant;
  final IconData? icon;

  const SunBadge({
    super.key,
    required this.label,
    this.variant = SunBadgeVariant.emerald,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case SunBadgeVariant.emerald:
        bg = AppColors.emerald.withValues(alpha: 0.12);
        border = AppColors.emerald.withValues(alpha: 0.4);
        text = AppColors.emerald;
        break;
      case SunBadgeVariant.amber:
        bg = AppColors.amber.withValues(alpha: 0.12);
        border = AppColors.amber.withValues(alpha: 0.4);
        text = AppColors.amber;
        break;
      case SunBadgeVariant.rose:
        bg = AppColors.rose.withValues(alpha: 0.12);
        border = AppColors.rose.withValues(alpha: 0.4);
        text = AppColors.rose;
        break;
      case SunBadgeVariant.cyan:
        bg = AppColors.cyan.withValues(alpha: 0.12);
        border = AppColors.cyan.withValues(alpha: 0.4);
        text = AppColors.cyan;
        break;
      case SunBadgeVariant.slate:
        bg = AppColors.border.withValues(alpha: 0.4);
        border = AppColors.border;
        text = AppColors.textSecondary;
        break;
    }

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: text),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTypography.labelSmall.copyWith(color: text)),
          ],
        ),
      ),
    );
  }
}
