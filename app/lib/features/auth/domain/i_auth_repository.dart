import '../../../core/network/api_result.dart';
import 'auth_models.dart';

/// Repository interface contract for authentication operations.
abstract class IAuthRepository {
  Future<Result<AuthSession>> loginResult({
    required String identifier,
    required String password,
  });

  Future<AuthResult> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();

  Future<AuthSession?> getStoredSession();

  Future<Map<String, String>> getDeviceMetadata();
}
