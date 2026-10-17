import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sunvine_epc/features/auth/domain/auth_models.dart';
import 'package:sunvine_epc/features/quotations/data/quotations_repository.dart';
import 'package:sunvine_epc/features/quotations/domain/models/catalog_models.dart';
import 'package:sunvine_epc/features/quotations/domain/services/pricing_engine.dart';

class CreateQuotationController extends ChangeNotifier {
  final IQuotationsRepository repository;
  final DealerUser currentUser;

  bool _isLoading = true;
  String? _errorMessage;
  CatalogBootstrapModel? _catalog;

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Customer Details
  String _customerName = '';
  String _customerPhone = '';
  String _customerLocation = '';
  String _paymentMode = 'CASH'; // 'CASH' or 'LOAN'
  String? _nameError;
  String? _phoneError;
  String? _locationError;
  bool _hasStep1Attempted = false;
  int _step1ValidationEpoch = 0;
  bool _isNavigating = false;
  String _consumerNumber = '';
  String _city = 'Rajkot';
  String _discom = 'PGVCL';
  String _phase = '1-Phase';
  double _sanctionedLoadKw = 5.0;

  // Step 2: Solar System Sizing
  double _selectedCapacityKw = 3.3;
  SolarModuleModel? _selectedModule;
  SolarInverterModel? _selectedInverter;
  String _structureType = 'Standard Rooftop';
  List<BomItemModel> _bomItems = [];
  String _projectType = 'Residential';
  bool _enableExtraTransport = false;
  double _extraTransportAmount = 3000.0;

  // Step 3: Pricing & Margin
  String _marginMode = 'per_kw'; // 'per_kw', 'amount', 'percent'
  double _marginRatePerKw = 4000.0;
  double _marginRatePct = 8.0;
  double _marginFixed = 20000.0;
  double _dealerMarginInr = 13200.0; // default margin for 3.3kW @ 4000/kW
  double _discountAmount = 0.0;
  bool _isLoanSelected = false;
  SolarBankModel? _selectedBank;
  int _loanTenureMonths = 84;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CatalogBootstrapModel? get catalog => _catalog;
  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;

  bool get isMarginBased {
    final cat = currentUser.category.toLowerCase();
    return !cat.contains('kit');
  }

  String get consumerNumber => _consumerNumber;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get customerLocation => _customerLocation;
  String get paymentMode => _paymentMode;
  String? get nameError => _nameError;
  String? get phoneError => _phoneError;
  String? get locationError => _locationError;
  bool get hasStep1Attempted => _hasStep1Attempted;
  int get step1ValidationEpoch => _step1ValidationEpoch;
  bool get isNavigating => _isNavigating;
  String get city => _city;
  String get discom => _discom;
  String get phase => _phase;
  double get sanctionedLoadKw => _sanctionedLoadKw;

  bool get isStep1Filled {
    final trimmedName = _customerName.trim();
    final digits = _customerPhone.replaceAll(RegExp(r'\D'), '');
    final trimmedLoc = _customerLocation.trim();
    return trimmedName.isNotEmpty &&
        digits.length == 10 &&
        trimmedLoc.isNotEmpty;
  }

  String get projectType => _projectType;
  bool get enableExtraTransport => _enableExtraTransport;
  double get extraTransportAmount => _extraTransportAmount;

  double get selectedCapacityKw => _selectedCapacityKw;
  SolarModuleModel? get selectedModule => _selectedModule;
  SolarInverterModel? get selectedInverter => _selectedInverter;
  String get structureType => _structureType;
  List<BomItemModel> get bomItems => _bomItems;

  String get marginMode => _marginMode;
  double get marginRatePerKw => _marginRatePerKw;
  double get marginRatePct => _marginRatePct;
  double get marginFixed => _marginFixed;
  double get dealerMarginInr => _dealerMarginInr;
  double get maxMarginCapPerKw => currentUser.maxMarginCapPerKw > 0
      ? currentUser.maxMarginCapPerKw
      : 6000.0;
  double get maxTotalMargin => maxMarginCapPerKw * _selectedCapacityKw;
  double get currentMarginPerKw => _selectedCapacityKw > 0
      ? (_dealerMarginInr / _selectedCapacityKw).roundToDouble()
      : 0.0;
  bool get isMarginExceeded =>
      maxMarginCapPerKw > 0 && currentMarginPerKw > maxMarginCapPerKw;
  String get effectiveMarginPercent => baseTurnkeyCost > 0
      ? ((_dealerMarginInr / baseTurnkeyCost) * 100).toStringAsFixed(1)
      : '0.0';

  int get rooftopAreaSqFt => (_selectedCapacityKw * 64).round();
  double get totalKwp => double.parse(
    ((panelCount * (_selectedModule?.wattage ?? 550)) / 1000).toStringAsFixed(
      3,
    ),
  );

  List<SolarModuleModel> get compatibleModules {
    if (_catalog == null || _catalog!.modules.isEmpty) return [];
    final compatible = _catalog!.modules
        .where(
          (m) => PricingEngine.isPanelWattageCompatible(
            _selectedCapacityKw,
            m.wattage,
          ),
        )
        .toList();
    return compatible.isNotEmpty ? compatible : _catalog!.modules;
  }

  double get discountAmount => _discountAmount;
  bool get isLoanSelected => _isLoanSelected;
  SolarBankModel? get selectedBank => _selectedBank;
  int get loanTenureMonths => _loanTenureMonths;

  CreateQuotationController({
    required this.repository,
    required this.currentUser,
  }) {
    _init();
  }

  Future<void> _init() async {
    // 1. Immediately provide healthy catalog so modules and inverters are never null
    _catalog = _getOfflineFallbackCatalog();
    _initDefaults();
    _isLoading = false;
    notifyListeners();

    // 2. Fetch fresh catalog from worker gateway in background
    try {
      final result = await repository.getBootstrapCatalog();
      final catData = result.dataOrNull;
      if (result.isSuccess && catData != null && catData.modules.isNotEmpty) {
        _catalog = catData;
        _initDefaults();
        notifyListeners();
      }
    } catch (_) {}
  }

  void _initDefaults() {
    if (_catalog != null) {
      if (_catalog!.modules.isNotEmpty) {
        _selectedModule = _catalog!.modules.firstWhere(
          (m) => m.brand.toLowerCase().contains('aps') && m.wattage == 550,
          orElse: () => _catalog!.modules.first,
        );
      }
      if (_catalog!.solarBanks.isNotEmpty) {
        _selectedBank = _catalog!.solarBanks.first;
      }
      _autoMatchInverter();
      _updateDefaultMargin();
      if (!isMarginBased) {
        _buildDefaultBom();
      }
    }
  }

  void _autoMatchInverter() {
    if (_catalog == null || _catalog!.inverters.isEmpty) return;
    final targetKw = _selectedCapacityKw;
    _selectedInverter = _catalog!.inverters.firstWhere(
      (i) => (i.capacityKw - targetKw).abs() < 1.0,
      orElse: () => _catalog!.inverters.first,
    );
  }

  void _updateDefaultMargin() {
    if (_marginMode == 'per_kw') {
      _dealerMarginInr = (_marginRatePerKw * _selectedCapacityKw)
          .roundToDouble();
    } else if (_marginMode == 'percent') {
      _dealerMarginInr = (baseTurnkeyCost * (_marginRatePct / 100))
          .roundToDouble();
    } else {
      _dealerMarginInr = _marginFixed.roundToDouble();
    }
  }

  // Setters for Step 1
  void setConsumerNumber(String val) {
    _consumerNumber = val;
    notifyListeners();
  }

  void setCustomerName(String val) {
    _customerName = val;
    if (_hasStep1Attempted) {
      if (val.trim().isNotEmpty) {
        _nameError = null;
      } else {
        _nameError = 'Please enter customer full name';
      }
    }
    notifyListeners();
  }

  void setCustomerPhone(String val) {
    _customerPhone = val;
    if (_hasStep1Attempted) {
      final digits = val.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10) {
        _phoneError = null;
      } else if (digits.isEmpty) {
        _phoneError = 'Please enter mobile number';
      } else {
        _phoneError = 'Mobile number must be exactly 10 digits';
      }
    }
    notifyListeners();
  }

  void setCustomerLocation(String val) {
    _customerLocation = val;
    _city = val;
    if (_hasStep1Attempted) {
      if (val.trim().isNotEmpty) {
        _locationError = null;
      } else {
        _locationError = 'Please enter installation city or pincode';
      }
    }
    notifyListeners();
  }

  bool validateStep1() {
    _hasStep1Attempted = true;
    bool isValid = true;

    final trimmedName = _customerName.trim();
    if (trimmedName.isEmpty) {
      _nameError = 'Please enter customer full name';
      isValid = false;
    } else {
      _nameError = null;
    }

    final digitsPhone = _customerPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsPhone.isEmpty) {
      _phoneError = 'Please enter mobile number';
      isValid = false;
    } else if (digitsPhone.length != 10) {
      _phoneError = 'Mobile number must be exactly 10 digits';
      isValid = false;
    } else {
      _phoneError = null;
    }

    final trimmedLoc = _customerLocation.trim();
    if (trimmedLoc.isEmpty) {
      _locationError = 'Please enter installation city or pincode';
      isValid = false;
    } else {
      _locationError = null;
    }

    if (!isValid) {
      _step1ValidationEpoch++;
    }

    notifyListeners();
    return isValid;
  }

  void setPaymentMode(String val) {
    if (val == 'LOAN') {
      // Solar Loan is currently in development; keep Cash Case active
      return;
    }
    _paymentMode = val;
    _isLoanSelected = (val == 'LOAN');
    notifyListeners();
  }

  void setCity(String val) {
    _city = val;
    notifyListeners();
  }

  void setDiscom(String val) {
    _discom = val;
    notifyListeners();
  }

  void setPhase(String val) {
    _phase = val;
    notifyListeners();
  }

  void setSanctionedLoadKw(double val) {
    _sanctionedLoadKw = val;
    notifyListeners();
  }

  // Setters for Step 2
  void setCapacityKw(double kw) {
    _selectedCapacityKw = kw;
    final compat = compatibleModules;
    if (compat.isNotEmpty && !compat.any((m) => m.id == _selectedModule?.id)) {
      _selectedModule = compat.first;
    }
    _autoMatchInverter();
    _updateDefaultMargin();
    if (!isMarginBased) {
      _buildDefaultBom();
    }
    notifyListeners();
  }

  void setModule(SolarModuleModel module) {
    _selectedModule = module;
    notifyListeners();
  }

  void setInverter(SolarInverterModel inverter) {
    _selectedInverter = inverter;
    notifyListeners();
  }

  void setStructureType(String type) {
    _structureType = type;
    notifyListeners();
  }

  // Step 2 Kit-Based BOM Operations
  void _buildDefaultBom() {
    if (_selectedModule == null) return;
    final qty = panelCount;
    final panelCost =
        qty * _selectedModule!.ratePerWpInr * _selectedModule!.wattage;
    final invCost = _selectedInverter?.basePriceInr ?? 35000.0;

    _bomItems = [
      BomItemModel(
        id: 'solar_panel',
        name:
            '${_selectedModule!.brand} ${_selectedModule!.wattage}W ${_selectedModule!.technology}',
        category: 'major',
        unit: 'NOS',
        qty: qty,
        rate: (_selectedModule!.ratePerWpInr * _selectedModule!.wattage)
            .roundToDouble(),
        gstRate: 5,
        baseAmount: panelCost,
        gstAmount: panelCost * 0.05,
        totalWithGst: panelCost * 1.05,
      ),
      BomItemModel(
        id: 'solar_inverter',
        name:
            '${_selectedInverter?.brand ?? "Solis"} ${_selectedInverter?.capacityKw ?? 3.3}kW On-Grid Inverter',
        category: 'major',
        unit: 'SET',
        qty: 1,
        rate: invCost,
        gstRate: 12,
        baseAmount: invCost,
        gstAmount: invCost * 0.12,
        totalWithGst: invCost * 1.12,
      ),
      BomItemModel(
        id: 'structure',
        name: 'HDGI Solar Module Mounting Structure ($_structureType)',
        category: 'structure',
        unit: 'SET',
        qty: 1,
        rate: (_selectedCapacityKw * 4000).roundToDouble(),
        gstRate: 18,
        baseAmount: _selectedCapacityKw * 4000,
        gstAmount: _selectedCapacityKw * 4000 * 0.18,
        totalWithGst: _selectedCapacityKw * 4000 * 1.18,
      ),
      BomItemModel(
        id: 'electrical_bos',
        name: 'ACDB, DCDB & Lightning Protection System',
        category: 'electrical',
        unit: 'KIT',
        qty: 1,
        rate: (_selectedCapacityKw * 2500).roundToDouble(),
        gstRate: 18,
        baseAmount: _selectedCapacityKw * 2500,
        gstAmount: _selectedCapacityKw * 2500 * 0.18,
        totalWithGst: _selectedCapacityKw * 2500 * 1.18,
      ),
      BomItemModel(
        id: 'cables_conduits',
        name: 'DC Solar Cable (4 sq mm) & PVC Conduits',
        category: 'cables',
        unit: 'LOT',
        qty: 1,
        rate: (_selectedCapacityKw * 2000).roundToDouble(),
        gstRate: 18,
        baseAmount: _selectedCapacityKw * 2000,
        gstAmount: _selectedCapacityKw * 2000 * 0.18,
        totalWithGst: _selectedCapacityKw * 2000 * 1.18,
      ),
    ];
  }

  void updateBomItemQty(String id, int qty) {
    final idx = _bomItems.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final item = _bomItems[idx];
      final base = (qty * item.rate).roundToDouble();
      final gst = (base * item.gstRate / 100).roundToDouble();
      _bomItems[idx] = BomItemModel(
        id: item.id,
        name: item.name,
        category: item.category,
        unit: item.unit,
        qty: qty,
        rate: item.rate,
        gstRate: item.gstRate,
        baseAmount: base,
        gstAmount: gst,
        totalWithGst: base + gst,
      );
      notifyListeners();
    }
  }

  void setProjectType(String val) {
    _projectType = val;
    notifyListeners();
  }

  void toggleExtraTransport(bool val) {
    _enableExtraTransport = val;
    notifyListeners();
  }

  void setExtraTransportAmount(double amt) {
    _extraTransportAmount = math.max(0.0, amt);
    notifyListeners();
  }

  // Setters for Step 3
  void setMarginMode(String mode) {
    _marginMode = mode;
    _updateDefaultMargin();
    notifyListeners();
  }

  void setMarginRatePerKw(double rate) {
    _marginRatePerKw = math.max(0.0, rate);
    if (_marginMode == 'per_kw') {
      _dealerMarginInr = (_marginRatePerKw * _selectedCapacityKw)
          .roundToDouble();
    }
    notifyListeners();
  }

  void setMarginRatePct(double pct) {
    _marginRatePct = math.max(0.0, pct);
    if (_marginMode == 'percent') {
      _dealerMarginInr = (baseTurnkeyCost * (_marginRatePct / 100))
          .roundToDouble();
    }
    notifyListeners();
  }

  void setMarginFixed(double amt) {
    _marginFixed = math.max(0.0, amt);
    if (_marginMode == 'amount') {
      _dealerMarginInr = _marginFixed.roundToDouble();
    }
    notifyListeners();
  }

  void setDealerMargin(double margin) {
    _dealerMarginInr = math.max(0.0, margin).roundToDouble();
    if (_selectedCapacityKw > 0) {
      _marginRatePerKw = (_dealerMarginInr / _selectedCapacityKw)
          .roundToDouble();
    }
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discountAmount = math.max(0.0, discount);
    notifyListeners();
  }

  void toggleLoan(bool isSelected) {
    _isLoanSelected = isSelected;
    notifyListeners();
  }

  void setBank(SolarBankModel bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  void setLoanTenureMonths(int months) {
    _loanTenureMonths = months;
    notifyListeners();
  }

  // Calculated Financial Values
  int get panelCount {
    if (_selectedModule == null) return 6;
    return PricingEngine.getPanelQuantityForCapacity(
      _selectedCapacityKw,
      _selectedModule!.wattage,
    );
  }

  double get extraTransportCharge =>
      _enableExtraTransport ? _extraTransportAmount : 0.0;

  double get baseTurnkeyCost {
    if (isMarginBased) {
      // Look up BOS pricing slab or dynamic rate per Wp
      final brand = _selectedModule?.brand.toLowerCase() ?? '';
      final match = _catalog?.bosMatrix.firstWhere(
        (b) =>
            (b.capacitySlab - _selectedCapacityKw).abs() < 0.2 &&
            b.panelBrand.toLowerCase().contains(brand),
        orElse: () =>
            _catalog?.bosMatrix.firstWhere(
              (b) => (b.capacitySlab - _selectedCapacityKw).abs() < 0.2,
              orElse: () => BosPricingSlabModel(
                capacitySlab: _selectedCapacityKw,
                panelBrand: _selectedModule?.brand ?? 'Adani',
                bosPricePerWp: 48.0,
                gstRate: 13.8,
              ),
            ) ??
            BosPricingSlabModel(
              capacitySlab: _selectedCapacityKw,
              panelBrand: _selectedModule?.brand ?? 'Adani',
              bosPricePerWp: 48.0,
              gstRate: 13.8,
            ),
      );

      final totalWatts = _selectedCapacityKw * 1000;
      final rate = match?.bosPricePerWp ?? 48.0;
      final baseExGst = (totalWatts * rate).roundToDouble();
      final gstRate = match?.gstRate ?? 13.8;
      return (baseExGst * (1 + (gstRate / 100))).roundToDouble();
    } else {
      final bomTotals = PricingEngine.calcBOMTotals(items: _bomItems);
      return (bomTotals['grossTurnkeyCost'] as double?) ?? 150000.0;
    }
  }

  double get centralSubsidy {
    return PricingEngine.calculateSubsidy(
      capacityKw: _selectedCapacityKw,
      projectType: _projectType,
      subsidySettings:
          _catalog?.settings.subsidy ?? const SubsidySettingsModel(),
    );
  }

  Map<String, double> get finalTotals {
    final grossTurnkey =
        baseTurnkeyCost + _dealerMarginInr + extraTransportCharge;
    final totalAmount = math.max(
      0.0,
      (grossTurnkey - _discountAmount).roundToDouble(),
    );
    final netPayable = math.max(
      0.0,
      (totalAmount - centralSubsidy).roundToDouble(),
    );
    final taxableBase = (totalAmount / 1.18).roundToDouble();
    final gstAmount = (totalAmount - taxableBase).roundToDouble();

    return {
      'totalAmount': totalAmount,
      'netPayable': netPayable,
      'discountAmount': _discountAmount,
      'taxableBase': taxableBase,
      'gstAmount': gstAmount,
      'extraTransport': extraTransportCharge,
    };
  }

  Map<String, dynamic> get generation {
    return PricingEngine.calculateGenerationUnits(
      capacityKw: _selectedCapacityKw,
      specificYield:
          _catalog?.settings.governance.defaultSpecificYield ?? 1440.0,
    );
  }

  Map<String, dynamic> get savings {
    return PricingEngine.calculateSavingsAndPayback(
      netPayable: finalTotals['netPayable'] ?? 0.0,
      annualUnits: (generation['annualUnits'] as int?) ?? 4320,
      tariff: _catalog?.settings.governance.defaultTariff ?? 6.67,
    );
  }

  double get monthlyLoanEmi {
    if (!_isLoanSelected) return 0.0;
    final principal = finalTotals['netPayable'] ?? 0.0;
    final rate = _selectedBank?.interestRate ?? 7.0;
    return PricingEngine.calcEMI(
      principal: principal,
      annualRatePct: rate,
      tenureMonths: _loanTenureMonths,
    );
  }

  // Stepper Navigation
  bool canProceedStep(int step) {
    if (step == 0) {
      final cleanPhone = _customerPhone.replaceAll(RegExp(r'\D'), '');
      return _customerName.trim().isNotEmpty &&
          cleanPhone.length == 10 &&
          _customerLocation.trim().isNotEmpty;
    }
    if (step == 1) {
      return _selectedCapacityKw > 0 && _selectedModule != null;
    }
    if (step == 2) {
      return finalTotals['totalAmount']! > 0;
    }
    return true;
  }

  bool nextStep() {
    if (_isNavigating) return false;

    if (_currentStep == 0) {
      final valid = validateStep1();
      if (!valid) return false;
    } else if (!canProceedStep(_currentStep)) {
      return false;
    }

    if (_currentStep < 3) {
      _isNavigating = true;
      _currentStep++;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
        notifyListeners();
      });
      return true;
    }
    return false;
  }

  void previousStep() {
    if (_isNavigating) return;
    if (_currentStep > 0) {
      _isNavigating = true;
      _currentStep--;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
        notifyListeners();
      });
    }
  }

  void goToStep(int targetStep) {
    if (_isNavigating || targetStep == _currentStep) return;
    // Disallow jumping forward past unvalidated steps
    if (targetStep > _currentStep) {
      if (_currentStep == 0 && !validateStep1()) return;
      for (int i = _currentStep; i < targetStep; i++) {
        if (!canProceedStep(i)) return;
      }
    }
    if (targetStep >= 0 && targetStep <= 3) {
      _isNavigating = true;
      _currentStep = targetStep;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
        notifyListeners();
      });
    }
  }

  // Payload Builder
  Map<String, dynamic> buildQuotePayload({
    String explicitStatus = 'Active / Sent',
  }) {
    final year = DateTime.now().year;
    final rand = (1000 + math.Random().nextInt(9000)).toString();
    final quoteId = 'SV-$year-Q$rand';

    return {
      'id': quoteId,
      'quoteNumber': quoteId,
      'customerName': _customerName.trim(),
      'customerPhone': _customerPhone.trim(),
      'customerLocation': _customerLocation.trim(),
      'location': _customerLocation.trim(),
      'city': _customerLocation.split(',').first.trim(),
      'paymentMode': _paymentMode,
      'financeType': _paymentMode,
      'consumerNumber': _consumerNumber.trim(),
      'state': 'Gujarat',
      'discom': _discom,
      'phase': _phase,
      'sanctionedLoadKw': _sanctionedLoadKw,
      'systemCapacityKW': _selectedCapacityKw,
      'capacityKW': _selectedCapacityKw,
      'projectType': 'Residential',
      'solarModule':
          '${_selectedModule?.brand ?? "Adani"} ${_selectedModule?.wattage ?? 550}W ${_selectedModule?.technology ?? "Bifacial"}',
      'moduleWattage': _selectedModule?.wattage ?? 550,
      'moduleCount': panelCount,
      'panelId': _selectedModule?.id,
      'inverterId': _selectedInverter?.id,
      'inverterMake': _selectedInverter?.brand ?? 'Solis / Growatt / Deye',
      'structureType': _structureType,
      'baseCost': baseTurnkeyCost,
      'dealerMarginINR': _dealerMarginInr,
      'discountAmount': _discountAmount,
      'subsidyAmount': centralSubsidy,
      'totalAmount': finalTotals['totalAmount'],
      'netPayable': finalTotals['netPayable'],
      'pricingCategory': isMarginBased ? 'Margin Based' : 'Kit Based',
      'status': explicitStatus,
      'dealerCode': currentUser.dealerCode.isNotEmpty
          ? currentUser.dealerCode
          : 'SV-DLR-0104',
      'dealerFirmName': currentUser.firmName.isNotEmpty
          ? currentUser.firmName
          : 'Sunvine Partner',
      'annualGenerationUnits': generation['annualUnits'],
      'annualSavingsInr': savings['annualSavings'],
      'paybackYears': savings['paybackYears'],
      'isLoanSelected': _isLoanSelected,
      'loanBank': _selectedBank?.bankName,
      'monthlyEmi': monthlyLoanEmi,
    };
  }

  // Submission Methods
  Future<Map<String, dynamic>?> saveAsDraft({bool syncPending = false}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final payload = buildQuotePayload(explicitStatus: 'Draft');
      await repository.saveOfflineDraft(payload, syncPending: syncPending);
      _isSubmitting = false;
      notifyListeners();
      return payload;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to save draft: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitQuotation() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = buildQuotePayload(explicitStatus: 'Active / Sent');
      final result = await repository.saveQuotation(payload);
      final resData = result.dataOrNull;

      if (result.isSuccess && resData != null) {
        _isSubmitting = false;
        notifyListeners();
        return resData;
      } else {
        // Fallback: Save to offline queue with auto-sync enabled!
        await repository.saveOfflineDraft(payload, syncPending: true);
        _isSubmitting = false;
        notifyListeners();
        return {'offlineQueued': true, 'quotation': payload};
      }
    } catch (e) {
      // Offline fallback
      final payload = buildQuotePayload(explicitStatus: 'Draft');
      await repository.saveOfflineDraft(payload, syncPending: true);
      _isSubmitting = false;
      notifyListeners();
      return {'offlineQueued': true, 'quotation': payload};
    }
  }

  CatalogBootstrapModel _getOfflineFallbackCatalog() {
    return const CatalogBootstrapModel(
      modules: [
        SolarModuleModel(
          id: 'mod_aps_550',
          brand: 'APS 550W',
          model: '550W TOPCon Mono Bifacial',
          wattage: 550,
          ratePerWpInr: 20.5,
          cellType: 'TOPCon',
          technology: 'TOPCon Mono Bifacial',
        ),
        SolarModuleModel(
          id: 'mod_adani_550',
          brand: 'Adani Solar',
          model: '550W Vertex Mono PERC Bifacial',
          wattage: 550,
          ratePerWpInr: 21.5,
          cellType: 'Mono PERC',
          technology: 'Bifacial Dual Glass',
        ),
        SolarModuleModel(
          id: 'mod_rayzon_550',
          brand: 'Rayzon Solar',
          model: '550W Albus TOPCon High Efficiency',
          wattage: 550,
          ratePerWpInr: 21.0,
          cellType: 'TOPCon',
          technology: 'Bifacial Dual Glass',
        ),
        SolarModuleModel(
          id: 'mod_waaree_585',
          brand: 'Waaree Energies',
          model: '585W HyperIon TOPCon Dual Glass',
          wattage: 585,
          ratePerWpInr: 22.8,
          cellType: 'TOPCon',
          technology: 'Bifacial Dual Glass',
        ),
      ],
      inverters: [
        SolarInverterModel(
          id: 'inv_solis_3k',
          brand: 'Solis',
          model: 'S6-GR1P3K',
          capacityKw: 3.3,
          basePriceInr: 32000.0,
        ),
        SolarInverterModel(
          id: 'inv_growatt_5k',
          brand: 'Growatt',
          model: 'MIN 5000TL-X',
          capacityKw: 5.0,
          basePriceInr: 45000.0,
        ),
        SolarInverterModel(
          id: 'inv_deye_6k',
          brand: 'Deye',
          model: 'SUN-6K-G03',
          capacityKw: 6.0,
          basePriceInr: 52000.0,
        ),
      ],
    );
  }
}
