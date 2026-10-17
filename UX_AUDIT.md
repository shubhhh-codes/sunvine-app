# Sunvine EPC Mobile App — UX, Accessibility & Architecture Audit (UX_AUDIT.md)

**Audit Date:** October 17, 2026  
**Auditor Roles:** Senior Flutter Architect, Mobile UX/UI Designer, Rendering & Performance Engineer, Accessibility Specialist, QA Lead  
**Scope:** Entire repository (`app/`), focusing on the 4-step Quotation Engine (Customer -> Solar Tech -> Pricing -> Review), Global Auth, Design System, and Auto-Sync Service.

---

## 1. Executive Summary

A comprehensive architectural and UX inspection was conducted across the Flutter code, state management, form inputs, keyboard interactions, navigation transitions, and theme design system. 

The audit confirmed several critical usability bottlenecks:
1. **Silent Continue CTA Failure (Issue UX-01, P1)**: The Continue button was disabled with `onPressed: null` when validation rules were not satisfied, providing zero visual or semantic feedback. Users tapping the button were left confused as to why the app was not proceeding.
2. **Missing Inline Error States & Focus Traversal (Issue UX-02, P1)**: Inputs lacked error borders, human-readable helper texts, and automatic focus traversal (`FocusNode.requestFocus()`) with smooth scrolling (`Scrollable.ensureVisible`) to the first invalid field.
3. **Step 2 (Solar Tech) Parity & Sizing Logic (Issue UX-03, P1)**: Missing the web portal's structured system capacity dropdown, wattpeak panel model selector, dynamic panel count badge, and the auto-generated plant capacity green banner.
4. **Step 3 (Pricing & Margin) Parity (Issue UX-04, P1)**: Missing the exact web breakdown card ("Central Subsidy Calculated"), margin mode tabs (`₹/kW`, `Fixed`, `%`), quick margin chips, and spread vs cap telemetry.
5. **Solar Loan / Coming Soon Interaction (Issue UX-05, P2)**: Previously opened an inconsistent or intrusive overlay rather than a clean, lightweight, accessible inline tooltip/modal explaining that the feature is currently in development.
6. **Double-Tap Debouncing & Navigation Race Conditions (Issue UX-06, P2)**: Step indicator circles permitted jumping ahead before verifying requirements, and rapid double-tapping on Continue could trigger unintended state jumps.

---

## 2. Prioritized Issue Registry

| Issue ID | Screen / Component | Observed Behavior | Expected Behavior | Severity | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **UX-01** | `CreateQuotationStepperScreen` (Bottom Bar) | Continue button was disabled with `onPressed: null`. Tapping it silently did nothing when required fields were missing. | Continue CTA is always clickable; on tap, validates all fields, surfaces inline errors, and focuses the first invalid field. | **P1 (High)** | **Verified Fixed** |
| **UX-02** | `Step1CustomerDiscom` (Customer Form) | No inline error messages, red borders, or focus scrolling when validation failed. | Distinct red outline, error message below field, automatic keyboard focus and scroll-to-view for first invalid field. | **P1 (High)** | **Verified Fixed** |
| **UX-03** | `Step2SolarSizing` (Solar Tech) | Sizing used an unguided horizontal chip list and arbitrary 28-division slider; lacked structured dropdowns for kW and ALMM panel models. | Dropdown for System Capacity kW with "X Panels Required" badge, ALMM panel selector dropdown, and Auto-Generated Plant Capacity green banner. | **P1 (High)** | **Verified Fixed** |
| **UX-04** | `Step3PricingMargin` (Pricing & Margin) | Financial breakdown differed from the web portal; lacked `₹/kW`, `Fixed`, `%` margin modes and quick selection chips. | Exact web parity: Central Subsidy Calculated card with full itemized breakdown, margin modes, quick chips, and cap telemetry. | **P1 (High)** | **Verified Fixed** |
| **UX-05** | `Step1CustomerDiscom` (Payment Mode) | Solar Loan (EMI) option lacked consistent disabled styling and displayed oversized or intrusive overlays. | Disabled state with 65% opacity, info badge, and lightweight non-intrusive tooltip/snackbar explaining "Coming Soon / In Development". | **P2 (Medium)** | **Verified Fixed** |
| **UX-06** | `CreateQuotationStepperScreen` (Stepper) | Stepper circle indicators allowed tapping to jump ahead before current step was validated; rapid double-taps were not debounced. | Stepper header restricts jumps to completed steps; Continue CTA implements double-tap debouncing. | **P2 (Medium)** | **Verified Fixed** |
| **UX-07** | `Step1CustomerDiscom` (Keyboard & Scroll) | Virtual keyboard covered input fields and bottom CTA on smaller devices without auto-scroll. | Card inputs use `Scrollable.ensureVisible` and proper padding to remain visible above keyboard insets. | **P2 (Medium)** | **Verified Fixed** |
| **UX-08** | Accessibility & Screen Readers | Missing semantics labels for buttons, inputs, and error states; tap targets on info icons were below 48x48 dp. | Semantics added, `SemanticsService.announce` on validation error, and minimum 48x48 dp touch targets. | **P2 (Medium)** | **Verified Fixed** |

---

## 3. Deep-Dive Findings & Technical Root Causes

### UX-01: Silent Continue Button Disabling
- **Root Cause**: In `create_quotation_stepper_screen.dart`, line 321 had:
  ```dart
  onPressed: canContinue ? _controller.nextStep : null
  ```
  When `canContinue` returned `false`, the button was set to disabled (`null`), completely discarding user tap events without any feedback.
- **Fix**: Make `onPressed` call `_handleContinueStep()`. If the active step has validation errors, compute field errors, request focus on the first invalid field, and display clear inline alerts.

### UX-02: Missing Form Field Validation & Focus Management
- **Root Cause**: `Step1CustomerDiscom` did not maintain error state strings (`nameError`, `phoneError`, `locationError`) or focus nodes. Validation was checked only at the controller level as a boolean without surfacing which specific field was invalid.
- **Fix**: Added `FocusNode` for each field (`_nameFocus`, _phoneFocus`, `_locationFocus`) and `GlobalKey` references. Connected `controller.validateStep1()` to return human-readable error strings and trigger `Scrollable.ensureVisible`.

### UX-03: Solar Tech Sizing & Hardware Parity
- **Root Cause**: `step2_solar_sizing.dart` lacked the web portal's Gujarat capacity slabs (2.0 to 10.0 kW), ALMM Tier-1 panel models dropdown, and the auto-generated plant capacity summary banner.
- **Fix**: Rebuilt Step 2 using custom smart dropdowns with live module count calculations (`capacityKw * 1000 / panelWattage`), shadow-free rooftop area estimate (`~64 sq. ft. per kW`), and ALMM panel specifications.

### UX-04: Pricing & Margin Calculation Alignment
- **Root Cause**: Step 3 used an ad-hoc layout rather than the standardized "Central Subsidy Calculated" card from the reference implementation.
- **Fix**: Reconstructed Step 3 with:
  1. Base Package (Turnkey Base Price)
  2. Channel Margin (+ ₹)
  3. Statutory GST (18%) included
  4. Total Project Cost
  5. PM Surya Ghar Subsidy deduction (- ₹30k/60k/78k)
  6. Net Effective Investment hero banner
  7. Interactive margin selector with `₹/kW`, `Fixed`, and `%` modes plus preset chips.

---

## 4. Verification & Testing Matrix

| Test Suite | Coverage Area | Result |
| :--- | :--- | :--- |
| `pricing_engine_test.dart` | Subsidy slabs, margin caps, module wattage compatibility, reducing-balance EMI | **Passed (5/5)** |
| `quotation_validation_test.dart` | Empty fields, whitespace, malformed phone, missing pincode, dynamic error clearing | **Passed** |
| `stepper_navigation_test.dart` | Prevent jump ahead, back navigation data preservation, double-tap debounce | **Passed** |
| `flutter analyze .` | Static analysis, deprecation checks, lint compliance | **0 Issues** |
