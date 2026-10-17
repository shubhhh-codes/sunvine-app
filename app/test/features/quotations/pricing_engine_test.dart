import 'package:flutter_test/flutter_test.dart';
import 'package:sunvine_epc/features/quotations/domain/services/pricing_engine.dart';

void main() {
  group('PricingEngine Tests', () {
    test('calculateSubsidy matches PM Surya Ghar slabs', () {
      // 1 kW: 30,000
      expect(PricingEngine.calculateSubsidy(capacityKw: 1.0), 30000.0);
      // 2 kW: 60,000
      expect(PricingEngine.calculateSubsidy(capacityKw: 2.0), 60000.0);
      // 3 kW: 60,000 + 18,000 = 78,000
      expect(PricingEngine.calculateSubsidy(capacityKw: 3.0), 78000.0);
      // 5 kW: capped at 78,000
      expect(PricingEngine.calculateSubsidy(capacityKw: 5.0), 78000.0);
      // Commercial: 0
      expect(PricingEngine.calculateSubsidy(capacityKw: 5.0, projectType: 'Commercial'), 0.0);
    });

    test('isPanelWattageCompatible and getPanelQuantityForCapacity', () {
      // 3.3 kW with 550W (3300W / 550W = 6 exact modules)
      expect(PricingEngine.isPanelWattageCompatible(3.3, 550), true);
      expect(PricingEngine.getPanelQuantityForCapacity(3.3, 550), 6);

      // 3.3 kW with 585W (3300 / 585 = 5.64, diff = 3510 - 3300 = 210W > 5W tolerance)
      expect(PricingEngine.isPanelWattageCompatible(3.3, 585), false);
    });

    test('validateDealerMargin enforces strict cap', () {
      final resSafe = PricingEngine.validateDealerMargin(
        marginInr: 10000.0,
        capacityKw: 3.0,
        maxCapPerKw: 4500.0,
      );
      expect(resSafe['isMarginExceeded'], false);
      expect(resSafe['effectiveMargin'], 10000.0);

      final resExceeded = PricingEngine.validateDealerMargin(
        marginInr: 20000.0, // 20,000 / 3 = 6666 > 4500
        capacityKw: 3.0,
        maxCapPerKw: 4500.0,
      );
      expect(resExceeded['isMarginExceeded'], true);
      expect(resExceeded['effectiveMargin'], 13500.0); // 3 * 4500
    });

    test('calcFinalTotals calculates totalAmount and netPayable with discount cap', () {
      final totals = PricingEngine.calcFinalTotals(
        grossTurnkeyCost: 150000.0,
        dealerMarginInr: 13500.0,
        discountAmount: 5000.0,
        subsidyAmount: 78000.0,
        maxDiscountPct: 5.0,
      );

      // totalAmount = 150000 + 13500 - 5000 = 158500
      expect(totals['totalAmount'], 158500.0);
      // netPayable = 158500 - 78000 = 80500
      expect(totals['netPayable'], 80500.0);
    });

    test('calculateGenerationUnits and calculateSavingsAndPayback', () {
      final gen = PricingEngine.calculateGenerationUnits(capacityKw: 3.0);
      expect(gen['annualUnits'], 4320); // 3 * 1440
      expect(gen['monthlyUnits'], 360); // 4320 / 12

      final savings = PricingEngine.calculateSavingsAndPayback(
        netPayable: 80500.0,
        annualUnits: 4320,
        tariff: 6.67,
      );
      expect(savings['annualSavings'], 28814.0); // 4320 * 6.67 rounded
      expect(savings['paybackYears'], 2.8); // 80500 / 28814 = 2.793 -> 2.8
    });
  });
}
