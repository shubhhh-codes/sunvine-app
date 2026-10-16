import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_models.dart';

/// Reusable quotation summary tile for dashboard feed.
class RecentQuoteTileWidget extends StatelessWidget {
  final RecentQuoteSummary quote;
  final VoidCallback? onTap;

  const RecentQuoteTileWidget({
    super.key,
    required this.quote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SunCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quote.customerName, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text('${quote.capacity} • ${quote.date}', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(quote.amount, style: AppTypography.monoMedium),
              const SizedBox(height: 4),
              SunBadge(label: quote.status, variant: quote.badgeVariant),
            ],
          ),
        ],
      ),
    );
  }
}
