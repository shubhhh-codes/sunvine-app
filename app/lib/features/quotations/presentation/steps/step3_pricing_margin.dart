import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/create_quotation_controller.dart';
import '../../domain/models/catalog_models.dart';

class Step3PricingMargin extends StatefulWidget {
  final CreateQuotationController controller;

  const Step3PricingMargin({super.key, required this.controller});

  @override
  State<Step3PricingMargin> createState() => _Step3PricingMarginState();
}

class _Step3PricingMarginState extends State<Step3PricingMargin> {
  late TextEditingController _customPerKwController;
  late TextEditingController _customPctController;
  late TextEditingController _customFixedController;

  static const List<double> perKwPresets = [3500, 4500, 5500, 6000, 8000];
  static const List<double> pctPresets = [5, 8, 10, 12, 15];
  static const List<double> fixedPresets = [10000, 20000, 30000, 50000];

  @override
  void initState() {
    super.initState();
    final ctrl = widget.controller;
    _customPerKwController = TextEditingController(
      text: ctrl.marginRatePerKw.toStringAsFixed(0),
    );
    _customPctController = TextEditingController(
      text: ctrl.marginRatePct.toStringAsFixed(0),
    );
    _customFixedController = TextEditingController(
      text: ctrl.marginFixed.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _customPerKwController.dispose();
    _customPctController.dispose();
    _customFixedController.dispose();
    super.dispose();
  }

  String _formatINR(double val) {
    final rounded = val.round();
    final str = rounded.abs().toString();
    if (str.length <= 3) {
      return (val < 0 ? '-₹ ' : '₹ ') + str;
    }
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    final formatted = '$buffer,$lastThree';
    return (val < 0 ? '-₹ ' : '₹ ') + formatted;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final totals = controller.finalTotals;
    final generation = controller.generation;
    final savings = controller.savings;
    final selectedModule = controller.selectedModule;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card matching Web STEP 1.3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_graph,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commercials & Margin',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turnkey package price, government subsidy & dealer margin',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'STEP 1.3',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. HIGHLIGHTED GREEN CARD: CENTRAL SUBSIDY CALCULATED
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_graph,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Central Subsidy Calculated',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary.withValues(alpha: 0.25),
                      size: 28,
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 20),

                // Base Package Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Solar Package (Base)',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${selectedModule?.brand ?? "APS"} (${selectedModule?.wattage ?? 550}W) • ${controller.panelCount} Modules • ${controller.selectedCapacityKw.toStringAsFixed(1)} kW',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatINR(controller.baseTurnkeyCost),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scope note
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Includes Tier-1 PV Modules, ${controller.selectedInverter?.capacityKw ?? controller.selectedCapacityKw} kW Inverter, Mounting Structure, BOS Cables, Switchgear & GST',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Channel Margin Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Channel Margin',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.marginMode == 'percent'
                                ? '${controller.marginRatePct.toStringAsFixed(0)}%'
                                : '${controller.effectiveMarginPercent}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '+ ${_formatINR(controller.dealerMarginInr)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Statutory GST Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Statutory GST (18%)',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Included',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Taxable Base: ${_formatINR(totals['taxableBase'] ?? 0)} • GST: ${_formatINR(totals['gstAmount'] ?? 0)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatINR(totals['gstAmount'] ?? 0),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra Outstation Transport (if toggled)
                if (controller.enableExtraTransport &&
                    controller.extraTransportAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Extra Outstation Transport',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '+ ${_formatINR(controller.extraTransportAmount)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(color: AppColors.border, height: 20),

                // Total Project Cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Project Cost',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Inclusive of GST, freight & liaisoning',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatINR(totals['totalAmount'] ?? 0),
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Central Government Subsidy
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'PM Surya Ghar Subsidy',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Central Govt.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Direct-to-bank account reimbursement',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '- ${_formatINR(controller.centralSubsidy)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Final Customer Payable Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NET EFFECTIVE INVESTMENT',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Final customer cost post-subsidy reimbursement',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            _formatINR(totals['netPayable'] ?? 0),
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Net',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Loan EMI Preview
                if (controller.isLoanSelected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance,
                              color: AppColors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Solar EMI',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amber,
                                  ),
                                ),
                                Text(
                                  '${controller.loanTenureMonths ~/ 12} Years (${controller.loanTenureMonths} Mos) • ${controller.selectedBank?.bankName ?? "SBI"}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${_formatINR(controller.monthlyLoanEmi)} / mo',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. INTERACTIVE COMMERCIALS CARD: CUSTOM DEALER MARGIN
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Dealer Margin',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatINR(controller.dealerMarginInr),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Segmented Mode Tabs: ₹/kW vs ₹ Fixed vs %
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildModeTab('per_kw', '₹ / kW'),
                      _buildModeTab('amount', '₹ Fixed'),
                      _buildModeTab('percent', '% Percent'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Mode-specific presets and input
                if (controller.marginMode == 'per_kw') ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: perKwPresets.map((rate) {
                      final isSel =
                          (controller.marginRatePerKw - rate).abs() < 1;
                      return InkWell(
                        onTap: () {
                          controller.setMarginRatePerKw(rate);
                          _customPerKwController.text = rate.toStringAsFixed(0);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '₹${rate.toStringAsFixed(0)}/kW',
                            style: AppTypography.bodySmall.copyWith(
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Custom ₹/kW:', style: AppTypography.bodySmall),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        height: 38,
                        child: TextField(
                          controller: _customPerKwController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: AppColors.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed =
                                double.tryParse(
                                  val.replaceAll(RegExp(r'\D'), ''),
                                ) ??
                                0.0;
                            controller.setMarginRatePerKw(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(= ${_formatINR(controller.dealerMarginInr)} total)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else if (controller.marginMode == 'percent') ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pctPresets.map((pct) {
                      final isSel =
                          (controller.marginRatePct - pct).abs() < 0.1;
                      return InkWell(
                        onTap: () {
                          controller.setMarginRatePct(pct);
                          _customPctController.text = pct.toStringAsFixed(0);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Custom %:', style: AppTypography.bodySmall),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        height: 38,
                        child: TextField(
                          controller: _customPctController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            suffixText: '%',
                            filled: true,
                            fillColor: AppColors.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed =
                                double.tryParse(
                                  val.replaceAll(RegExp(r'[^0-9.]'), ''),
                                ) ??
                                0.0;
                            controller.setMarginRatePct(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(= ${_formatINR(controller.dealerMarginInr)} total)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fixedPresets.map((amt) {
                      final isSel = (controller.marginFixed - amt).abs() < 1;
                      return InkWell(
                        onTap: () {
                          controller.setMarginFixed(amt);
                          _customFixedController.text = amt.toStringAsFixed(0);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '₹${(amt / 1000).toStringAsFixed(0)}k',
                            style: AppTypography.bodySmall.copyWith(
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Custom ₹:', style: AppTypography.bodySmall),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        height: 38,
                        child: TextField(
                          controller: _customFixedController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: AppColors.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed =
                                double.tryParse(
                                  val.replaceAll(RegExp(r'\D'), ''),
                                ) ??
                                0.0;
                            controller.setMarginFixed(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(color: AppColors.border, height: 24),

                // Telemetry footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spread: ${_formatINR(controller.currentMarginPerKw)} / kW (${controller.effectiveMarginPercent}%)',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: controller.isMarginExceeded
                                ? AppColors.rose
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Cap: ${_formatINR(controller.maxMarginCapPerKw)}/kW (Gold Tier)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: AppColors.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Confidential',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Cap Exceeded Alert
                if (controller.isMarginExceeded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.rose.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.rose,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tier Margin Cap Exceeded (${_formatINR(controller.currentMarginPerKw)}/kW > ${_formatINR(controller.maxMarginCapPerKw)}/kW)',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.rose,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your configured spread exceeds the approved threshold. This quotation will require HO compliance audit.',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. SOLAR GENERATION & ROI TELEMETRY
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.bolt,
                  title: 'Annual Generation',
                  value: '${generation['annualUnits']} units',
                  subtitle: '~${generation['monthlyUnits']} units/mo',
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.savings_outlined,
                  title: 'Annual Savings',
                  value: _formatINR(savings['annualSavings'] as double? ?? 0),
                  subtitle: 'Payback: ${savings['paybackText']}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. SOLAR LOAN BANK PARTNER TOGGLE
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.isLoanSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: controller.isLoanSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solar Bank Loan Option',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'PM Surya Ghar 7% Concessional Scheme',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: controller.isLoanSelected,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => controller.toggleLoan(val),
                    ),
                  ],
                ),
                if (controller.isLoanSelected) ...[
                  const Divider(color: AppColors.border, height: 20),
                  DropdownButtonFormField<SolarBankModel>(
                    initialValue: controller.selectedBank,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: (controller.catalog?.solarBanks ?? []).map((b) {
                      return DropdownMenuItem<SolarBankModel>(
                        value: b,
                        child: Text(
                          '${b.bankName} (${b.interestRate}%)',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.setBank(val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Monthly EMI',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        '${_formatINR(controller.monthlyLoanEmi)} / mo',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModeTab(String modeKey, String label) {
    final isSel = widget.controller.marginMode == modeKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.controller.setMarginMode(modeKey);
        },
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isSel ? Colors.white : AppColors.textSecondary,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
