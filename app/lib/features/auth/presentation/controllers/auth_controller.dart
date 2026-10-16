import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_models.dart';
import '../../domain/auth_service.dart';

/// Lifecycle state of the dealer session.
enum AppSessionState {
  initialChecking,
  unauthenticated,
  biometricRequired,
  authenticated,
}

/// Reactive State Notifier managing authentication state, session transitions, and biometrics.
class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final AuthService authService;
  final TokenStorage tokenStorage;

  AppSessionState _sessionState = AppSessionState.initialChecking;
  DealerUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  int? _lastStatusCode;
  String? _sessionRevocationReason;

  AuthController({
    required this.repository,
    required this.authService,
    required this.tokenStorage,
  });

  AppSessionState get sessionState => _sessionState;
  DealerUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get lastStatusCode => _lastStatusCode;
  String? get sessionRevocationReason => _sessionRevocationReason;
  bool get isAuthenticated => _sessionState == AppSessionState.authenticated;

  /// Performs cold-start check of persisted session and biometrics requirement.
  Future<void> initialize() async {
    _sessionState = AppSessionState.initialChecking;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authService.checkColdStartSession();
      final isBioEnabled = await tokenStorage.isBiometricEnabled();
      final canBio = await authService.canCheckBiometrics();

      if (session != null) {
        _currentUser = session.user;
        if (isBioEnabled && canBio) {
          _sessionState = AppSessionState.biometricRequired;
        } else {
          _sessionState = AppSessionState.authenticated;
        }
      } else {
        _sessionState = AppSessionState.unauthenticated;
      }
    } catch (e) {
      _sessionState = AppSessionState.unauthenticated;
    }

    notifyListeners();
  }

  /// Submits dealer phone and password to authenticate.
  Future<bool> login({
    required String phone,
    required String password,
    bool enableBiometrics = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastStatusCode = null;
    notifyListeners();

    final result = await repository.loginResult(
      identifier: phone,
      password: password,
    );

    _isLoading = false;

    switch (result) {
      case Success(data: final session):
        _currentUser = session.user;
        _sessionState = AppSessionState.authenticated;
        if (enableBiometrics) {
          final canBio = await authService.canCheckBiometrics();
          if (canBio) {
            await tokenStorage.setBiometricEnabled(true);
          }
        }
        notifyListeners();
        return true;

      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _lastStatusCode = failure.statusCode;
        notifyListeners();
        return false;
    }
  }

  /// Attempts biometric authentication (fingerprint/face).
  Future<bool> unlockWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await authService.authenticateWithBiometrics();
    _isLoading = false;

    if (success) {
      await authService.clearBackgroundTimestamp();
      _sessionState = AppSessionState.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Biometric verification cancelled or not recognized.';
      notifyListeners();
      return false;
    }
  }

  /// Clears stored session and returns to username/password login.
  Future<void> fallbackToPasswordLogin() async {
    await tokenStorage.clearSession();
    _currentUser = null;
    _sessionState = AppSessionState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Locks session and requires biometric unlock.
  void requireBiometricUnlock() {
    _sessionState = AppSessionState.biometricRequired;
    notifyListeners();
  }

  /// Called when app goes into background to start timeout counter.
  Future<void> recordAppPaused() async {
    await authService.recordAppPaused();
  }

  /// Called when app resumes from background; locks session if timeout exceeded.
  Future<void> handleAppResume() async {
    final shouldLock = await authService.shouldPromptBackgroundBiometricUnlock();
    if (shouldLock && _sessionState == AppSessionState.authenticated) {
      requireBiometricUnlock();
    }
  }

  /// Logs out of session locally and upstream.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await repository.logout();
    _currentUser = null;
    _sessionState = AppSessionState.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  /// Handles 401/403 session revocation from interceptors.
  void handleSessionRevocation(String reason) {
    _currentUser = null;
    _sessionState = AppSessionState.unauthenticated;
    _sessionRevocationReason = reason;
    notifyListeners();
  }

  /// Clears one-shot revocation notice after display.
  void clearRevocationNotice() {
    _sessionRevocationReason = null;
  }
}
