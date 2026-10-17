import 'dart:math' as math;
import '../models/catalog_models.dart';

/// Single source of truth for all Sunvine Solar financial and engineering math.
/// Parity guaranteed with web engine (`src/shared/pricing/calculations.js`).
class PricingEngine {
  static const double defaultSubsidySlab1Rate = 30000.0;
  static const double defaultSubsidySlab2Rate = 18000.0;
  static const double defaultSubsidyCap = 78000.0;
  static const double defaultSpecificYield = 1440.0;
  static const double defaultTariffPerUnit = 6.67;
  static const double defaultSolarLoanRatePa = 8.5;

  /// PM Surya Ghar Central Residential Subsidy Calculation
  /// Tier 1: ≤ 2 kW @ slab1Rate (default ₹30,000/kW)
  /// Tier 2: 2 to 3 kW @ slab2Rate (default ₹18,000/kW)
  /// Cap: strictly capped at cap (default ₹78,000)
  static double calculateSubsidy({
    required double capacityKw,
    String projectType = 'Residential',
    SubsidySettingsModel subsidySettings = const SubsidySettingsModel(),
  }) {
    if (capacityKw <= 0 || projectType.toLowerCase() == 'commercial') {
      return 0.0;
    }

    final s1 = subsidySettings.slab1Rate;
    final s2 = subsidySettings.slab2Rate;
    final cap = subsidySettings.cap;
    final bp = subsidySettings.breakpointKw;

    // Tier 1: first 2 kW @ s1
    final tier1 = math.min(capacityKw, 2.0) * s1;
    // Tier 2: capacity between 2 and breakpoint (3 kW) @ s2
    final tier2 = math.max(0.0, math.min(capacityKw, bp) - 2.0) * s2;

    final total = tier1 + tier2;
    return math.min(total.roundToDouble(), cap);
  }

  /// Whole number of panels multiplied by wattage must equal system capacity within <= 5W tolerance
  static bool isPanelWattageCompatible(double capacityKw, int panelWattage) {
    if (capacityKw <= 0 || panelWattage <= 0) return false;
    final totalWatts = (capacityKw * 1000).round();
    final exactModules = totalWatts / panelWattage;
    final roundedModules = exactModules.round();
    if (roundedModules < 1) return false;

    final wattDiff = ((roundedModules * panelWattage) - totalWatts).abs();
    return wattDiff <= 5;
  }

  /// Calculates number of panels required for a given system capacity
  static int getPanelQuantityForCapacity(double capacityKw, int panelWattage) {
    if (capacityKw <= 0 || panelWattage <= 0) return 0;
    return ((capacityKw * 1000).round() / panelWattage).round();
  }

  /// GST Calculation per item
  static Map<String, double> calcItemGST({
    required double baseAmount,
    required int gstRate,
    bool isInterState = false,
  }) {
    final base = baseAmount.roundToDouble();
    final gstAmount = (base * gstRate / 100).roundToDouble();
    final half = (gstAmount / 2).roundToDouble();

    return {
      'baseAmount': base,
      'gstAmount': gstAmount,
      'cgst': isInterState ? 0.0 : half,
      'sgst': isInterState ? 0.0 : gstAmount - half,
      'igst': isInterState ? gstAmount : 0.0,
      'totalWithGst': base + gstAmount,
    };
  }

  /// BOM Totals Aggregation
  static Map<String, dynamic> calcBOMTotals({
    required List<BomItemModel> items,
    bool isInterState = false,
  }) {
    double totalTaxableBase = 0.0;
    double totalGstAmount = 0.0;
    double grossTurnkeyCost = 0.0;
    double cgstTotal = 0.0;
    double sgstTotal = 0.0;
    double igstTotal = 0.0;

    final calculatedItems = <BomItemModel>[];

    for (final item in items) {
      final baseAmount = (item.qty * item.rate).roundToDouble();
      final gstInfo = calcItemGST(
        baseAmount: baseAmount,
        gstRate: item.gstRate,
        isInterState: isInterState,
      );

      final gstAmount = gstInfo['gstAmount']!;
      final itemTotal = gstInfo['totalWithGst']!;

      totalTaxableBase += baseAmount;
      totalGstAmount += gstAmount;
      grossTurnkeyCost += itemTotal;
      cgstTotal += gstInfo['cgst']!;
      sgstTotal += gstInfo['sgst']!;
      igstTotal += gstInfo['igst']!;

      calculatedItems.add(BomItemModel(
        id: item.id,
        name: item.name,
        category: item.category,
        unit: item.unit,
        qty: item.qty,
        rate: item.rate,
        gstRate: item.gstRate,
        baseAmount: baseAmount,
        gstAmount: gstAmount,
        totalWithGst: itemTotal,
      ));
    }

    return {
      'items': calculatedItems,
      'totalTaxableBase': totalTaxableBase,
      'totalGstAmount': totalGstAmount,
      'grossTurnkeyCost': grossTurnkeyCost,
      'cgstTotal': cgstTotal,
      'sgstTotal': sgstTotal,
      'igstTotal': igstTotal,
    };
  }

  /// Dealer Margin Validation & Cap Enforcement
  static Map<String, dynamic> validateDealerMargin({
    required double marginInr,
    required double capacityKw,
    required double maxCapPerKw,
  }) {
    if (capacityKw <= 0) {
      return {'marginPerKw': 0.0, 'isMarginExceeded': false, 'effectiveMargin': 0.0};
    }

    final marginPerKw = (marginInr / capacityKw).roundToDouble();
    final isMarginExceeded = marginPerKw > maxCapPerKw;
    final effectiveMargin = isMarginExceeded
        ? (maxCapPerKw * capacityKw).roundToDouble()
        : marginInr.roundToDouble();

    return {
      'marginPerKw': marginPerKw,
      'isMarginExceeded': isMarginExceeded,
      'effectiveMargin': effectiveMargin,
    };
  }

  /// Final Quotation Financial Summary
  static Map<String, double> calcFinalTotals({
    required double grossTurnkeyCost,
    required double dealerMarginInr,
    double discountAmount = 0.0,
    double subsidyAmount = 0.0,
    double maxDiscountPct = 5.0,
  }) {
    double effectiveDiscount = math.max(0.0, discountAmount);
    final maxAllowedDiscount = (grossTurnkeyCost * (maxDiscountPct / 100)).roundToDouble();

    if (effectiveDiscount > maxAllowedDiscount) {
      effectiveDiscount = maxAllowedDiscount;
    }

    final totalAmount = math.max(0.0, (grossTurnkeyCost + dealerMarginInr - effectiveDiscount).roundToDouble());
    final netPayable = math.max(0.0, (totalAmount - subsidyAmount).roundToDouble());

    return {
      'totalAmount': totalAmount,
      'netPayable': netPayable,
      'discountAmount': effectiveDiscount,
    };
  }

  /// Solar Generation Estimator (Units)
  static Map<String, dynamic> calculateGenerationUnits({
    required double capacityKw,
    double specificYield = defaultSpecificYield,
  }) {
    if (capacityKw <= 0) {
      return {'annualUnits': 0, 'monthlyUnits': 0, 'dailyUnits': 0.0};
    }

    final annualUnits = (capacityKw * specificYield).round();
    final monthlyUnits = (annualUnits / 12).round();
    final dailyUnits = double.parse((annualUnits / 365).toStringAsFixed(1));

    return {
      'annualUnits': annualUnits,
      'monthlyUnits': monthlyUnits,
      'dailyUnits': dailyUnits,
    };
  }

  /// Electricity Bill Savings & Payback Duration
  static Map<String, dynamic> calculateSavingsAndPayback({
    required double netPayable,
    required int annualUnits,
    double tariff = defaultTariffPerUnit,
  }) {
    if (netPayable <= 0 || annualUnits <= 0) {
      return {
        'annualSavings': 0.0,
        'monthlySavings': 0.0,
        'paybackYears': 0.0,
        'paybackText': '0.0 Years',
      };
    }

    final annualSavings = (annualUnits * tariff).roundToDouble();
    final monthlySavings = (annualSavings / 12).roundToDouble();
    final paybackYears = double.parse((netPayable / annualSavings).toStringAsFixed(1));

    return {
      'annualSavings': annualSavings,
      'monthlySavings': monthlySavings,
      'paybackYears': paybackYears,
      'paybackText': '$paybackYears Years',
    };
  }

  /// Reducing Balance Solar Loan EMI
  static double calcEMI({
    required double principal,
    double annualRatePct = 7.0,
    int tenureMonths = 84,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0.0;
    final r = (annualRatePct / 12) / 100;
    if (r == 0) return (principal / tenureMonths).roundToDouble();

    final emi = principal * r * math.pow(1 + r, tenureMonths) / (math.pow(1 + r, tenureMonths) - 1);
    return emi.roundToDouble();
  }
}
