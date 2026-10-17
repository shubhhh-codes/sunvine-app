import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_models.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/metric_card_widget.dart';
import 'widgets/recent_quote_tile_widget.dart';

/// Presentation screen for dealer business overview, KPIs, and quick actions.
class DashboardScreen extends StatefulWidget {
  final DealerUser? dealer;
  final DashboardController? controller;
  final VoidCallback onNewQuotePressed;
  final VoidCallback onApplicationsPressed;

  const DashboardScreen({
    super.key,
    required this.dealer,
    this.controller,
    required this.onNewQuotePressed,
    required this.onApplicationsPressed,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller!;
    if (_controller.status == DashboardStatus.initial) {
      _controller.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealer = widget.dealer;
    final firmName = dealer?.firmName.isNotEmpty == true
        ? dealer!.firmName
        : 'Solar EPC Partner';
    final dealerCode = dealer?.dealerCode.isNotEmpty == true
        ? dealer!.dealerCode
        : 'DLR-GUJ';
    final staffName = dealer?.assignedStaffName ?? 'HQ Operations Desk';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emerald,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await _controller.loadDashboard();
          },
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dealer Firm Header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.energyGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firmName,
                                    style: AppTypography.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        dealerCode,
                                        style: AppTypography.monoSmall.copyWith(
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          staffName,
                                          style: AppTypography.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SunBadge(
                              label: 'ONLINE',
                              variant: SunBadgeVariant.emerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Time Range Filter Pills
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _controller.timeRanges.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final range = _controller.timeRanges[index];
                              final isSelected =
                                  range == _controller.selectedRange;
                              return ChoiceChip(
                                label: Text(range),
                                selected: isSelected,
                                labelStyle: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                selectedColor: AppColors.emerald600,
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : AppColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (val) {
                                  if (val) _controller.setTimeRange(range);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2x2 KPI Telemetry Grid
                        if (_controller.isLoading &&
                            _controller.overview == null)
                          const SunLoadingIndicator(
                            message: 'Loading telemetry...',
                          )
                        else if (_controller.status == DashboardStatus.error &&
                            _controller.overview == null)
                          SunErrorView(
                            message:
                                _controller.errorMessage ??
                                'Unable to fetch dashboard telemetry',
                            onRetry: () => _controller.loadDashboard(),
                          )
                        else ...[
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                            children: (_controller.overview?.kpis ?? []).map((
                              kpi,
                            ) {
                              return MetricCardWidget(kpi: kpi);
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Quick Action Cards
                        Row(
                          children: [
                            Expanded(
                              child: SunCard(
                                onTap: widget.onNewQuotePressed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: AppColors.emerald,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create Quote',
                                            style: AppTypography.labelLarge,
                                          ),
                                          Text(
                                            '4-step wizard',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SunCard(
                                onTap: widget.onApplicationsPressed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyan.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.folder_open_rounded,
                                        color: AppColors.cyan,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Applications',
                                            style: AppTypography.labelLarge,
                                          ),
                                          Text(
                                            'Active pipeline',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Recent Proposals Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Quotations',
                              style: AppTypography.titleMedium,
                            ),
                            TextButton(
                              onPressed: widget.onApplicationsPressed,
                              child: Text(
                                'View All',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Recent Quotations Feed
                        if (_controller.overview?.recentQuotes.isEmpty ?? true)
                          const SunEmptyState(
                            icon: Icons.description_outlined,
                            title: 'No quotations found',
                            description: 'Create your first proposal to see it listed here.',
                          )
                        else
                          ...(_controller.overview?.recentQuotes ?? []).map((
                            q,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: RecentQuoteTileWidget(quote: q),
                            );
                          }),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
