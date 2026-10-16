import 'package:flutter/material.dart';
import '../../../core/theme/components/sun_badge.dart';

/// Representation of a key performance indicator tile on the dashboard.
class DashboardKpi {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const DashboardKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

/// Representation of a recent quotation item on the dashboard feed.
class RecentQuoteSummary {
  final String id;
  final String customerName;
  final String capacity;
  final String amount;
  final String date;
  final String status;
  final SunBadgeVariant badgeVariant;

  const RecentQuoteSummary({
    required this.id,
    required this.customerName,
    required this.capacity,
    required this.amount,
    required this.date,
    required this.status,
    required this.badgeVariant,
  });
}

/// Aggregated dashboard overview snapshot.
class DashboardOverview {
  final List<DashboardKpi> kpis;
  final List<RecentQuoteSummary> recentQuotes;

  const DashboardOverview({
    required this.kpis,
    required this.recentQuotes,
  });
}
