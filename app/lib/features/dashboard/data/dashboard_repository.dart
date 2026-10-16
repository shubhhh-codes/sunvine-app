import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/components/sun_badge.dart';
import '../domain/dashboard_models.dart';

abstract class IDashboardRepository {
  Future<Result<DashboardOverview>> getDashboardOverview({
    String range = 'Last 30 Days',
  });
}

class DashboardRepository implements IDashboardRepository {
  final Dio dio;

  DashboardRepository({required this.dio});

  @override
  Future<Result<DashboardOverview>> getDashboardOverview({
    String range = 'Last 30 Days',
  }) async {
    try {
      // Parallel fetch from database: quotations and customer applications
      final results = await Future.wait([
        dio.get(ApiEndpoints.quotations, queryParameters: {'limit': 100}),
        dio.get(ApiEndpoints.customerFiles, queryParameters: {'limit': 100}),
      ]);

      final quotesRes = results[0];
      final filesRes = results[1];

      final List<RecentQuoteSummary> recentQuotes = [];
      double totalBusinessValue = 0.0;
      double totalCapacityKw = 0.0;
      int approvedCount = 0;
      int totalQuotesCount = 0;

      if (quotesRes.statusCode == 200 && quotesRes.data != null) {
        final data = quotesRes.data;
        final list = (data is Map && data['quotations'] is List)
            ? data['quotations'] as List
            : [];
        totalQuotesCount = (data is Map && data['total'] is int)
            ? data['total'] as int
            : list.length;

        for (final item in list) {
          if (item is Map) {
            final cap = (item['system_capacity_kw'] as num?)?.toDouble() ?? 0.0;
            final amt = (item['total_amount'] as num?)?.toDouble() ?? 0.0;
            final statusStr = (item['status'] as String? ?? 'DRAFT').toUpperCase();

            totalBusinessValue += amt;
            totalCapacityKw += cap;

            if (statusStr == 'APPROVED' ||
                statusStr == 'CONFIRMED' ||
                statusStr == 'CONVERTED') {
              approvedCount++;
            }

            final variant = switch (statusStr) {
              'APPROVED' => SunBadgeVariant.emerald,
              'CONFIRMED' => SunBadgeVariant.cyan,
              'IN REVIEW' => SunBadgeVariant.amber,
              _ => SunBadgeVariant.slate,
            };

            if (recentQuotes.length < 5) {
              recentQuotes.add(
                RecentQuoteSummary(
                  id: item['id']?.toString() ?? '',
                  customerName:
                      item['customer_name']?.toString() ?? 'Prospective Client',
                  capacity: '${cap.toStringAsFixed(1)} kW',
                  amount: '₹${amt.toStringAsFixed(0)}',
                  date: item['created_at'] != null
                      ? (item['created_at'] as String).substring(0, 10)
                      : 'Recent',
                  status: statusStr,
                  badgeVariant: variant,
                ),
              );
            }
          }
        }
      }

      // Customer applications count from customer_files table
      int totalFilesCount = 0;
      int activeFilesCount = 0;

      if (filesRes.statusCode == 200 && filesRes.data != null) {
        final fData = filesRes.data;
        final fList = (fData is Map && fData['files'] is List)
            ? fData['files'] as List
            : [];
        totalFilesCount = (fData is Map && fData['total'] is int)
            ? fData['total'] as int
            : fList.length;

        for (final f in fList) {
          if (f is Map) {
            final st = (f['status'] as String? ?? '').toLowerCase();
            if (!st.contains('cancelled') && !st.contains('deleted')) {
              activeFilesCount++;
            }
          }
        }
      }

      // Format authentic KPI metrics matching web app format
      final String formattedValue = totalBusinessValue >= 10000000
          ? '₹${(totalBusinessValue / 10000000).toStringAsFixed(2)} Cr'
          : (totalBusinessValue >= 100000
              ? '₹${(totalBusinessValue / 100000).toStringAsFixed(2)} L'
              : '₹${totalBusinessValue.toStringAsFixed(0)}');

      final String conversionRate = totalQuotesCount > 0
          ? '${((approvedCount / totalQuotesCount) * 100).toStringAsFixed(0)}%'
          : '0%';

      final kpis = [
        DashboardKpi(
          title: 'BUSINESS VALUE',
          value: formattedValue,
          subtitle: totalQuotesCount > 0
              ? '$totalQuotesCount proposals generated'
              : '0 proposals generated',
          icon: Icons.currency_rupee_rounded,
          accentColor: AppColors.emerald,
        ),
        DashboardKpi(
          title: 'SIZING VOLUME',
          value: '${totalCapacityKw.toStringAsFixed(1)} kW',
          subtitle: totalQuotesCount > 0
              ? '$totalQuotesCount systems quoted'
              : '0 kW quoted',
          icon: Icons.bolt_rounded,
          accentColor: AppColors.teal,
        ),
        DashboardKpi(
          title: 'APPLICATIONS',
          value: '$totalFilesCount',
          subtitle: totalFilesCount > 0
              ? '$activeFilesCount in progress'
              : '0 active files',
          icon: Icons.folder_shared_rounded,
          accentColor: AppColors.cyan,
        ),
        DashboardKpi(
          title: 'CONVERSION',
          value: conversionRate,
          subtitle: totalQuotesCount > 0
              ? '$approvedCount approved'
              : 'Ready to quote',
          icon: Icons.pie_chart_outline_rounded,
          accentColor: AppColors.amber,
        ),
      ];

      return Result.success(
        DashboardOverview(kpis: kpis, recentQuotes: recentQuotes),
      );
    } catch (e) {
      // Fallback with structured error or default telemetry
      return Result.failure(
        ServerFailure('Failed to load dashboard overview: $e'),
      );
    }
  }
}
