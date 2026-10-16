import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import 'controllers/ledger_controller.dart';

/// Presentation screen for reviewing dealer financial disbursements and ledger entries.
class LedgerScreen extends StatefulWidget {
  final LedgerController controller;

  const LedgerScreen({super.key, required this.controller});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == LedgerStatus.initial) {
      widget.controller.loadLedger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Dealer Ledger & Payouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => widget.controller.loadLedger(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading && widget.controller.entries.isEmpty) {
              return const SunLoadingIndicator(message: 'Loading financial ledger...');
            }

            if (widget.controller.status == LedgerStatus.error && widget.controller.entries.isEmpty) {
              return SunErrorView(
                message: widget.controller.errorMessage ?? 'Unable to fetch ledger data',
                onRetry: () => widget.controller.loadLedger(),
              );
            }

            final summary = widget.controller.summary;
            final entries = widget.controller.entries;

            return RefreshIndicator(
              color: AppColors.emerald,
              backgroundColor: AppColors.surface,
              onRefresh: () => widget.controller.loadLedger(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (summary != null) ...[
                    SunCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET DISBURSED BALANCE', style: AppTypography.labelSmall),
                          const SizedBox(height: 8),
                          Text('₹${summary.netBalance.toStringAsFixed(2)}', style: AppTypography.monoLarge.copyWith(fontSize: 28, color: AppColors.emerald)),
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Credit (Earnings)', style: AppTypography.bodySmall),
                                  const SizedBox(height: 4),
                                  Text('₹${summary.totalCredit.toStringAsFixed(2)}', style: AppTypography.monoMedium.copyWith(color: AppColors.emerald)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Total Debit (Payouts)', style: AppTypography.bodySmall),
                                  const SizedBox(height: 4),
                                  Text('₹${summary.totalDebit.toStringAsFixed(2)}', style: AppTypography.monoMedium.copyWith(color: AppColors.amber)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text('TRANSACTION ENTRIES', style: AppTypography.labelSmall),
                  const SizedBox(height: 10),

                  if (entries.isEmpty)
                    const SunEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No ledger entries recorded',
                      description: 'Commission disbursements will be logged here.',
                    )
                  else
                    ...entries.map((entry) {
                      final isCredit = entry.entryType == 'CREDIT';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: SunCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.voucherNo, style: AppTypography.monoSmall.copyWith(color: AppColors.emerald)),
                                  SunBadge(
                                    label: entry.entryType,
                                    variant: isCredit ? SunBadgeVariant.emerald : SunBadgeVariant.amber,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(entry.customerName, style: AppTypography.titleMedium)),
                                  Text(
                                    '${isCredit ? "+" : "-"}₹${entry.amount.toStringAsFixed(0)}',
                                    style: AppTypography.monoMedium.copyWith(
                                      color: isCredit ? AppColors.emerald : AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(entry.narration, style: AppTypography.bodySmall),
                              const SizedBox(height: 6),
                              Text('${entry.entryDate} • Balance: ₹${entry.runningBalance.toStringAsFixed(0)}', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
