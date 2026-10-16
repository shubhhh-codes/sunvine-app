import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_models.dart';

class AuthService {
  final AuthRepository repository;
  final TokenStorage tokenStorage;
  final LocalAuthentication _localAuth;

  AuthService({
    required this.repository,
    required this.tokenStorage,
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = 'Authenticate to access Sunvine EPC Console'}) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<bool> shouldPromptBackgroundBiometricUnlock() async {
    final bgTimestamp = await tokenStorage.getBackgroundTimestamp();
    if (bgTimestamp == null) return false;

    final isBioEnabled = await tokenStorage.isBiometricEnabled();
    if (!isBioEnabled) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - bgTimestamp;

    // 5 minutes = 5 * 60 * 1000 = 300,000 ms
    return diffMs > 300000;
  }

  Future<void> recordAppPaused() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await tokenStorage.saveBackgroundTimestamp(now);
  }

  Future<void> clearBackgroundTimestamp() async {
    await tokenStorage.saveBackgroundTimestamp(0);
  }

  Future<AuthSession?> checkColdStartSession() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    return await repository.getStoredSession();
  }
}
