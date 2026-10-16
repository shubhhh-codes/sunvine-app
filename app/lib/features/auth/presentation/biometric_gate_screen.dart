import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_service.dart';
import 'controllers/auth_controller.dart';

/// Presentation screen guarding access when biometric verification is required.
class BiometricGateScreen extends StatefulWidget {
  final AuthService? authService;
  final AuthController? controller;
  final VoidCallback onAuthenticated;
  final VoidCallback onFallbackToLogin;
  final String title;
  final String subtitle;

  const BiometricGateScreen({
    super.key,
    this.authService,
    this.controller,
    required this.onAuthenticated,
    required this.onFallbackToLogin,
    this.title = 'Unlock Sunvine EPC',
    this.subtitle = 'Verify your biometric identity to access dealer console',
  });

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> {
  bool _isPrompting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricPrompt();
    });
  }

  Future<void> _triggerBiometricPrompt() async {
    if (_isPrompting) return;
    setState(() {
      _isPrompting = true;
      _errorMessage = null;
    });

    bool success = false;
    if (widget.controller != null) {
      success = await widget.controller!.unlockWithBiometrics();
    } else if (widget.authService != null) {
      success = await widget.authService!.authenticateWithBiometrics(
        reason: 'Scan fingerprint or face to unlock dealer session',
      );
      if (success) {
        await widget.authService!.clearBackgroundTimestamp();
      }
    }

    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _isPrompting = false;
        _errorMessage = widget.controller?.errorMessage ?? 'Biometric verification cancelled or not recognized.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Glowing Biometric Icon
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fingerprint_rounded,
                      size: 48,
                      color: AppColors.emerald,
                    ),
                    onPressed: _triggerBiometricPrompt,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Center(
                child: Text(
                  widget.title,
                  style: AppTypography.displayMedium,
                ),
              ),
              const SizedBox(height: 8),

              Center(
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.rose.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.rose, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.rose),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SunButton(
                text: 'Authenticate with Biometrics',
                icon: Icons.fingerprint_rounded,
                onPressed: _triggerBiometricPrompt,
              ),

              const SizedBox(height: 12),

              SunButton(
                text: 'Sign In with Password Instead',
                variant: SunButtonVariant.secondary,
                onPressed: widget.onFallbackToLogin,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
