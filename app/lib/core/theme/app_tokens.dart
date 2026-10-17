import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized Sunvine Design Tokens defining spacing, radii, durations,
/// curves, breakpoints, and interaction dimensions.
abstract final class AppTokens {
  // Prevent instantiation
  AppTokens._();
}

/// Spacing scale (4px grid system)
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Common insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(md);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 14.0,
    vertical: 12.0,
  );
}

/// Corner Radii
abstract final class AppRadii {
  AppRadii._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;

  static final BorderRadius roundedXs = BorderRadius.circular(xs);
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}

/// Motion and Animation Durations
abstract final class AppDurations {
  AppDurations._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration transition = Duration(milliseconds: 300);
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Helper to get effective duration honoring platform reduced-motion
  static Duration motion(BuildContext context, Duration standard) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : standard;
  }
}

/// Motion Curves
abstract final class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve snappy = Curves.easeOutCubic;
}

/// Responsive Breakpoints
abstract final class AppBreakpoints {
  AppBreakpoints._();

  static const double compactPhone = 360.0;
  static const double standardPhone = 480.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;

  /// Max-width constraint for form cards, wizards, and detail flows on desktop/tablet
  static const double maxContentWidth = 720.0;
}

/// Standardized Touch Targets and Component Dimensions
abstract final class AppComponentDimensions {
  AppComponentDimensions._();

  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 50.0;
  static const double compactButtonHeight = 38.0;
  static const double inputMinHeight = 48.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
}

/// Standardized Elevation & Shadows
abstract final class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.12),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 2),
    ),
  ];
}
