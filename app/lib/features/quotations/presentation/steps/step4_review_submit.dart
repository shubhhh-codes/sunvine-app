import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/create_quotation_controller.dart';

class Step4ReviewSubmit extends StatelessWidget {
  final CreateQuotationController controller;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmitOnline;

  const Step4ReviewSubmit({
    super.key,
    required this.controller,
    required this.onSaveDraft,
    required this.onSubmitOnline,
  });

  @override
  Widget build(BuildContext context) {
    final totals = controller.finalTotals;
    final generation = controller.generation;
    final savings = controller.savings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Proposal & Submit',
            style: AppTypography.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Verify all customer, technical and financial details before generating proposal.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 1. Customer Section
          _buildSectionCard(
            title: 'Customer Details',
            icon: Icons.person_outline,
            children: [
              _buildDetailRow('Customer Name', controller.customerName),
              _buildDetailRow('Mobile Number', '+91 ${controller.customerPhone}'),
              _buildDetailRow('Installation Location', controller.customerLocation.isNotEmpty ? controller.customerLocation : controller.city),
              _buildDetailRow('Payment Mode', controller.paymentMode == 'CASH' ? 'Cash Case' : 'Solar Loan (EMI)'),
              if (controller.consumerNumber.isNotEmpty)
                _buildDetailRow('Consumer Number', controller.consumerNumber),
              _buildDetailRow('Utility / DISCOM', '${controller.discom} (${controller.phase})'),
              _buildDetailRow('Sanctioned Load', '${controller.sanctionedLoadKw} kW'),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Solar Technical Specs
          _buildSectionCard(
            title: 'Solar System Specifications',
            icon: Icons.solar_power_outlined,
            children: [
              _buildDetailRow('System Capacity', '${controller.selectedCapacityKw.toStringAsFixed(1)} kW (${controller.totalKwp} kWp)'),
              _buildDetailRow('Project Scheme', controller.projectType == 'Residential' ? 'Residential (PM Surya Ghar Subsidy)' : 'Commercial / Industrial'),
              _buildDetailRow('Solar Modules', '${controller.panelCount} × ${controller.selectedModule?.brand ?? "APS"} ${controller.selectedModule?.wattage ?? 550}W'),
              _buildDetailRow('Module Technology', controller.selectedModule?.technology ?? 'TOPCon Bifacial Dual Glass'),
              _buildDetailRow('Rooftop Area', '~${controller.rooftopAreaSqFt} Sq. Ft.'),
              _buildDetailRow('On-Grid Inverter', '${controller.selectedInverter?.brand ?? "Solis"} ${controller.selectedCapacityKw.toStringAsFixed(1)} kW'),
              _buildDetailRow('Mounting Structure', controller.structureType),
              _buildDetailRow('Performance Warranty', '25 Years Linear Warranty (Tier-1 ALMM)'),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Financial Breakdown
          _buildSectionCard(
            title: 'Financial Summary',
            icon: Icons.currency_rupee,
            children: [
              _buildDetailRow('Complete Solar Package (Base)', '₹\u00A0${controller.baseTurnkeyCost.toStringAsFixed(0)}'),
              _buildDetailRow('Channel Margin', '+ ₹\u00A0${controller.dealerMarginInr.toStringAsFixed(0)}',
                  valueColor: AppColors.secondary),
              _buildDetailRow('Statutory GST (18%) Included', '₹\u00A0${(totals['gstAmount'] ?? 0).toStringAsFixed(0)}'),
              if (controller.enableExtraTransport && controller.extraTransportAmount > 0)
                _buildDetailRow('Extra Outstation Freight', '+ ₹\u00A0${controller.extraTransportAmount.toStringAsFixed(0)}',
                    valueColor: AppColors.secondary),
              const Divider(color: AppColors.border, height: 16),
              _buildDetailRow('Total Project Cost', '₹\u00A0${(totals['totalAmount'] ?? 0).toStringAsFixed(0)}', isBold: true),
              _buildDetailRow('PM Surya Ghar Subsidy', '- ₹\u00A0${controller.centralSubsidy.toStringAsFixed(0)}',
                  valueColor: AppColors.primary, isBold: true),
              const Divider(color: AppColors.border, height: 16),
              _buildDetailRow(
                'Net Effective Investment',
                '₹\u00A0${(totals['netPayable'] ?? 0).toStringAsFixed(0)}',
                valueColor: AppColors.primary,
                isBold: true,
              ),
              if (controller.isLoanSelected) ...[
                const SizedBox(height: 4),
                _buildDetailRow('Estimated Solar EMI', '₹\u00A0${controller.monthlyLoanEmi.toStringAsFixed(0)} / month',
                    valueColor: AppColors.secondary),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 4. Generation & Payback
          _buildSectionCard(
            title: 'Energy & Economic Returns',
            icon: Icons.energy_savings_leaf_outlined,
            children: [
              _buildDetailRow('Estimated Annual Units', '${generation['annualUnits']} kWh / year'),
              _buildDetailRow('Annual Electricity Savings', '₹\u00A0${(savings['annualSavings'] as double? ?? 0).toStringAsFixed(0)}'),
              _buildDetailRow('Estimated Payback Period', '${savings['paybackText']}'),
            ],
          ),
          const SizedBox(height: 24),

          // Offline auto-sync assurance note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auto-Sync Enabled: If your device is offline in the field, this quote will be secured locally and automatically uploaded to cloud when internet is available.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SunButton(
                  text: 'Save Draft',
                  variant: SunButtonVariant.secondary,
                  icon: Icons.bookmark_border,
                  isLoading: controller.isSubmitting,
                  onPressed: onSaveDraft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SunButton(
                  text: 'Generate & Submit',
                  variant: SunButtonVariant.primary,
                  icon: Icons.send_rounded,
                  isLoading: controller.isSubmitting,
                  onPressed: onSubmitOnline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
