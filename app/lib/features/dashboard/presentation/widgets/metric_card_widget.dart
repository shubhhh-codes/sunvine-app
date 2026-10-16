import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_models.dart';

/// Reusable KPI Metric Card widget.
class MetricCardWidget extends StatelessWidget {
  final DashboardKpi kpi;

  const MetricCardWidget({super.key, required this.kpi});

  @override
  Widget build(BuildContext context) {
    return SunCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kpi.title, style: AppTypography.labelSmall),
              Icon(kpi.icon, size: 16, color: kpi.accentColor),
            ],
          ),
          Text(kpi.value, style: AppTypography.monoLarge.copyWith(fontSize: 22)),
          Text(
            kpi.subtitle,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
