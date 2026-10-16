import 'package:flutter/material.dart';
import '../../../core/network/app_update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/theme/app_typography.dart';
import '../../applications/data/applications_repository.dart';
import '../../applications/presentation/applications_screen.dart';
import '../../applications/presentation/controllers/applications_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dashboard/presentation/more_menu_sheet.dart';
import '../../quotations/data/quotations_repository.dart';
import '../../quotations/presentation/controllers/quotations_controller.dart';
import '../../quotations/presentation/quotations_screen.dart';

/// Top-level shell hosting BottomNavigationBar and the 4 primary tabs.
class MainShellScreen extends StatefulWidget {
  final DealerUser? dealer;
  final AuthService authService;
  final AuthRepository authRepository;
  final AuthController? authController;
  final AppUpdateService appUpdateService;
  final VoidCallback onLogout;
  final VoidCallback onRequireBiometricUnlock;

  const MainShellScreen({
    super.key,
    required this.dealer,
    required this.authService,
    required this.authRepository,
    this.authController,
    required this.appUpdateService,
    required this.onLogout,
    required this.onRequireBiometricUnlock,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final DashboardController _dashboardController;
  late final QuotationsController _quotationsController;
  late final ApplicationsController _applicationsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final dio = widget.authRepository.dio;
    _dashboardController = DashboardController(repository: DashboardRepository(dio: dio));
    _quotationsController = QuotationsController(repository: QuotationsRepository(dio: dio));
    _applicationsController = ApplicationsController(repository: ApplicationsRepository(dio: dio));

    // Non-blocking in-app version update check on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
  }

  Future<void> _checkForAppUpdate() async {
    final updateInfo = await widget.appUpdateService.checkForUpdate();
    if (mounted && updateInfo != null && updateInfo.hasUpdate) {
      AppUpdateService.showUpdateBottomSheet(context, updateInfo);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (widget.authController != null) {
        widget.authController!.recordAppPaused();
      } else {
        widget.authService.recordAppPaused();
      }
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    if (widget.authController != null) {
      await widget.authController!.handleAppResume();
    } else {
      final shouldLock = await widget.authService.shouldPromptBackgroundBiometricUnlock();
      if (shouldLock && mounted) {
        widget.onRequireBiometricUnlock();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardController.dispose();
    _quotationsController.dispose();
    _applicationsController.dispose();
    super.dispose();
  }

  void _onNewQuote() {
    AppLogger.action('Dealer tapped "New Quote" (Wizard)');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create Quotation Stepper (Wizard) will launch in Phase 1.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        dealer: widget.dealer,
        controller: _dashboardController,
        onNewQuotePressed: _onNewQuote,
        onApplicationsPressed: () {
          AppLogger.action('Tapped "View All Applications"');
          setState(() => _currentIndex = 2);
        },
      ),
      QuotationsScreen(
        controller: _quotationsController,
        onNewQuote: _onNewQuote,
      ),
      ApplicationsScreen(
        controller: _applicationsController,
      ),
      MoreMenuSheet(
        dealer: widget.dealer,
        onLogout: widget.onLogout,
        dio: widget.authRepository.dio,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex < 3
          ? FloatingActionButton.extended(
              onPressed: _onNewQuote,
              backgroundColor: AppColors.emerald,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'New Quote',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          const tabNames = ['Dashboard', 'Quotes', 'Applications', 'More'];
          final name = index < tabNames.length ? tabNames[index] : 'Tab $index';
          AppLogger.nav('Switched Tab: $name');
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_outlined),
            activeIcon: Icon(Icons.request_quote_rounded),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            activeIcon: Icon(Icons.menu_open_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
