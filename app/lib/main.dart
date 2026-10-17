import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/network/app_update_service.dart';
import 'core/network/token_storage.dart';
import 'core/config/app_config.dart';
import 'core/services/device_info_service.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/app_nav_observer.dart';
import 'core/state/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/widgets.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/auth_service.dart';
import 'features/auth/presentation/biometric_gate_screen.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/main_shell_screen.dart';
import 'core/services/auto_sync_service.dart';
import 'features/quotations/data/quotations_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.state('App Bootstrapped | Env: ${AppConfig.envName} | BaseUrl: ${AppConfig.gatewayBaseUrl}');
  setupDependencies();
  runApp(const SunvineEpcApp());
}

/// Sets up singletons and dependency injection container.
void setupDependencies({bool force = false}) {
  if (!force && ServiceLocator.isRegistered<AuthController>()) {
    return;
  }
  if (force) {
    ServiceLocator.reset();
  }

  final tokenStorage = TokenStorage();
  final deviceInfoService = DeviceInfoService();

  late final ApiClient apiClient;

  apiClient = ApiClient(
    tokenStorage: tokenStorage,
    onSessionRevoked: (reason) {
      if (ServiceLocator.isRegistered<AuthController>()) {
        ServiceLocator.get<AuthController>().handleSessionRevocation(reason);
      }
    },
    getDeviceId: () => deviceInfoService.getDeviceId(),
  );

  final authRepository = AuthRepository(
    dio: apiClient.dio,
    tokenStorage: tokenStorage,
    deviceInfoService: deviceInfoService,
  );

  final authService = AuthService(
    repository: authRepository,
    tokenStorage: tokenStorage,
  );

  final authController = AuthController(
    repository: authRepository,
    authService: authService,
    tokenStorage: tokenStorage,
  );

  final appUpdateService = AppUpdateService(dio: apiClient.dio);
  final quotationsRepository = QuotationsRepository(dio: apiClient.dio);
  final autoSyncService = AutoSyncService(quotationsRepository: quotationsRepository);

  ServiceLocator.registerSingleton<TokenStorage>(tokenStorage);
  ServiceLocator.registerSingleton<DeviceInfoService>(deviceInfoService);
  ServiceLocator.registerSingleton<ApiClient>(apiClient);
  ServiceLocator.registerSingleton<AuthRepository>(authRepository);
  ServiceLocator.registerSingleton<AuthService>(authService);
  ServiceLocator.registerSingleton<AuthController>(authController);
  ServiceLocator.registerSingleton<AppUpdateService>(appUpdateService);
  ServiceLocator.registerSingleton<IQuotationsRepository>(quotationsRepository);
  ServiceLocator.registerSingleton<AutoSyncService>(autoSyncService);
}

/// Root widget for Sunvine EPC Dealer Mobile Application.
class SunvineEpcApp extends StatefulWidget {
  const SunvineEpcApp({super.key});

  @override
  State<SunvineEpcApp> createState() => _SunvineEpcAppState();
}

class _SunvineEpcAppState extends State<SunvineEpcApp> {
  late final AuthController _authController;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    if (!ServiceLocator.isRegistered<AuthController>()) {
      setupDependencies();
    }
    _authController = ServiceLocator.get<AuthController>();
    _authController.initialize();
  }

  void _showNotice(String message, {bool isError = true}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.rose : AppColors.emerald,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunvine EPC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [AppNavObserver()],
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: ListenableBuilder(
        listenable: _authController,
        builder: (context, _) {
          if (_authController.sessionRevocationReason != null) {
            final reason = _authController.sessionRevocationReason!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showNotice(reason, isError: true);
              _authController.clearRevocationNotice();
            });
          }

          return _buildCurrentScreen(_authController.sessionState);
        },
      ),
    );
  }

  Widget _buildCurrentScreen(AppSessionState sessionState) {
    switch (sessionState) {
      case AppSessionState.initialChecking:
        return const Scaffold(
          body: Center(
            child: SunLoadingIndicator(message: 'Initializing session...'),
          ),
        );

      case AppSessionState.unauthenticated:
        return LoginScreen(
          controller: _authController,
          authRepository: ServiceLocator.get<AuthRepository>(),
          authService: ServiceLocator.get<AuthService>(),
          tokenStorage: ServiceLocator.get<TokenStorage>(),
          onLoginSuccess: () {},
        );

      case AppSessionState.biometricRequired:
        return BiometricGateScreen(
          controller: _authController,
          authService: ServiceLocator.get<AuthService>(),
          onAuthenticated: () {},
          onFallbackToLogin: () => _authController.fallbackToPasswordLogin(),
        );

      case AppSessionState.authenticated:
        return MainShellScreen(
          dealer: _authController.currentUser,
          authService: ServiceLocator.get<AuthService>(),
          authRepository: ServiceLocator.get<AuthRepository>(),
          authController: _authController,
          appUpdateService: ServiceLocator.get<AppUpdateService>(),
          onLogout: () => _authController.logout(),
          onRequireBiometricUnlock: () => _authController.requireBiometricUnlock(),
        );
    }
  }
}
