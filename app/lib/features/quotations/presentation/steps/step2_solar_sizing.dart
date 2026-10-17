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

  @override
  void initState() {
    super.initState();
    _transportController = TextEditingController(
      text: widget.controller.extraTransportAmount > 0
          ? widget.controller.extraTransportAmount.toStringAsFixed(0)
          : '',
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card matching Reference STEP 1.2
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.solar_power_outlined,
                    color: AppColors.textSecondary,
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
                          fontSize: 16,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          ),
          const SizedBox(height: 14),

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
                                        child: Text(
                                          '${kw.toStringAsFixed(kw == kw.roundToDouble() ? 0 : 1)} kW System',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
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
          const SizedBox(height: 14),

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
                                      ? '${selectedModule.brand} (${selectedModule.model.isNotEmpty ? selectedModule.model : "${selectedModule.wattage}W ${selectedModule.technology}"})'
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
                                              '${mod.brand} (${mod.model.isNotEmpty ? mod.model : "${mod.wattage}W ${mod.technology}"})',
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
                                              '${mod.wattage}W • ${mod.cellType} • ${mod.technology}',
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
          const SizedBox(height: 14),

          // 3. AUTO-GENERATED PLANT CAPACITY & HARDWARE TELEMETRY BANNER (SIDE-BY-SIDE MATCHING REFERENCE)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;

                final telemetryLeft = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
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
                              Text(
                                '${controller.panelCount} Panels × ${selectedModule?.wattage ?? 550}W (${selectedModule?.brand ?? "APS 550W"})',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                '${selectedKw.toStringAsFixed(selectedKw == selectedKw.roundToDouble() ? 0 : 1)} kW System',
                                style: AppTypography.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '(${controller.totalKwp} kWp)',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final telemetryRight = Column(
                  crossAxisAlignment: isCompact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rooftop Area Required',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Shadow-free roof space',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~${controller.rooftopAreaSqFt} Sq. Ft.',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      telemetryLeft,
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      telemetryRight,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: telemetryLeft),
                    Container(
                      height: 44,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    Expanded(flex: 2, child: telemetryRight),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4. PROJECT SCHEME & SUBSIDY ELIGIBILITY
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 500;

                final infoWidget = Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Project Scheme & Subsidy Eligibility',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Residential (PM Surya Ghar Subsidy up to ₹78,000) or Commercial/Industrial',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final dropdownWidget = Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.projectType,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Residential',
                          child: Text(
                            'Residential (PM Surya Ghar Subsidy Eligible)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Commercial',
                          child: Text(
                            'Commercial / Industrial (No Subsidy)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          controller.setProjectType(val);
                        }
                      },
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoWidget,
                      const SizedBox(height: 10),
                      dropdownWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: infoWidget),
                    const SizedBox(width: 14),
                    SizedBox(width: 290, child: dropdownWidget),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 5. ADD TRANSPORT / FREIGHT CHARGE TOGGLE
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: controller.enableExtraTransport
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: controller.enableExtraTransport
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Add Transport / Freight Charge',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (controller.enableExtraTransport &&
                                  controller.extraTransportAmount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '+ ₹${controller.extraTransportAmount.toStringAsFixed(0)}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Toggle ON to manually include outstation doorstep transport / freight charges in this quotation & PDF.',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: controller.enableExtraTransport,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      onChanged: (val) => controller.toggleExtraTransport(val),
                    ),
                  ],
                ),
                if (controller.enableExtraTransport) ...[
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Manual Extra Transport Charge (₹):',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        height: 40,
                        child: TextField(
                          controller: _transportController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
