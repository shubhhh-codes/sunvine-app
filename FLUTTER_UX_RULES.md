# Sunvine EPC Engineering & UX Standards (FLUTTER_UX_RULES.md)

This document establishes the permanent UI/UX, architecture, performance, accessibility, and form validation standards for the Sunvine EPC Flutter application.

---

## 1. Form Validation & CTA Rules (Non-Negotiable)

1. **Never Silently Disable Primary Action Buttons**:
   - The primary CTA (e.g. "Continue", "Submit", "Sign In") must **never** have a silent `onPressed: null` when validation requirements are incomplete.
   - When the user taps the button, all fields must be validated immediately.
   - If validation fails:
     1. Display clear, human-readable inline error messages below each invalid field.
     2. Apply a visible error border (e.g. `Color(0xFFEF4444)`) and error icon.
     3. Move focus to the first invalid field using `FocusNode.requestFocus()`.
     4. Bring the invalid field into view smoothly using `Scrollable.ensureVisible(duration: Duration(milliseconds: 250), alignment: 0.2)`.
     5. Announce the error accessibly using `SemanticsService.announce`.
     6. Do not navigate to the next step or submit.

2. **Dynamic Error Clearing**:
   - When the user begins typing or corrects an invalid field, the error for that specific field must clear immediately as soon as the input satisfies its validation rule.
   - Do not clear unrelated errors on other fields prematurely.

3. **Field Normalization & Whitespace**:
   - Always sanitize and trim inputs (`value.trim()`).
   - Phone numbers must be stripped of non-digits (`replaceAll(RegExp(r'\D'), '')`) and validated for exactly 10 digits for Indian mobile numbers.
   - Pincodes / Locations must verify that non-empty text contains meaningful characters, not just whitespace.

---

## 2. Multi-Step Flow & Navigation Standards

1. **State Preservation Across Steps**:
   - Form state must never be destroyed when the user navigates backward or forward.
   - State must reside in the controller (`CreateQuotationController`), not purely in ephemeral widget state.
   - Controllers and focus nodes must be properly initialized and disposed of in `State.dispose()`.

2. **Step Protection & Debouncing**:
   - Stepper headers must prevent users from jumping ahead to future steps unless all intermediate steps have passed validation.
   - Primary action buttons must debounce rapid consecutive taps (minimum 350ms lock) to prevent duplicate screen transitions or duplicate API submissions.

3. **Back Navigation & Confirmation**:
   - Stepper Back buttons must smoothly retreat to `step - 1`.
   - Android hardware back button and iOS swipe-to-pop must be handled with `PopScope(canPop: ...)` to ensure the user doesn't accidentally lose unsaved quotation data.

---

## 3. Coming Soon & In-Development Features

1. **No Oversized or Obstructive Overlays**:
   - Never show an oversized fullscreen modal for a minor "Coming Soon" or "In Development" notice.
   - Use subtle visual cues:
     - Clear disabled state with `opacity: 0.65`.
     - Distinct info icon (`Icons.info_outline_rounded`).
     - Lightweight tooltip or compact inline bottom sheet explaining the release roadmap clearly:
       > *"Feature is under integration and will be available in an upcoming release."*

---

## 4. Performance & Rendering Guidelines

1. **Widget Rebuild Optimization**:
   - Use `const` constructors aggressively on all immutable widgets.
   - Avoid performing expensive calculations inside `build()`. Math, pricing calculations, and formatting must be memoized or computed in the controller.
   - Use `ListenableBuilder` or targeted listeners to restrict rebuilds to the specific parts of the tree that change.

2. **Animation Budget**:
   - Micro-interactions (hover, toggle, selection): `120ms` to `180ms`, `Curves.easeInOut`.
   - Card expansion / Step transitions: `200ms` to `280ms`, `Curves.fastOutSlowIn`.
   - No gratuitous bouncy animations or layout-shifting jumps.

---

## 5. Visual Design System & Design Tokens

1. **Brand Color Palette**:
   - Primary Green (Brand): `#6CBF3D`
   - Dark Canvas / Background: `#0B111E`
   - Card Surface: `#131B2E`
   - Elevated Surface Hover: `#1C263D`
   - Border: `#23304A`
   - Text Primary: `#F8FAFC`
   - Text Secondary: `#94A3B8`
   - Error Red: `#EF4444`
   - Warning Amber: `#F59E0B`

2. **Touch Targets & Accessibility**:
   - Minimum touch target for all buttons, chips, and interactive icons: `48x48 dp`.
   - All input fields must have permanent visible labels, not merely placeholders.
   - High text contrast matching WCAG AA standards ($4.5:1$ for normal text, $3:1$ for large text).

---

## 6. Build & Compilation Discipline (User Rule)

1. **Never Trigger Full Builds Automatically**:
   - **DO NOT** run `flutter build web`, `flutter build apk`, or `flutter build` automatically after routine code changes.
   - Full bundle generation is strictly reserved for when the user **explicitly asks** for a build (e.g. *"build apk"*, *"generate build"*, *"rebuild web"*).
2. **Use Fast Zero-Overhead Verification Instead**:
   - Verify code using `flutter analyze .` (sub-second static analysis, syntax and type checking) and `flutter test` (targeted unit and widget tests).
   - This prevents 2+ minute compilation delays and keeps workflow fast and responsive.
