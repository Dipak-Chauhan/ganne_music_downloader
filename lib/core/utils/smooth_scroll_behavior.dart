import 'dart:ui';
import 'package:flutter/material.dart';

/// Custom scroll behavior optimized for snappy, responsive scrolling
/// on high refresh rate displays (90Hz, 120Hz, 144Hz).
///
/// Uses Android-native [ClampingScrollPhysics] for crisp scroll stops,
/// with [StretchingOverscrollIndicator] (Material 3 stretch effect)
/// instead of the legacy glow for a modern feel.
class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Material 3 stretch effect — lightweight GPU composite, no blur
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  // Enable all input types for scrolling
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
