import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_models.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../ledger/presentation/controllers/ledger_controller.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../settings/presentation/diagnostics_screen.dart';

/// Presentation sheet for secondary navigation, settings, ledger, and sign out.
class MoreMenuSheet extends StatelessWidget {
  final DealerUser? dealer;
  final VoidCallback onLogout;
  final Dio? dio;

  const MoreMenuSheet({
    super.key,
    required this.dealer,
    required this.onLogout,
    this.dio,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Menu & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            // Dealer Profile Card
            SunCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.2),
                    child: Text(
                      dealer?.contactPerson.isNotEmpty == true
                          ? dealer!.contactPerson[0].toUpperCase()
                          : 'D',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.emerald),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dealer?.contactPerson ?? 'Dealer Principal', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(dealer?.firmName ?? 'Authorized Partner', style: AppTypography.bodySmall),
                        Text(dealer?.mobile ?? '', style: AppTypography.monoSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('FINANCE & PERFORMANCE'),
            _buildMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Dealer Ledger & Payouts',
              subtitle: 'Commission disbursements and margin records',
              onTap: () {
                if (dio != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LedgerScreen(
                        controller: LedgerController(
                          repository: LedgerRepository(dio: dio!),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.trending_up_rounded,
              title: 'Performance & Sizing Targets',
              subtitle: 'Monthly conversion goals and tier incentives',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Performance analytics available in Phase 1.')),
                );
              },
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('SUPPORT & MASTER DATA'),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Documentation Master Hub',
              subtitle: 'Consumer document check-rules and guidelines',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Documentation hub opening soon.')),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'Contact HQ Desk',
              subtitle: dealer?.assignedStaffName ?? 'Operations Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Staff Desk: ${dealer?.assignedStaffName ?? "Sunvine HQ"}')),
                );
              },
            ),
            const SizedBox(height: 20),

            if (dio != null) ...[
              _buildMenuItem(
                icon: Icons.bug_report_outlined,
                title: 'Diagnostics & Gateway Health',
                subtitle: 'Verify connection, environment, and health status',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiagnosticsScreen(dio: dio!),
                    ),
                  );
                },
              ),
            ],
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'End dealer session on this device',
              isDanger: true,
              onTap: onLogout,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SunCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDanger ? AppColors.rose : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDanger ? AppColors.rose : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDanger ? AppColors.rose.withValues(alpha: 0.6) : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
