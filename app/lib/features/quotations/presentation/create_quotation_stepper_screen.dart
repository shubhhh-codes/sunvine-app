import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/state/service_locator.dart';
import '../../auth/domain/auth_models.dart';
import 'controllers/create_quotation_controller.dart';
import 'steps/step1_customer_discom.dart';
import 'steps/step2_solar_sizing.dart';
import 'steps/step3_pricing_margin.dart';
import 'steps/step4_review_submit.dart';
import 'widgets/quotation_success_sheet.dart';
import 'quotation_detail_screen.dart';

class CreateQuotationStepperScreen extends StatefulWidget {
  final CreateQuotationController? controller;

  const CreateQuotationStepperScreen({super.key, this.controller});

  @override
  State<CreateQuotationStepperScreen> createState() =>
      _CreateQuotationStepperScreenState();
}

class _CreateQuotationStepperScreenState
    extends State<CreateQuotationStepperScreen> {
  late final CreateQuotationController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _ownsController = true;
      final dealer =
          ServiceLocator.authController.currentUser ??
          DealerUser(
            id: 'SV-DLR-0104',
            dealerCode: 'SV-DLR-0104',
            firmName: 'Sunvine Partner Dealer',
            contactPerson: 'Authorized Dealer',
            mobile: '9023370474',
            city: 'Rajkot',
            state: 'Gujarat',
            discom: 'PGVCL',
            tier: 'Gold',
            maxMarginCapPerKw: 5000.0,
            assignedStaffId: 'STF-DIRECT',
            category: 'Margin Based',
            pricingConfig: const {},
          );

      _controller = CreateQuotationController(
        repository: ServiceLocator.quotationsRepository,
        currentUser: dealer,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSaveDraft() async {
    final result = await _controller.saveAsDraft();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully to local storage.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Could not save draft.'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _handleSubmitOnline() async {
    final result = await _controller.submitQuotation();
    if (!mounted) return;

    if (result != null) {
      final isOfflineQueued = result['offlineQueued'] == true;
      final quoteObj = result['quotation'] as Map<String, dynamic>? ?? result;
      final quoteId =
          quoteObj['id']?.toString() ??
          quoteObj['quoteNumber']?.toString() ??
          'SV-PROPOSAL';
      final shareToken =
          quoteObj['share_token']?.toString() ??
          quoteObj['shareToken']?.toString() ??
          '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => QuotationSuccessSheet(
          quoteId: quoteId,
          customerName: _controller.customerName,
          customerPhone: _controller.customerPhone,
          capacityKw: _controller.selectedCapacityKw,
          panelCount: _controller.panelCount,
          netPayable: _controller.finalTotals['netPayable'] ?? 0.0,
          shareToken: shareToken,
          dealerName: _controller.currentUser.firmName,
          isOfflineQueued: isOfflineQueued,
          onViewDetails: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => QuotationDetailScreen(quoteData: quoteObj),
              ),
            );
          },
          onDone: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop(true);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Submission failed.'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SunLoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dynamic catalog & pricing matrix...',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        final bool isKeyboardOpen =
            MediaQuery.viewInsetsOf(context).bottom > 80;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_controller.currentStep > 0) {
              _controller.previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () {
                  if (_controller.currentStep > 0) {
                    _controller.previousStep();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Solar Quotation',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _controller.isMarginBased
                      ? 'Turnkey Partner Flow (${_controller.currentUser.tier})'
                      : 'Kit-Based EPC Flow (${_controller.currentUser.tier})',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    // Step Progress Indicator Bar
                    _buildStepIndicator(),

                    // Active Step Body with Smooth Transition
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_controller.currentStep),
                          child: IndexedStack(
                            index: _controller.currentStep,
                            children: [
                              Step1CustomerDiscom(controller: _controller),
                              Step2SolarSizing(controller: _controller),
                              Step3PricingMargin(controller: _controller),
                              Step4ReviewSubmit(
                                controller: _controller,
                                onSaveDraft: _handleSaveDraft,
                                onSubmitOnline: _handleSubmitOnline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar (Steps 0 - 2, hidden when keyboard is open)
                    if (_controller.currentStep < 3 && !isKeyboardOpen)
                      _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildStepIndicator() {
    final stepTitles = ['Customer', 'Solar Tech', 'Pricing', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = _controller.currentStep > index;
          final isCurrent = _controller.currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _controller.goToStep(index);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary
                                : (isCompleted
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.surfaceContainerHigh),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isCurrent || isCompleted)
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.primary,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stepTitles[index],
                          style: AppTypography.labelSmall.copyWith(
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 16,
                    height: 1,
                    color: isCompleted ? AppColors.primary : AppColors.border,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _handleContinueStep() {
    if (_controller.isNavigating) return;
    if (_controller.currentStep == 0) {
      final valid = _controller.validateStep1();
      if (!valid) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Please complete all required customer details.',
          TextDirection.ltr,
        );
        return;
      }
    }
    _controller.nextStep();
  }

  Widget _buildBottomBar() {
    final bool isStep0 = _controller.currentStep == 0;
    final bool isSubdued = isStep0 && !_controller.isStep1Filled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_controller.currentStep > 0) ...[
              Expanded(
                child: SunButton(
                  text: 'Back',
                  variant: SunButtonVariant.secondary,
                  onPressed: _controller.previousStep,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: SunButton(
                text: 'Continue',
                variant: SunButtonVariant.primary,
                isSubdued: isSubdued,
                icon: Icons.arrow_forward,
                onPressed: _handleContinueStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
