import '../../../../core/theme/components/sun_badge.dart';

/// Quotation domain entity representing a solar proposal generated for a consumer.
class QuotationModel {
  final String id;
  final String quoteNumber;
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final double systemCapacityKw;
  final double totalAmount;
  final double subsidyAmount;
  final double netPayable;
  final String status;
  final DateTime createdAt;

  const QuotationModel({
    required this.id,
    required this.quoteNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerCity,
    required this.systemCapacityKw,
    required this.totalAmount,
    required this.subsidyAmount,
    required this.netPayable,
    required this.status,
    required this.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id']?.toString() ?? '',
      quoteNumber: json['request_id']?.toString() ?? json['id']?.toString() ?? 'SV-2026',
      customerName: json['customer_name']?.toString() ?? 'Unnamed Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerCity: json['customer_city']?.toString() ?? 'Gujarat',
      systemCapacityKw: (json['system_capacity_kw'] as num?)?.toDouble() ?? 3.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      subsidyAmount: (json['subsidy_amount'] as num?)?.toDouble() ?? 0.0,
      netPayable: (json['net_payable'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as String? ?? 'DRAFT').toUpperCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SunBadgeVariant get badgeVariant => switch (status) {
        'APPROVED' => SunBadgeVariant.emerald,
        'CONFIRMED' => SunBadgeVariant.cyan,
        'IN REVIEW' => SunBadgeVariant.amber,
        _ => SunBadgeVariant.slate,
      };
}
