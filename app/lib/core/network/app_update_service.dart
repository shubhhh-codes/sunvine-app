import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/api_endpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/components/sun_button.dart';
import '../theme/components/sun_badge.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final String apkUrl;
  final String notes;
  final bool hasUpdate;
  final bool isMandatory;

  AppUpdateInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.apkUrl,
    required this.notes,
    required this.hasUpdate,
    required this.isMandatory,
  });
}

class AppUpdateService {
  final Dio dio;

  AppUpdateService({required this.dio});

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = pkg.version;

      final res = await dio.get(
        ApiEndpoints.appVersion,
        queryParameters: {'platform': 'android'},
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final latest = (data['latest'] as String?) ?? currentVersion;
        final minSupported = (data['minSupported'] as String?) ?? currentVersion;
        final apkUrl = (data['apkUrl'] as String?) ?? '';
        final notes = (data['notes'] as String?) ?? '';

        final hasUpdate = _compareVersions(latest, currentVersion) > 0;
        final isMandatory = _compareVersions(minSupported, currentVersion) > 0;

        return AppUpdateInfo(
          latestVersion: latest,
          minSupportedVersion: minSupported,
          apkUrl: apkUrl,
          notes: notes,
          hasUpdate: hasUpdate,
          isMandatory: isMandatory,
        );
      }
    } catch (_) {
      // Non-blocking telemetry
    }
    return null;
  }

  int _compareVersions(String v1, String v2) {
    try {
      final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final num1 = i < p1.length ? p1[i] : 0;
        final num2 = i < p2.length ? p2[i] : 0;
        if (num1 > num2) return 1;
        if (num1 < num2) return -1;
      }
    } catch (_) {}
    return 0;
  }

  static void showUpdateBottomSheet(BuildContext context, AppUpdateInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: !info.isMandatory,
      enableDrag: !info.isMandatory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Update Available', style: AppTypography.titleLarge),
                  SunBadge(
                    label: 'v${info.latestVersion}',
                    variant: SunBadgeVariant.emerald,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                info.notes.isNotEmpty
                    ? info.notes
                    : 'A newer, more stable version of Sunvine EPC Dealer Mobile is available.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              SunButton(
                text: 'Download & Install Update',
                icon: Icons.download_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  // Trigger direct download / open URL
                },
              ),
              if (!info.isMandatory) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Remind Me Later',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
