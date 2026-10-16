import 'package:flutter/material.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_repository.dart';
import '../domain/auth_service.dart';
import 'controllers/auth_controller.dart';

/// Presentation screen for dealer phone and password authentication.
class LoginScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final AuthService? authService;
  final TokenStorage? tokenStorage;
  final AuthController? controller;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    this.authRepository,
    this.authService,
    this.tokenStorage,
    this.controller,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _biometricEnabled = true;
  bool _hasBiometricsHardware = false;

  String? _phoneError;
  String? _passwordError;

  AuthController get _controller => widget.controller!;

  @override
  void initState() {
    super.initState();
    _checkHardwareBiometrics();
  }

  Future<void> _checkHardwareBiometrics() async {
    if (widget.authService != null) {
      final available = await widget.authService!.canCheckBiometrics();
      final pref = widget.tokenStorage != null ? await widget.tokenStorage!.isBiometricEnabled() : false;
      if (mounted) {
        setState(() {
          _hasBiometricsHardware = available;
          _biometricEnabled = available ? pref : false;
        });
      }
    }
  }

  void _validateInputs() {
    setState(() {
      _phoneError = null;
      _passwordError = null;

      final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty) {
        _phoneError = 'Please enter your registered mobile number.';
      } else if (phone.length != 10) {
        _phoneError = 'Mobile number must be exactly 10 digits.';
      }

      final pass = _passwordController.text;
      if (pass.isEmpty) {
        _passwordError = 'Please enter your password.';
      } else if (pass.length > 128) {
        _passwordError = 'Password exceeds maximum length.';
      }
    });
  }

  Future<void> _handleLogin() async {
    _validateInputs();
    if (_phoneError != null || _passwordError != null) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    AppLogger.action('Dealer tapped "Sign In" (Mobile: $phone)');

    final success = await _controller.login(
      phone: phone,
      password: password,
      enableBiometrics: _biometricEnabled,
    );

    if (mounted && success) {
      widget.onLoginSuccess();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isLoading = _controller.isLoading;
        final generalError = _controller.errorMessage;
        final lastStatusCode = _controller.lastStatusCode;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glowing Logo & Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.energyGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.solar_power_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand Headline
                    Center(
                      child: Text(
                        'Sunvine EPC',
                        style: AppTypography.displayMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: SunBadge(
                        label: 'GUJARAT DEALER NETWORK',
                        variant: SunBadgeVariant.emerald,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // General Error Alert (with distinction between 401 & 403)
                    if (generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: lastStatusCode == 403
                              ? AppColors.amber.withValues(alpha: 0.12)
                              : AppColors.rose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: lastStatusCode == 403 ? AppColors.amber : AppColors.rose,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              lastStatusCode == 403
                                  ? Icons.warning_amber_rounded
                                  : Icons.error_outline_rounded,
                              color: lastStatusCode == 403 ? AppColors.amber : AppColors.rose,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lastStatusCode == 403
                                        ? 'Account Access Restricted (403)'
                                        : lastStatusCode == 401
                                            ? 'Invalid Credentials (401)'
                                            : 'Authentication Error',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: lastStatusCode == 403
                                          ? AppColors.amber
                                          : AppColors.rose,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    generalError,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Mobile Number Input
                    SunInput(
                      controller: _phoneController,
                      label: 'Registered Mobile Number',
                      hintText: '10-digit mobile (e.g. 9876543210)',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      errorText: _phoneError,
                      prefixIcon: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password Input
                    SunInput(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Enter console password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      errorText: _passwordError,
                      onSubmitted: (_) => _handleLogin(),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biometrics Quick-Toggle
                    if (_hasBiometricsHardware) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.fingerprint_rounded,
                                color: AppColors.emerald,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enable Biometric Unlock',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                          Switch(
                            value: _biometricEnabled,
                            activeThumbColor: AppColors.emerald,
                            activeTrackColor: AppColors.emerald.withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.textMuted,
                            inactiveTrackColor: AppColors.border,
                            onChanged: (val) {
                              setState(() {
                                _biometricEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sign In Button
                    SunButton(
                      text: 'Sign In to Console',
                      isLoading: isLoading,
                      icon: Icons.login_rounded,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),

                    // Support Helpdesk Note
                    Center(
                      child: Text(
                        'Need assistance? Contact Sunvine Operations Desk at support@sunvine.in',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
