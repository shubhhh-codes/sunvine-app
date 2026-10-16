class DealerUser {
  final String id;
  final String dealerCode;
  final String firmName;
  final String contactPerson;
  final String mobile;
  final String city;
  final String state;
  final String discom;
  final String tier;
  final double maxMarginCapPerKw;
  final String assignedStaffId;
  final String? assignedStaffName;
  final String category;
  final Map<String, dynamic> pricingConfig;

  DealerUser({
    required this.id,
    required this.dealerCode,
    required this.firmName,
    required this.contactPerson,
    required this.mobile,
    required this.city,
    required this.state,
    required this.discom,
    required this.tier,
    required this.maxMarginCapPerKw,
    required this.assignedStaffId,
    this.assignedStaffName,
    required this.category,
    required this.pricingConfig,
  });

  factory DealerUser.fromJson(Map<String, dynamic> json) {
    return DealerUser(
      id: json['id'] as String? ?? json['dealer_id'] as String? ?? '',
      dealerCode: json['dealerCode'] as String? ?? '',
      firmName: json['firmName'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? 'Gujarat',
      discom: json['discom'] as String? ?? 'UGVCL',
      tier: json['tier'] as String? ?? 'Tier 1',
      maxMarginCapPerKw: (json['maxMarginCapPerKw'] as num?)?.toDouble() ?? 0.0,
      assignedStaffId: json['assignedStaffId'] as String? ?? 'STF-DIRECT',
      assignedStaffName: json['assignedStaffName'] as String?,
      category: json['category'] as String? ?? 'Margin Based',
      pricingConfig: json['pricingConfig'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dealerCode': dealerCode,
      'firmName': firmName,
      'contactPerson': contactPerson,
      'mobile': mobile,
      'city': city,
      'state': state,
      'discom': discom,
      'tier': tier,
      'maxMarginCapPerKw': maxMarginCapPerKw,
      'assignedStaffId': assignedStaffId,
      'assignedStaffName': assignedStaffName,
      'category': category,
      'pricingConfig': pricingConfig,
    };
  }
}

class AuthSession {
  final String accessToken;
  final int accessExpiresAt;
  final String refreshToken;
  final DealerUser user;

  AuthSession({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = json['accessExpiresAt'] as int? ??
        (json['expiresIn'] != null ? nowSec + (json['expiresIn'] as int) : nowSec + 3600);

    return AuthSession(
      accessToken: json['accessToken'] as String,
      accessExpiresAt: expiresAt,
      refreshToken: json['refreshToken'] as String,
      user: DealerUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthResult {
  final bool isSuccess;
  final AuthSession? session;
  final String? errorMessage;
  final int? statusCode;

  AuthResult.success(this.session)
      : isSuccess = true,
        errorMessage = null,
        statusCode = 200;

  AuthResult.failure(this.errorMessage, {this.statusCode})
      : isSuccess = false,
        session = null;
}
