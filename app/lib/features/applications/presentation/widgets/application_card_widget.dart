import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/customer_file_model.dart';

/// Reusable application pipeline progress card widget.
class ApplicationCardWidget extends StatelessWidget {
  final CustomerFileModel application;
  final VoidCallback? onTap;

  const ApplicationCardWidget({
    super.key,
    required this.application,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SunCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(application.customerName, style: AppTypography.titleMedium),
              const SunBadge(label: 'ACTIVE', variant: SunBadgeVariant.emerald),
            ],
          ),
          const SizedBox(height: 4),
          Text('File: ${application.fileNo}', style: AppTypography.monoSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(application.stage, style: AppTypography.labelMedium.copyWith(color: AppColors.emerald)),
              Text('Step ${application.currentStep} of ${application.totalSteps}', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: application.progress,
            backgroundColor: AppColors.surfaceSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
