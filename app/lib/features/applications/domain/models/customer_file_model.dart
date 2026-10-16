/// Entity representing a customer's active EPC installation application pipeline file.
class CustomerFileModel {
  final String id;
  final String customerName;
  final String fileNo;
  final String stage;
  final String status;
  final int currentStep;
  final int totalSteps;
  final double progress;

  const CustomerFileModel({
    required this.id,
    required this.customerName,
    required this.fileNo,
    required this.stage,
    required this.status,
    required this.currentStep,
    required this.totalSteps,
  }) : progress = totalSteps > 0 ? currentStep / totalSteps : 0.0;

  factory CustomerFileModel.fromJson(Map<String, dynamic> json) {
    final rawStage = json['stage']?.toString() ?? 'LEAD_SOURCED';
    final (step, total, displayStage) = _mapStageToSteps(rawStage);

    return CustomerFileModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Customer',
      fileNo: json['consumerNo']?.toString() ?? json['consumer_no']?.toString() ?? json['id']?.toString() ?? 'CF-GUJ',
      stage: displayStage,
      status: json['status']?.toString() ?? 'Active',
      currentStep: step,
      totalSteps: total,
    );
  }

  static (int, int, String) _mapStageToSteps(String stage) {
    switch (stage.toUpperCase()) {
      case 'LEAD_SOURCED':
        return (1, 6, 'Lead Sourced & Intake');
      case 'DISCOM_NETMETER_APPLIED':
      case 'NETMETER_APPLIED':
        return (2, 6, 'DISCOM Net-Meter Applied');
      case 'SITE_SURVEY_COMPLETED':
      case 'SITE_SURVEY':
        return (3, 6, 'Site Survey Complete');
      case 'INSTALLATION_SCHEDULED':
      case 'MATERIAL_DISPATCHED':
        return (4, 6, 'Installation Scheduled');
      case 'COMMISSIONED':
      case 'INSPECTION_PENDING':
        return (5, 6, 'Plant Commissioned');
      case 'SUBSIDY_DISBURSED':
      case 'COMPLETED':
        return (6, 6, 'Subsidy Disbursed (Completed)');
      default:
        return (2, 6, stage.replaceAll('_', ' '));
    }
  }
}
