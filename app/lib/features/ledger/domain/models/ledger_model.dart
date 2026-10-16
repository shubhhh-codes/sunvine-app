/// Single financial ledger transaction entry for dealer payouts and margin disbursements.
class LedgerEntryModel {
  final String id;
  final String voucherNo;
  final String customerName;
  final String entryDate;
  final String entryType; // DEBIT or CREDIT
  final String category;
  final double amount;
  final double runningBalance;
  final String narration;

  const LedgerEntryModel({
    required this.id,
    required this.voucherNo,
    required this.customerName,
    required this.entryDate,
    required this.entryType,
    required this.category,
    required this.amount,
    required this.runningBalance,
    required this.narration,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id']?.toString() ?? '',
      voucherNo: json['voucher_no']?.toString() ?? 'VCH-000',
      customerName: json['customer_name']?.toString() ?? 'EPC Commission',
      entryDate: json['entry_date']?.toString() ?? '',
      entryType: json['entry_type']?.toString() ?? 'CREDIT',
      category: json['category']?.toString() ?? 'Margin',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      runningBalance: (json['running_balance'] as num?)?.toDouble() ?? 0.0,
      narration: json['narration']?.toString() ?? '',
    );
  }
}

/// Aggregated financial summary of the dealer account.
class LedgerSummaryModel {
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
  final int totalEntries;

  const LedgerSummaryModel({
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
    required this.totalEntries,
  });

  factory LedgerSummaryModel.fromJson(Map<String, dynamic> json) {
    return LedgerSummaryModel(
      totalDebit: (json['totalDebit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0.0,
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
    );
  }
}
