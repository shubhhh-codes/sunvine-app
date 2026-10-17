import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

class QuotationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> quoteData;

  const QuotationDetailScreen({super.key, required this.quoteData});

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final customerName = quoteData['customerName']?.toString() ?? 'Customer';
    final customerPhone = quoteData['customerPhone']?.toString() ?? '';
    final capacityKw =
        double.tryParse(
          quoteData['systemCapacityKW']?.toString() ??
              quoteData['capacityKW']?.toString() ??
              '',
        ) ??
        3.3;
    final panelCount =
        int.tryParse(quoteData['moduleCount']?.toString() ?? '') ?? 6;
    final netPayable =
        double.tryParse(quoteData['netPayable']?.toString() ?? '') ?? 0.0;
    final shareToken =
        quoteData['shareToken']?.toString() ??
        quoteData['share_token']?.toString() ??
        '';
    final dealerName =
        quoteData['dealerFirmName']?.toString() ?? 'Sunvine Partner';

    final proposalUrl = shareToken.isNotEmpty
        ? 'https://sunvinerenewable.com/p/$shareToken'
        : 'https://sunvinerenewable.com/quotations';

    final message =
        '''
નમસ્તે $customerName જી,
Sunvine Renewable Energy તરફથી તમારા સોલાર રૂફટોપ પ્રોજેક્ટનું ઓફિશિયલ પ્રપોઝલ:

☀️ સિસ્ટમ ક્ષમતા: ${capacityKw.toStringAsFixed(1)} kW ($panelCount પેનલ્સ)
💰 ગ્રાહક ચૂકવણી: ₹\u00A0${netPayable.toStringAsFixed(0)} (પીએમ સૂર્ય ઘર સબસિડી બાદ)
📄 ઓફિશિયલ ડિટેઇલ્ડ પ્રપોઝલ જોવા માટે લિંક પર ક્લિક કરો:
$proposalUrl

Sunvine EPC Partner: $dealerName
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
    final quoteId =
        quoteData['id']?.toString() ??
        quoteData['quoteNumber']?.toString() ??
        'SV-PROPOSAL';
    final customerName =
        quoteData['customerName']?.toString() ?? 'Unnamed Customer';
    final customerPhone = quoteData['customerPhone']?.toString() ?? '';
    final city =
        quoteData['location']?.toString() ??
        quoteData['city']?.toString() ??
        'Gujarat';
    final discom = quoteData['discom']?.toString() ?? 'PGVCL';
    final capacityKw =
        double.tryParse(
          quoteData['systemCapacityKW']?.toString() ??
              quoteData['capacityKW']?.toString() ??
              '',
        ) ??
        3.3;
    final panelCount =
        int.tryParse(quoteData['moduleCount']?.toString() ?? '') ?? 6;
    final solarModule =
        quoteData['solarModule']?.toString() ??
        'Tier-1 ALMM Bifacial Dual Glass';
    final inverter =
        quoteData['inverterMake']?.toString() ??
        'Solis / Growatt On-Grid Inverter';
    final structure =
        quoteData['structureType']?.toString() ?? 'Standard Rooftop';
    final totalAmount =
        double.tryParse(quoteData['totalAmount']?.toString() ?? '') ?? 0.0;
    final subsidyAmount =
        double.tryParse(quoteData['subsidyAmount']?.toString() ?? '') ?? 0.0;
    final netPayable =
        double.tryParse(quoteData['netPayable']?.toString() ?? '') ?? 0.0;
    final status = quoteData['status']?.toString() ?? 'Active / Sent';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quoteId,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              customerName,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SunBadge(
                label: status,
                variant: status.toUpperCase().contains('DRAFT')
                    ? SunBadgeVariant.amber
                    : SunBadgeVariant.emerald,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net Payable Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceContainerHigh,
                          AppColors.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NET PAYABLE BY CONSUMER',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SunBadge(
                              label: 'PM Surya Ghar',
                              variant: SunBadgeVariant.emerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹\u00A0${netPayable.toStringAsFixed(0)}',
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gross Project Cost: ₹\u00A0${totalAmount.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Subsidy: - ₹\u00A0${subsidyAmount.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Details Card
                  _buildCard(
                    title: 'Customer & DISCOM Details',
                    icon: Icons.person_outline,
                    children: [
                      _buildRow('Customer Name', customerName),
                      _buildRow('Phone Number', customerPhone),
                      _buildRow('City / Location', city),
                      _buildRow('Utility (DISCOM)', discom),
                      if (quoteData['consumerNumber'] != null)
                        _buildRow(
                          'Consumer Number',
                          quoteData['consumerNumber'].toString(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Technical Specifications Card
                  _buildCard(
                    title: 'System Specifications',
                    icon: Icons.solar_power_outlined,
                    children: [
                      _buildRow(
                        'System Capacity',
                        '${capacityKw.toStringAsFixed(1)} kW',
                      ),
                      _buildRow('Solar Panels', '$panelCount × $solarModule'),
                      _buildRow('Inverter Make', inverter),
                      _buildRow('Mounting Structure', structure),
                      _buildRow(
                        'Generation Benchmark',
                        '${(capacityKw * 1440).round()} kWh / year',
                      ),
                      _buildRow(
                        'Annual Savings',
                        '₹\u00A0${(capacityKw * 1440 * 6.67).round()} / year',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1-Tap WhatsApp Share Button with Tactile Feedback
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.share, size: 20),
                      label: Text(
                        '1-Tap Share Proposal on WhatsApp',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _shareOnWhatsApp(context),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SunCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
