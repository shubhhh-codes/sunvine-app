import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/create_quotation_controller.dart';
import '../../domain/services/pricing_engine.dart';

class Step2SolarSizing extends StatefulWidget {
  final CreateQuotationController controller;

  const Step2SolarSizing({super.key, required this.controller});

  @override
  State<Step2SolarSizing> createState() => _Step2SolarSizingState();
}

class _Step2SolarSizingState extends State<Step2SolarSizing> {
  bool _kwDropdownOpen = false;
  bool _makeDropdownOpen = false;
  late TextEditingController _transportController;

  static const List<double> standardKws = [
    2.0,
    2.5,
    3.0,
    3.3,
    4.0,
    5.0,
    6.0,
    8.0,
    10.0,
  ];
  static const List<String> structures = [
    'Standard Rooftop',
    'Elevated Super Structure',
    'High Rise',
  ];

  @override
  void initState() {
    super.initState();
    _transportController = TextEditingController(
      text: widget.controller.extraTransportAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _transportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selectedKw = controller.selectedCapacityKw;
    final selectedModule = controller.selectedModule;
    final compatibleModules = controller.compatibleModules;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card matching Web STEP 1.2
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
                  Icons.electric_bolt,
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
                      'System Details',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'System capacity slab, manufacturer make & equipment configuration',
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
                  'STEP 1.2',
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
          const SizedBox(height: 20),

          // 1. SYSTEM CAPACITY (kW) SELECTOR — CUSTOM SMART DROPDOWN
          Container(
            padding: const EdgeInsets.all(14),
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
                    Flexible(
                      child: Text(
                        '1. System Capacity (kW) *',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${controller.panelCount} Panels Required',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Trigger Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _kwDropdownOpen = !_kwDropdownOpen;
                      _makeDropdownOpen = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kwDropdownOpen
                            ? AppColors.primary
                            : AppColors.border,
                        width: _kwDropdownOpen ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.speed,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  '${selectedKw.toStringAsFixed(selectedKw == selectedKw.roundToDouble() ? 0 : 1)} kW System — ${controller.panelCount} Panels',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _kwDropdownOpen
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: _kwDropdownOpen
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),

                // Dropdown Menu
                if (_kwDropdownOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: standardKws.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final kw = standardKws[index];
                        final isSelected = (selectedKw - kw).abs() < 0.05;
                        final reqPanels =
                            PricingEngine.getPanelQuantityForCapacity(
                              kw,
                              selectedModule?.wattage ?? 550,
                            );

                        return InkWell(
                          onTap: () {
                            controller.setCapacityKw(kw);
                            setState(() {
                              _kwDropdownOpen = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${kw.toStringAsFixed(kw == kw.roundToDouble() ? 0 : 1)} kW System',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    '$reqPanels Panels',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. SOLAR PANEL SELECTION — CUSTOM SMART DROPDOWN
          Container(
            padding: const EdgeInsets.all(14),
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
                    Flexible(
                      child: Text(
                        '2. Select Solar Panel *',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${compatibleModules.length} Compatible Models',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Trigger Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _makeDropdownOpen = !_makeDropdownOpen;
                      _kwDropdownOpen = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _makeDropdownOpen
                            ? AppColors.primary
                            : AppColors.border,
                        width: _makeDropdownOpen ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.solar_power,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedModule != null
                                      ? '${selectedModule.brand} ${selectedModule.wattage}W (${selectedModule.technology})'
                                      : '-- Select Compatible Solar Panel --',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _makeDropdownOpen
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: _makeDropdownOpen
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),

                // Dropdown Menu
                if (_makeDropdownOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: compatibleModules.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final mod = compatibleModules[index];
                        final isSelected = selectedModule?.id == mod.id;
                        final reqPanels =
                            PricingEngine.getPanelQuantityForCapacity(
                              selectedKw,
                              mod.wattage,
                            );

                        return InkWell(
                          onTap: () {
                            controller.setModule(mod);
                            setState(() {
                              _makeDropdownOpen = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${mod.brand} ${mod.wattage}W',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${mod.brand} • ${mod.technology}',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '$reqPanels Panels',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. AUTO-GENERATED PLANT CAPACITY & HARDWARE TELEMETRY BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.electric_bolt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'AUTO-GENERATED PLANT CAPACITY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${controller.panelCount} Panels × ${selectedModule?.wattage ?? 550}W (${selectedModule?.brand ?? "APS"})',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${selectedKw.toStringAsFixed(1)} kW System (${controller.totalKwp} kWp)',
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rooftop Area Required',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Shadow-free roof space',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '~${controller.rooftopAreaSqFt} Sq. Ft.',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. PROJECT SCHEME & SUBSIDY ELIGIBILITY
          Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.apartment,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Scheme & Subsidy Eligibility',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Residential (PM Surya Ghar Subsidy up to ₹78,000) or Commercial',
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: controller.projectType,
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
                  items: const [
                    DropdownMenuItem(
                      value: 'Residential',
                      child: Text(
                        'Residential (PM Surya Ghar Subsidy Eligible)',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Commercial',
                      child: Text(
                        'Commercial / Industrial (Accelerated Depr.)',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.setProjectType(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. EXTRA OUTSTATION TRANSPORT / FREIGHT CHARGE TOGGLE
          Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extra Outstation Freight',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Enable if delivery is outside standard logistics hub',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: controller.enableExtraTransport,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => controller.toggleExtraTransport(val),
                    ),
                  ],
                ),
                if (controller.enableExtraTransport) ...[
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      Text(
                        'Amount (₹):',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        height: 40,
                        child: TextField(
                          controller: _transportController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
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
                            controller.setExtraTransportAmount(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. MOUNTING STRUCTURE TYPE
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mounting Structure Elevation',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: structures.map((s) {
                    final isSel = controller.structureType == s;
                    return InkWell(
                      onTap: () => controller.setStructureType(s),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          s,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSel
                                ? AppColors.primary
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7. INVERTER & BOS BREAKDOWN
          Container(
            padding: const EdgeInsets.all(14),
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
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Included Inverter & Turnkey BOS',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildSpecRow(
                  'Inverter',
                  '${controller.selectedInverter?.brand ?? "Solis/Growatt"} ${selectedKw.toStringAsFixed(1)}kW On-Grid',
                ),
                _buildSpecRow(
                  'Structure',
                  'Hot Dip Galvanized Iron (HDGI) - ${controller.structureType}',
                ),
                _buildSpecRow(
                  'Protection',
                  'ACDB, DCDB & Lightning Protection System',
                ),
                _buildSpecRow(
                  'Cables',
                  '4 sq mm UV-Resistant Solar DC Cables & Conduits',
                ),
                _buildSpecRow(
                  'Installation',
                  'Turnkey Erection, DISCOM Net Metering & Commissioning',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
