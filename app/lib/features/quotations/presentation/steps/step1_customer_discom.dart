import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/create_quotation_controller.dart';

/// Step 1.1: Customer Details
/// Exact match with Web Partner Portal (Card 1: Customer Details)
/// Fully compliant with UX_AUDIT.md and FLUTTER_UX_RULES.md
class Step1CustomerDiscom extends StatefulWidget {
  final CreateQuotationController controller;

  const Step1CustomerDiscom({super.key, required this.controller});

  @override
  State<Step1CustomerDiscom> createState() => _Step1CustomerDiscomState();
}

class _Step1CustomerDiscomState extends State<Step1CustomerDiscom> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _locationFocus;

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();

  int _lastSeenValidationEpoch = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.customerName);
    _phoneCtrl = TextEditingController(text: widget.controller.customerPhone);
    _locationCtrl = TextEditingController(
      text: widget.controller.customerLocation,
    );

    _nameFocus = FocusNode();
    _phoneFocus = FocusNode();
    _locationFocus = FocusNode();

    _lastSeenValidationEpoch = widget.controller.step1ValidationEpoch;
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    // Keep local text controllers in sync with controller state ONLY if changed externally
    if (_nameCtrl.text != widget.controller.customerName) {
      _nameCtrl.value = _nameCtrl.value.copyWith(
        text: widget.controller.customerName,
        selection: TextSelection.collapsed(
          offset: widget.controller.customerName.length,
        ),
      );
    }
    if (_phoneCtrl.text != widget.controller.customerPhone) {
      _phoneCtrl.value = _phoneCtrl.value.copyWith(
        text: widget.controller.customerPhone,
        selection: TextSelection.collapsed(
          offset: widget.controller.customerPhone.length,
        ),
      );
    }
    if (_locationCtrl.text != widget.controller.customerLocation) {
      _locationCtrl.value = _locationCtrl.value.copyWith(
        text: widget.controller.customerLocation,
        selection: TextSelection.collapsed(
          offset: widget.controller.customerLocation.length,
        ),
      );
    }

    // Auto-focus and scroll to first invalid field ONLY when a new validation attempt just failed (e.g. Continue tap)
    if (widget.controller.step1ValidationEpoch != _lastSeenValidationEpoch &&
        mounted) {
      _lastSeenValidationEpoch = widget.controller.step1ValidationEpoch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusAndScrollToFirstInvalid();
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _focusAndScrollToFirstInvalid() {
    if (widget.controller.nameError != null) {
      _nameFocus.requestFocus();
      _scrollToKey(_nameKey);
    } else if (widget.controller.phoneError != null) {
      _phoneFocus.requestFocus();
      _scrollToKey(_phoneKey);
    } else if (widget.controller.locationError != null) {
      _locationFocus.requestFocus();
      _scrollToKey(_locationKey);
    }
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        alignment: 0.10,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Customer Details Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Customer Details + STEP 1.1 Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Details',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Site contact & regional grid jurisdictional data',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP 1.1',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // Field 1: Customer Name *
                _buildFieldLabel('Customer Name', isRequired: true),
                const SizedBox(height: 6),
                _buildTextField(
                  containerKey: _nameKey,
                  focusNode: _nameFocus,
                  controller: _nameCtrl,
                  hintText: "Enter customer's full name",
                  prefixIcon: Icons.badge_outlined,
                  errorText: controller.nameError,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                  onChanged: (val) {
                    controller.setCustomerName(val);
                  },
                ),
                const SizedBox(height: 16),

                // Fields 2 & 3: Mobile Number & Installation City / Pincode
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;

                    final phoneWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Mobile Number', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextField(
                          containerKey: _phoneKey,
                          focusNode: _phoneFocus,
                          controller: _phoneCtrl,
                          hintText: '10-digit mobile number',
                          prefixIcon: Icons.phone_outlined,
                          errorText: controller.phoneError,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _locationFocus.requestFocus(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (val) {
                            controller.setCustomerPhone(val);
                          },
                        ),
                      ],
                    );

                    final locationWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'Installation City / Pincode',
                          isRequired: true,
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          containerKey: _locationKey,
                          focusNode: _locationFocus,
                          controller: _locationCtrl,
                          hintText: 'e.g. Rajkot, 360004',
                          prefixIcon: Icons.location_on_outlined,
                          errorText: controller.locationError,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _locationFocus.unfocus(),
                          onChanged: (val) {
                            controller.setCustomerLocation(val);
                          },
                        ),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: phoneWidget),
                          const SizedBox(width: 14),
                          Expanded(child: locationWidget),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          phoneWidget,
                          const SizedBox(height: 16),
                          locationWidget,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),

                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // Field 4: Payment / Finance Mode
                _buildFieldLabel('Payment / Finance Mode', isRequired: false),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Cash Case Button (Active)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: controller.paymentMode == 'CASH',
                        label: 'Cash Case payment mode',
                        child: InkWell(
                          onTap: () => controller.setPaymentMode('CASH'),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: controller.paymentMode == 'CASH'
                                  ? const Color(0xFF6CBF3D)
                                  : AppColors.surfaceHover,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.paymentMode == 'CASH'
                                    ? const Color(0xFF6CBF3D)
                                    : AppColors.border,
                                width: controller.paymentMode == 'CASH'
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: controller.paymentMode == 'CASH'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Cash Case',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: controller.paymentMode == 'CASH'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Solar Loan (EMI) Button (Disabled / In-Development Tooltip)
                    Expanded(
                      child: Semantics(
                        button: true,
                        enabled: false,
                        label: 'Solar Loan EMI payment option, coming soon. Currently only Cash Case proposals are supported.',
                        child: Tooltip(
                          preferBelow: false,
                          triggerMode: TooltipTriggerMode.tap,
                          waitDuration: const Duration(milliseconds: 200),
                          showDuration: const Duration(seconds: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          richMessage: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'COMING SOON ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: '\nCurrently, only Cash Case proposals are supported.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: 0.65,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.account_balance_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Solar Loan (EMI)',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.border,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Semantics(
      label: isRequired ? '$label, required' : label,
      child: RichText(
        text: TextSpan(
          text: label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required GlobalKey containerKey,
    required FocusNode focusNode,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      key: containerKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 19,
              color: hasError
                  ? const Color(0xFFEF4444)
                  : AppColors.textSecondary,
            ),
            suffixIcon: hasError
                ? const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: hasError
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : AppColors.surfaceHover,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF4444) : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF4444) : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6CBF3D),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFEF4444),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
