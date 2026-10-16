import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/system_repository.dart';
import 'controllers/diagnostics_controller.dart';

/// Presentation screen for inspecting environment parameters and gateway connectivity.
class DiagnosticsScreen extends StatefulWidget {
  final Dio? dio;
  final DiagnosticsController? controller;

  const DiagnosticsScreen({
    super.key,
    this.dio,
    this.controller,
  });

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final DiagnosticsController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else if (widget.dio != null) {
      _controller = DiagnosticsController(
        repository: SystemRepository(dio: widget.dio!),
      );
    } else {
      throw ArgumentError('Either controller or dio must be provided to DiagnosticsScreen');
    }

    if (_controller.status == DiagnosticsStatus.initial) {
      _controller.fetchHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Diagnostics & System Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.fetchHealth(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final healthData = _controller.healthData;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SunCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ENVIRONMENT CONFIGURATION', style: AppTypography.labelSmall),
                      const SizedBox(height: 12),
                      _buildRow('GATEWAY_BASE_URL', ApiEndpoints.baseUrl),
                      const Divider(height: 20, color: AppColors.border),
                      _buildRow('APP_ENV', ApiEndpoints.appEnv),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SunCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GATEWAY HEALTH STATUS (/v1/health)', style: AppTypography.labelSmall),
                          if (healthData != null)
                            SunBadge(
                              label: healthData['ok'] == true ? 'HEALTHY' : 'DEGRADED',
                              variant: healthData['ok'] == true
                                  ? SunBadgeVariant.emerald
                                  : SunBadgeVariant.rose,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_controller.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_controller.status == DiagnosticsStatus.error)
                        Text(
                          'Error: ${_controller.errorMessage}',
                          style: const TextStyle(color: AppColors.rose),
                        )
                      else if (healthData != null) ...[
                        _buildRow('Overall OK', healthData['ok']?.toString() ?? 'false'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Supabase Reachable', healthData['supabaseReachable']?.toString() ?? 'false'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('D1 Database', healthData['d1']?.toString() ?? 'false'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Secrets Configured', healthData['secretsConfigured']?.toString() ?? 'false'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Worker Environment', healthData['env']?.toString() ?? 'unknown'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Worker Version', healthData['version']?.toString() ?? 'unknown'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Security Invariant: No tokens, passwords, or secrets are ever displayed on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(value, style: AppTypography.monoSmall.copyWith(color: AppColors.emerald)),
      ],
    );
  }
}
