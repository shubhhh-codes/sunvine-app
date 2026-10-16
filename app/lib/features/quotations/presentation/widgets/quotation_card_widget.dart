import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/quotation_model.dart';

/// Reusable quotation summary card for quotation lists.
class QuotationCardWidget extends StatelessWidget {
  final QuotationModel quotation;
  final VoidCallback? onTap;

  const QuotationCardWidget({
    super.key,
    required this.quotation,
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
              Text(quotation.customerName, style: AppTypography.titleMedium),
              SunBadge(label: quotation.status, variant: quotation.badgeVariant),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${quotation.quoteNumber} • ${quotation.systemCapacityKw} kW System', style: AppTypography.bodySmall),
              Text('₹${quotation.totalAmount.toStringAsFixed(0)}', style: AppTypography.monoMedium),
            ],
          ),
        ],
      ),
    );
  }
}
