class SolarModuleModel {
  final String id;
  final String brand;
  final String model;
  final int wattage;
  final double ratePerWpInr;
  final String cellType;
  final String technology;
  final int warrantyYears;
  final bool isAlmmApproved;
  final bool isBifacial;

  const SolarModuleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.wattage,
    required this.ratePerWpInr,
    this.cellType = 'TOPCon',
    this.technology = 'Bifacial Dual Glass',
    this.warrantyYears = 25,
    this.isAlmmApproved = true,
    this.isBifacial = true,
  });

  factory SolarModuleModel.fromJson(Map<String, dynamic> json) {
    return SolarModuleModel(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      wattage: int.tryParse(json['wattage']?.toString() ?? '') ?? 550,
      ratePerWpInr: double.tryParse(json['rate_per_wp_inr']?.toString() ?? '') ?? 0.0,
      cellType: json['cell_type']?.toString() ?? 'TOPCon',
      technology: json['technology']?.toString() ?? 'Bifacial Dual Glass',
      warrantyYears: int.tryParse(json['warranty_years']?.toString() ?? '') ?? 25,
      isAlmmApproved: json['is_almm_approved'] != false,
      isBifacial: json['is_bifacial'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'wattage': wattage,
    'rate_per_wp_inr': ratePerWpInr,
    'cell_type': cellType,
    'technology': technology,
    'warranty_years': warrantyYears,
    'is_almm_approved': isAlmmApproved,
    'is_bifacial': isBifacial,
  };
}

class SolarInverterModel {
  final String id;
  final String brand;
  final String model;
  final double capacityKw;
  final double basePriceInr;
  final String phase;
  final int warrantyYears;

  const SolarInverterModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.capacityKw,
    required this.basePriceInr,
    this.phase = 'Single Phase',
    this.warrantyYears = 8,
  });

  factory SolarInverterModel.fromJson(Map<String, dynamic> json) {
    return SolarInverterModel(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      capacityKw: double.tryParse(json['capacity_kw']?.toString() ?? '') ?? 3.3,
      basePriceInr: double.tryParse(json['base_price_inr']?.toString() ?? '') ?? 0.0,
      phase: json['phase']?.toString() ?? 'Single Phase',
      warrantyYears: int.tryParse(json['warranty_years']?.toString() ?? '') ?? 8,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'capacity_kw': capacityKw,
    'base_price_inr': basePriceInr,
    'phase': phase,
    'warranty_years': warrantyYears,
  };
}

class BosPricingSlabModel {
  final double capacitySlab;
  final String panelBrand;
  final double bosPricePerWp;
  final double gstRate;
  final Map<String, dynamic>? rawSlab;

  const BosPricingSlabModel({
    required this.capacitySlab,
    required this.panelBrand,
    required this.bosPricePerWp,
    required this.gstRate,
    this.rawSlab,
  });

  factory BosPricingSlabModel.fromJson(Map<String, dynamic> json) {
    return BosPricingSlabModel(
      capacitySlab: double.tryParse(json['capacity_slab']?.toString() ?? json['capacityKW']?.toString() ?? '') ?? 0.0,
      panelBrand: json['panel_brand']?.toString() ?? '',
      bosPricePerWp: double.tryParse(json['bos_price_per_wp']?.toString() ?? '') ?? 0.0,
      gstRate: double.tryParse(json['gst_rate']?.toString() ?? '') ?? 13.8,
      rawSlab: json,
    );
  }
}

class SubsidySettingsModel {
  final double slab1Rate;
  final double slab2Rate;
  final double cap;
  final double breakpointKw;

  const SubsidySettingsModel({
    this.slab1Rate = 30000.0,
    this.slab2Rate = 18000.0,
    this.cap = 78000.0,
    this.breakpointKw = 3.0,
  });

  factory SubsidySettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubsidySettingsModel();
    return SubsidySettingsModel(
      slab1Rate: double.tryParse(json['slab1Rate']?.toString() ?? '') ?? 30000.0,
      slab2Rate: double.tryParse(json['slab2Rate']?.toString() ?? '') ?? 18000.0,
      cap: double.tryParse(json['cap']?.toString() ?? '') ?? 78000.0,
      breakpointKw: double.tryParse(json['breakpointKw']?.toString() ?? '') ?? 3.0,
    );
  }
}

class GovernanceSettingsModel {
  final double maxDiscountPct;
  final double maxSystemKw;
  final String quotePrefix;
  final int validityDays;
  final double defaultSpecificYield;
  final double defaultTariff;
  final double defaultLoanRate;

  const GovernanceSettingsModel({
    this.maxDiscountPct = 5.0,
    this.maxSystemKw = 1000.0,
    this.quotePrefix = 'SV',
    this.validityDays = 15,
    this.defaultSpecificYield = 1440.0,
    this.defaultTariff = 6.67,
    this.defaultLoanRate = 8.5,
  });

  factory GovernanceSettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GovernanceSettingsModel();
    return GovernanceSettingsModel(
      maxDiscountPct: double.tryParse(json['max_discount_pct']?.toString() ?? '') ?? 5.0,
      maxSystemKw: double.tryParse(json['max_system_kw']?.toString() ?? '') ?? 1000.0,
      quotePrefix: json['quote_prefix']?.toString() ?? 'SV',
      validityDays: int.tryParse(json['validity_days']?.toString() ?? '') ?? 15,
      defaultSpecificYield: double.tryParse(json['default_specific_yield']?.toString() ?? '') ?? 1440.0,
      defaultTariff: double.tryParse(json['default_tariff']?.toString() ?? '') ?? 6.67,
      defaultLoanRate: double.tryParse(json['default_loan_rate']?.toString() ?? '') ?? 8.5,
    );
  }
}

class SystemSettingsModel {
  final GovernanceSettingsModel governance;
  final SubsidySettingsModel subsidy;
  final List<int> gstSlabs;

  const SystemSettingsModel({
    this.governance = const GovernanceSettingsModel(),
    this.subsidy = const SubsidySettingsModel(),
    this.gstSlabs = const [0, 5, 12, 18, 28],
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SystemSettingsModel();
    final gov = json['governance_settings'] as Map<String, dynamic>?;
    final stat = json['statutory_taxes'] as Map<String, dynamic>?;
    final sub = stat?['subsidy'] as Map<String, dynamic>?;
    final slabsRaw = stat?['gstSlabs'];
    List<int> slabs = [0, 5, 12, 18, 28];
    if (slabsRaw is List) {
      slabs = slabsRaw.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    }
    return SystemSettingsModel(
      governance: GovernanceSettingsModel.fromJson(gov),
      subsidy: SubsidySettingsModel.fromJson(sub),
      gstSlabs: slabs,
    );
  }
}

class SolarBankModel {
  final String id;
  final String bankName;
  final String schemeName;
  final double interestRate;
  final int maxTenureMonths;
  final double processingFeePct;

  const SolarBankModel({
    required this.id,
    required this.bankName,
    this.schemeName = 'PM Surya Ghar Loan',
    this.interestRate = 7.0,
    this.maxTenureMonths = 84,
    this.processingFeePct = 0.5,
  });

  factory SolarBankModel.fromJson(Map<String, dynamic> json) {
    return SolarBankModel(
      id: json['id']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? json['name']?.toString() ?? 'State Bank of India',
      schemeName: json['scheme_name']?.toString() ?? 'Surya Ghar Solar Loan',
      interestRate: double.tryParse(json['interest_rate']?.toString() ?? json['rate']?.toString() ?? '') ?? 7.0,
      maxTenureMonths: int.tryParse(json['max_tenure_months']?.toString() ?? '') ?? 84,
      processingFeePct: double.tryParse(json['processing_fee_pct']?.toString() ?? '') ?? 0.5,
    );
  }
}

class BomItemModel {
  final String id;
  final String name;
  final String category;
  final String unit;
  final int qty;
  final double rate;
  final int gstRate;
  final double baseAmount;
  final double gstAmount;
  final double totalWithGst;

  const BomItemModel({
    required this.id,
    required this.name,
    this.category = 'major',
    this.unit = 'NOS',
    required this.qty,
    required this.rate,
    this.gstRate = 18,
    required this.baseAmount,
    required this.gstAmount,
    required this.totalWithGst,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': name,
    'category': category,
    'unit': unit,
    'qty': qty,
    'rate': rate,
    'gstRate': gstRate,
    'baseAmount': baseAmount,
    'gstAmount': gstAmount,
    'totalWithGst': totalWithGst,
  };

  factory BomItemModel.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['qty']?.toString() ?? '') ?? 1;
    final rate = double.tryParse(json['rate']?.toString() ?? '') ?? 0.0;
    final gstRate = int.tryParse(json['gstRate']?.toString() ?? json['taxRate']?.toString() ?? '') ?? 18;
    final baseAmount = double.tryParse(json['baseAmount']?.toString() ?? '') ?? (qty * rate);
    final gstAmount = double.tryParse(json['gstAmount']?.toString() ?? '') ?? (baseAmount * gstRate / 100);
    final totalWithGst = double.tryParse(json['totalWithGst']?.toString() ?? '') ?? (baseAmount + gstAmount);

    return BomItemModel(
      id: json['id']?.toString() ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: json['item']?.toString() ?? json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'major',
      unit: json['unit']?.toString() ?? 'NOS',
      qty: qty,
      rate: rate,
      gstRate: gstRate,
      baseAmount: baseAmount,
      gstAmount: gstAmount,
      totalWithGst: totalWithGst,
    );
  }
}

class CatalogBootstrapModel {
  final List<SolarModuleModel> modules;
  final List<SolarInverterModel> inverters;
  final List<BosPricingSlabModel> bosMatrix;
  final SystemSettingsModel settings;
  final List<SolarBankModel> solarBanks;

  const CatalogBootstrapModel({
    this.modules = const [],
    this.inverters = const [],
    this.bosMatrix = const [],
    this.settings = const SystemSettingsModel(),
    this.solarBanks = const [],
  });

  factory CatalogBootstrapModel.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] as Map<String, dynamic>? ?? json;
    
    // Modules & Inverters
    final hw = catalog['hardware'] as Map<String, dynamic>?;
    final rawModules = hw?['modules'] as List? ?? [];
    final rawInverters = hw?['inverters'] as List? ?? [];
    
    final modules = rawModules.map((m) => SolarModuleModel.fromJson(m as Map<String, dynamic>)).toList();
    final inverters = rawInverters.map((i) => SolarInverterModel.fromJson(i as Map<String, dynamic>)).toList();

    // BOS Matrix
    final rawBos = catalog['bosMatrix'] as List? ?? [];
    final bosMatrix = rawBos.map((b) => BosPricingSlabModel.fromJson(b as Map<String, dynamic>)).toList();

    // Settings
    final settingsMap = (catalog['settings'] ?? json['settings']) as Map<String, dynamic>?;
    final settings = SystemSettingsModel.fromJson(settingsMap);

    // Banks
    final rawBanks = catalog['solarBanks'] as List? ?? [];
    final banks = rawBanks.map((b) => SolarBankModel.fromJson(b as Map<String, dynamic>)).toList();

    return CatalogBootstrapModel(
      modules: modules,
      inverters: inverters,
      bosMatrix: bosMatrix,
      settings: settings,
      solarBanks: banks.isNotEmpty ? banks : [
        const SolarBankModel(id: 'sbi', bankName: 'State Bank of India', schemeName: 'Surya Ghar Solar Loan', interestRate: 7.0),
        const SolarBankModel(id: 'canara', bankName: 'Canara Bank', schemeName: 'PM Surya Ghar Scheme', interestRate: 7.0),
        const SolarBankModel(id: 'bob', bankName: 'Bank of Baroda', schemeName: 'Baroda Rooftop Solar Loan', interestRate: 7.15),
        const SolarBankModel(id: 'hdfc', bankName: 'HDFC Bank', schemeName: 'Green Energy Loan', interestRate: 8.5),
      ],
    );
  }
}
