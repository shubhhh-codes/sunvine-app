/// Central registry for secure storage and local preferences keys.
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'sv_access_token';
  static const String refreshToken = 'sv_refresh_token';
  static const String accessExpiresAt = 'sv_access_expires_at';
  static const String dealerUser = 'sv_dealer_user';
  static const String biometricEnabled = 'sv_biometric_enabled';
  static const String lastBackgroundTimestamp = 'sv_last_bg_time';
}
