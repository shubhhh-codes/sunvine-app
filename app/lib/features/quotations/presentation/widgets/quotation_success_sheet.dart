import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';

class QuotationSuccessSheet extends StatelessWidget {
  final String quoteId;
  final String customerName;
  final String customerPhone;
  final double capacityKw;
  final int panelCount;
  final double netPayable;
  final String shareToken;
  final String dealerName;
  final bool isOfflineQueued;
  final VoidCallback onViewDetails;
  final VoidCallback onDone;

  const QuotationSuccessSheet({
    super.key,
    required this.quoteId,
    required this.customerName,
    required this.customerPhone,
    required this.capacityKw,
    required this.panelCount,
    required this.netPayable,
    required this.shareToken,
    required this.dealerName,
    this.isOfflineQueued = false,
    required this.onViewDetails,
    required this.onDone,
  });

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final proposalUrl = shareToken.isNotEmpty
        ? 'https://sunvinerenewable.com/p/$shareToken'
        : 'https://sunvinerenewable.com/quotations';

    final message =
        '''
નમસ્તે $customerName જી,
Sunvine Renewable Energy તરફથી તમારા સોલાર રૂફટોપ પ્રોજેક્ટનું ઓફિશિયલ પ્રપોઝલ તૈયાર છે:

☀️ સિસ્ટમ: ${capacityKw.toStringAsFixed(1)} kW ($panelCount પેનલ્સ)
💰 નેટ કિંમત: ₹\u00A0${netPayable.toStringAsFixed(0)} (પીએમ સૂર્ય ઘર સબસિડી બાદ)
📄 ઓફિશિયલ પ્રપોઝલ જોવા માટે લિંક પર ક્લિક કરો:
$proposalUrl

Sunvine Authorized EPC Partner: $dealerName
'''
            .trim();

    final encoded = Uri.encodeComponent(message);
    final cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final targetPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=$targetPhone&text=$encoded',
    );
    final webUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$targetPhone&text=$encoded',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOfflineQueued
                        ? AppColors.amber.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOfflineQueued
                        ? Icons.cloud_queue_rounded
                        : Icons.check_circle_rounded,
                    color: isOfflineQueued
                        ? AppColors.amber
                        : AppColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  isOfflineQueued
                      ? 'Quotation Secured Locally!'
                      : 'Quotation Generated Successfully!',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isOfflineQueued
                      ? 'Device is currently offline. This quote will automatically sync to the cloud as soon as internet is available.'
                      : 'Official proposal #$quoteId is ready for $customerName.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proposal ID',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            quoteId,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Net Payable',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹\u00A0${netPayable.toStringAsFixed(0)}',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1-Tap WhatsApp Share Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF25D366,
                      ), // Official WhatsApp Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.share, size: 20),
                    label: Text(
                      '1-Tap Share on WhatsApp',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => _shareOnWhatsApp(context),
                  ),
                ),
                const SizedBox(height: 12),

                // View Details and Done
                Row(
                  children: [
                    Expanded(
                      child: SunButton(
                        text: 'View Details',
                        variant: SunButtonVariant.secondary,
                        onPressed: onViewDetails,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SunButton(
                        text: 'Done',
                        variant: SunButtonVariant.secondary,
                        onPressed: onDone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
