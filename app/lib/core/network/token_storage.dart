import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// Secure token and session credentials storage backed by Android EncryptedSharedPreferences.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  Future<int?> getAccessExpiresAt() async {
    final str = await _storage.read(key: StorageKeys.accessExpiresAt);
    if (str == null) return null;
    return int.tryParse(str);
  }

  Future<void> saveSession({
    required String accessToken,
    required int accessExpiresAt,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.accessExpiresAt, value: accessExpiresAt.toString()),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<void> saveDealerUser(Map<String, dynamic> userMap) async {
    await _storage.write(key: StorageKeys.dealerUser, value: jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getDealerUser() async {
    final str = await _storage.read(key: StorageKeys.dealerUser);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: StorageKeys.biometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: StorageKeys.biometricEnabled, value: enabled.toString());
  }

  Future<void> saveBackgroundTimestamp(int timestampMs) async {
    await _storage.write(key: StorageKeys.lastBackgroundTimestamp, value: timestampMs.toString());
  }

  Future<int?> getBackgroundTimestamp() async {
    final str = await _storage.read(key: StorageKeys.lastBackgroundTimestamp);
    if (str == null) return null;
    return int.tryParse(str);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.accessExpiresAt),
      _storage.delete(key: StorageKeys.dealerUser),
      _storage.delete(key: StorageKeys.lastBackgroundTimestamp),
    ]);
  }
}
