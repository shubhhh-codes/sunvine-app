import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunvine_epc/core/network/api_result.dart';
import 'package:sunvine_epc/features/auth/domain/auth_models.dart';
import 'package:sunvine_epc/features/quotations/data/quotations_repository.dart';
import 'package:sunvine_epc/features/quotations/domain/models/catalog_models.dart';
import 'package:sunvine_epc/features/quotations/domain/models/quotation_model.dart';
import 'package:sunvine_epc/core/theme/components/sun_button.dart';
import 'package:sunvine_epc/core/theme/components/sun_card.dart';
import 'package:sunvine_epc/features/quotations/presentation/controllers/create_quotation_controller.dart';
import 'package:sunvine_epc/features/quotations/presentation/create_quotation_stepper_screen.dart';
import 'package:sunvine_epc/features/quotations/presentation/steps/step1_customer_discom.dart';
import 'package:sunvine_epc/features/quotations/presentation/steps/step2_solar_sizing.dart';

class MockQuotationsRepo implements IQuotationsRepository {
  @override
  Future<Result<CatalogBootstrapModel>> getBootstrapCatalog() async {
    return Result.success(
      const CatalogBootstrapModel(
        modules: [
          SolarModuleModel(
            id: 'mod_aps_550',
            brand: 'APS',
            model: 'APS 550W TOPCon',
            wattage: 550,
            ratePerWpInr: 24.2,
            technology: 'TOPCon Bifacial',
            cellType: 'Dual Glass',
            warrantyYears: 25,
          ),
          SolarModuleModel(
            id: 'mod_adani_550',
            brand: 'Adani',
            model: 'Adani 550W Mono PERC',
            wattage: 550,
            ratePerWpInr: 25.0,
            technology: 'Bifacial Mono PERC',
            cellType: 'Dual Glass',
            warrantyYears: 25,
          ),
        ],
        inverters: [
          SolarInverterModel(
            id: 'inv_solis_3_3',
            brand: 'Solis',
            model: 'Solis 3.3kW Single Phase',
            capacityKw: 3.3,
            basePriceInr: 32000,
            phase: 'Single Phase',
            warrantyYears: 5,
          ),
        ],
        solarBanks: [
          SolarBankModel(
            id: 'sbi_loan',
            bankName: 'State Bank of India',
            interestRate: 7.0,
            maxTenureMonths: 84,
          ),
        ],
        bosMatrix: [
          BosPricingSlabModel(
            capacitySlab: 3.3,
            panelBrand: 'APS',
            bosPricePerWp: 48.0,
            gstRate: 13.8,
          ),
        ],
        settings: SystemSettingsModel(),
      ),
    );
  }

  @override
  Future<Result<List<QuotationModel>>> getQuotations({
    int limit = 50,
    int offset = 0,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> saveQuotation(
    Map<String, dynamic> payload,
  ) async {
    return Result.success({'id': 'quote_123'});
  }

  @override
  Future<void> saveOfflineDraft(
    Map<String, dynamic> draft, {
    bool syncPending = false,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncDrafts() async => [];

  @override
  Future<void> markDraftSynced(
    String localId,
    String serverId,
    String shareToken,
  ) async {}

  @override
  Future<List<Map<String, dynamic>>> getAllDrafts() async => [];

  @override
  Future<void> deleteDraft(String id) async {}
}

void main() {
  group('CreateQuotationController Form Validation & Flow Tests', () {
    late CreateQuotationController controller;
    late DealerUser testUser;

    setUp(() {
      testUser = DealerUser(
        id: 'usr_test_1',
        dealerCode: 'SV-DLR-0104',
        firmName: 'Sunvine Energy Solutions',
        contactPerson: 'Authorized Dealer',
        mobile: '9876543210',
        city: 'Rajkot',
        state: 'Gujarat',
        discom: 'PGVCL',
        tier: 'gold',
        maxMarginCapPerKw: 6000.0,
        assignedStaffId: 'staff_1',
        category: 'Margin Based',
        pricingConfig: const {},
      );

      controller = CreateQuotationController(
        repository: MockQuotationsRepo(),
        currentUser: testUser,
      );
    });

    test('Initial Step 1 state has empty errors', () {
      expect(controller.currentStep, 0);
      expect(controller.nameError, isNull);
      expect(controller.phoneError, isNull);
      expect(controller.locationError, isNull);
      expect(controller.hasStep1Attempted, false);
    });

    test(
      'validateStep1 rejects completely empty inputs and sets readable errors',
      () {
        final isValid = controller.validateStep1();
        expect(isValid, false);
        expect(controller.hasStep1Attempted, true);
        expect(controller.nameError, 'Please enter customer full name');
        expect(controller.phoneError, 'Please enter mobile number');
        expect(
          controller.locationError,
          'Please enter installation city or pincode',
        );
      },
    );

    test('validateStep1 rejects whitespace-only inputs', () {
      controller.setCustomerName('    ');
      controller.setCustomerLocation('   ');
      controller.setCustomerPhone('          ');

      final isValid = controller.validateStep1();
      expect(isValid, false);
      expect(controller.nameError, 'Please enter customer full name');
      expect(controller.phoneError, 'Please enter mobile number');
      expect(
        controller.locationError,
        'Please enter installation city or pincode',
      );
    });

    test('validateStep1 rejects phone with less than 10 digits', () {
      controller.setCustomerName('Rajesh Patel');
      controller.setCustomerLocation('Rajkot 360005');
      controller.setCustomerPhone('98765'); // only 5 digits

      final isValid = controller.validateStep1();
      expect(isValid, false);
      expect(controller.nameError, isNull);
      expect(controller.phoneError, 'Mobile number must be exactly 10 digits');
      expect(controller.locationError, isNull);
    });

    test('Dynamic error clearing on keystroke after validation attempted', () {
      // Trigger errors first
      controller.validateStep1();
      expect(controller.nameError, isNotNull);
      expect(controller.phoneError, isNotNull);
      expect(controller.locationError, isNotNull);

      // User types valid name -> name error clears immediately
      controller.setCustomerName('Anil Ambani');
      expect(controller.nameError, isNull);

      // User types valid 10-digit phone -> phone error clears
      controller.setCustomerPhone('9825012345');
      expect(controller.phoneError, isNull);

      // User types valid location -> location error clears
      controller.setCustomerLocation('Ahmedabad');
      expect(controller.locationError, isNull);

      // Now validateStep1 passes
      expect(controller.validateStep1(), true);
    });

    test('nextStep() is blocked on Step 1 if validation fails', () {
      expect(controller.currentStep, 0);
      final progressed = controller.nextStep();
      expect(progressed, false);
      expect(controller.currentStep, 0); // Stays on Step 1
      expect(controller.nameError, isNotNull);
    });

    test('nextStep() advances to Step 2 when Step 1 is valid, and previousStep preserves data', () async {
      controller.setCustomerName('Bhavik Mehta');
      controller.setCustomerPhone('9898098980');
      controller.setCustomerLocation('Surat 395007');

      final progressed = controller.nextStep();
      expect(progressed, true);
      expect(controller.currentStep, 1);

      // Wait for debounce period (300ms)
      await Future.delayed(const Duration(milliseconds: 350));

      // Move backward to Step 1
      controller.previousStep();
      expect(controller.currentStep, 0);
      expect(controller.customerName, 'Bhavik Mehta');
      expect(controller.customerPhone, '9898098980');
      expect(controller.customerLocation, 'Surat 395007');
    });

    test(
      'Step 2 solar sizing correctly calculates panel count and rooftop area',
      () {
        controller.setCapacityKw(3.3);
        expect(controller.panelCount, 6);
        expect(controller.totalKwp, 3.3);
        expect(controller.rooftopAreaSqFt, (3.3 * 64).round());

        // Change capacity to 5.0 kW
        controller.setCapacityKw(5.0);
        expect(controller.panelCount, 9);
        expect(controller.rooftopAreaSqFt, (5.0 * 64).round());
      },
    );

    test('Step 3 triple margin modes calculate dealerMarginInr correctly', () {
      controller.setCapacityKw(3.0);

      // 1. per_kw mode: ₹4,000/kW * 3.0 kW = ₹12,000
      controller.setMarginMode('per_kw');
      controller.setMarginRatePerKw(4000.0);
      expect(controller.dealerMarginInr, 12000.0);
      expect(controller.currentMarginPerKw, 4000.0);
      expect(controller.isMarginExceeded, false);

      // Exceed cap: ₹7,000/kW > 6,000 cap
      controller.setMarginRatePerKw(7000.0);
      expect(controller.currentMarginPerKw, 7000.0);
      expect(controller.isMarginExceeded, true);

      // 2. amount (fixed) mode: ₹25,000
      controller.setMarginMode('amount');
      controller.setMarginFixed(25000.0);
      expect(controller.dealerMarginInr, 25000.0);

      // 3. percent mode: 10%
      controller.setMarginMode('percent');
      controller.setMarginRatePct(10.0);
      final expectedPctMargin = (controller.baseTurnkeyCost * 0.10)
          .roundToDouble();
      expect(controller.dealerMarginInr, expectedPctMargin);
    });

    test('Step 3 extra outstation transport is added to totalAmount and netPayable', () {
      controller.setCapacityKw(3.3);
      controller.setMarginMode('per_kw');
      controller.setMarginRatePerKw(4000.0);

      final totalsWithoutTransport = controller.finalTotals;
      final totalBefore = totalsWithoutTransport['totalAmount']!;
      final netBefore = totalsWithoutTransport['netPayable']!;

      controller.toggleExtraTransport(true);
      controller.setExtraTransportAmount(4500.0);

      final totalsWithTransport = controller.finalTotals;
      expect(totalsWithTransport['totalAmount'], totalBefore + 4500.0);
      expect(totalsWithTransport['netPayable'], netBefore + 4500.0);
    });

    test('Subsidy calculation is zero for Commercial projectType', () {
      controller.setCapacityKw(3.3);
      expect(controller.projectType, 'Residential');
      expect(controller.centralSubsidy, 78000.0);

      controller.setProjectType('Commercial');
      expect(controller.centralSubsidy, 0.0);
    });

    test(
      'step1ValidationEpoch increments on each failed validateStep1() attempt',
      () {
        expect(controller.step1ValidationEpoch, 0);

        // Attempt 1 with empty fields
        final firstCheck = controller.validateStep1();
        expect(firstCheck, false);
        expect(controller.step1ValidationEpoch, 1);

        // Attempt 2 with still invalid fields
        final secondCheck = controller.validateStep1();
        expect(secondCheck, false);
        expect(controller.step1ValidationEpoch, 2);

        // Fill valid data
        controller.setCustomerName('Harish Verma');
        controller.setCustomerPhone('9876543210');
        controller.setCustomerLocation('Rajkot 360001');

        // Attempt 3 with valid fields
        final thirdCheck = controller.validateStep1();
        expect(thirdCheck, true);
        // Epoch remains unchanged on successful validation
        expect(controller.step1ValidationEpoch, 2);
      },
    );

    test('Solar Loan option is guarded and preserves Cash Case', () {
      expect(controller.paymentMode, 'CASH');
      expect(controller.isLoanSelected, false);

      // Attempting to set LOAN mode is guarded while in development
      controller.setPaymentMode('LOAN');
      expect(controller.paymentMode, 'CASH');
      expect(controller.isLoanSelected, false);

      // Explicitly setting CASH succeeds
      controller.setPaymentMode('CASH');
      expect(controller.paymentMode, 'CASH');
    });

    test(
      'Rapid repeated calls to nextStep() do not advance multiple steps',
      () {
        controller.setCustomerName('Kiran Rao');
        controller.setCustomerPhone('9876543210');
        controller.setCustomerLocation('Vadodara');

        expect(controller.currentStep, 0);
        final first = controller.nextStep();
        expect(first, true);
        expect(controller.currentStep, 1);
        expect(controller.isNavigating, true);

        // Immediate second call while isNavigating is true must return false
        final second = controller.nextStep();
        expect(second, false);
        expect(controller.currentStep, 1);
      },
    );

    testWidgets(
      'Step1CustomerDiscom renders inputs, displays errors on validation, and clears them on correction',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Step1CustomerDiscom(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Verify all field labels are present
        expect(find.text('Customer Details'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText && w.text.toPlainText().contains('Customer Name'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText && w.text.toPlainText().contains('Mobile Number'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('Installation City / Pincode'),
          ),
          findsOneWidget,
        );
        expect(find.text('Cash Case'), findsOneWidget);
        expect(find.text('Solar Loan (EMI)'), findsOneWidget);

        // Initially no validation errors should be displayed
        expect(find.text('Please enter customer full name'), findsNothing);
        expect(find.text('Please enter mobile number'), findsNothing);
        expect(
          find.text('Please enter installation city or pincode'),
          findsNothing,
        );

        // Trigger validation failure via controller
        controller.validateStep1();
        await tester.pumpAndSettle();

        // Error texts must now be visible
        expect(find.text('Please enter customer full name'), findsOneWidget);
        expect(find.text('Please enter mobile number'), findsOneWidget);
        expect(
          find.text('Please enter installation city or pincode'),
          findsOneWidget,
        );

        // Type valid name in name field
        await tester.enterText(find.byType(TextFormField).at(0), 'Mahesh Shah');
        await tester.pumpAndSettle();

        // Name error should clear, while phone and location errors remain
        expect(find.text('Please enter customer full name'), findsNothing);
        expect(find.text('Please enter mobile number'), findsOneWidget);
        expect(
          find.text('Please enter installation city or pincode'),
          findsOneWidget,
        );

        // Type 5 digits into mobile field -> error updates to 10 digits required
        await tester.enterText(find.byType(TextFormField).at(1), '98765');
        await tester.pumpAndSettle();
        expect(
          find.text('Mobile number must be exactly 10 digits'),
          findsOneWidget,
        );

        // Complete 10 digits
        await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
        await tester.pumpAndSettle();
        expect(
          find.text('Mobile number must be exactly 10 digits'),
          findsNothing,
        );
        expect(find.text('Please enter mobile number'), findsNothing);

        // Enter location
        await tester.enterText(find.byType(TextFormField).at(2), 'Rajkot');
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter installation city or pincode'),
          findsNothing,
        );

        // Verify Solar Loan tap triggers tooltip without altering payment mode
        await tester.tap(find.text('Solar Loan (EMI)'));
        await tester.pumpAndSettle();
        expect(controller.paymentMode, 'CASH');
        expect(find.textContaining('COMING SOON'), findsOneWidget);
      },
    );
  });

  group('SunButton & SunCard Micro-Interaction Tests', () {
    testWidgets('SunButton scales smoothly on tap and triggers callback', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SunButton(
                text: 'Continue',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);

      // Verify tap executes callback
      await tester.tap(find.byType(SunButton));
      await tester.pumpAndSettle();
      expect(tapped, true);
    });

    testWidgets(
      'SunButton in loading state displays indicator and ignores taps',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SunButton(
                  text: 'Submit',
                  isLoading: true,
                  onPressed: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.byType(SunButton));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tapped, false);
      },
    );

    testWidgets('SunCard handles tap callbacks and animates states', (
      tester,
    ) async {
      bool cardTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SunCard(
                onTap: () => cardTapped = true,
                child: const Text('Solar Panel Spec'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Solar Panel Spec'), findsOneWidget);
      await tester.tap(find.text('Solar Panel Spec'));
      await tester.pumpAndSettle();
      expect(cardTapped, true);
    });
  });

  group('Responsive Layout & Stepper Constraint Tests', () {
    testWidgets(
      'CreateQuotationStepperScreen constrains max-width to 720 on wide screens',
      (tester) async {
        // Set wide desktop/tablet dimensions: 1200x800
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testUser = DealerUser(
          id: 'usr_test_wide',
          dealerCode: 'SV-DLR-0104',
          firmName: 'Sunvine Energy Solutions',
          contactPerson: 'Authorized Dealer',
          mobile: '9876543210',
          city: 'Rajkot',
          state: 'Gujarat',
          discom: 'PGVCL',
          tier: 'gold',
          maxMarginCapPerKw: 6000.0,
          assignedStaffId: 'staff_1',
          category: 'Margin Based',
          pricingConfig: const {},
        );

        final controller = CreateQuotationController(
          repository: MockQuotationsRepo(),
          currentUser: testUser,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CreateQuotationStepperScreen(controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        // Find ConstrainedBox with maxWidth == 720
        final constrainedBoxes = tester.widgetList<ConstrainedBox>(
          find.byWidgetPredicate(
            (w) => w is ConstrainedBox && w.constraints.maxWidth == 720.0,
          ),
        );
        expect(constrainedBoxes.isNotEmpty, true);
      },
    );

    testWidgets(
      'Step2SolarSizing renders gracefully on narrow viewports (320px width)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testUser = DealerUser(
          id: 'usr_test_narrow',
          dealerCode: 'SV-DLR-0104',
          firmName: 'Sunvine Energy Solutions',
          contactPerson: 'Authorized Dealer',
          mobile: '9876543210',
          city: 'Rajkot',
          state: 'Gujarat',
          discom: 'PGVCL',
          tier: 'gold',
          maxMarginCapPerKw: 6000.0,
          assignedStaffId: 'staff_1',
          category: 'Margin Based',
          pricingConfig: const {},
        );

        final controller = CreateQuotationController(
          repository: MockQuotationsRepo(),
          currentUser: testUser,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Step2SolarSizing(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify key elements exist and no RenderFlex overflow was thrown
        expect(find.textContaining('System Capacity (kW)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
