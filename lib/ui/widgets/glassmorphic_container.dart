import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable high-fidelity Frosted Glass container following Material 3 Expressive spacing
/// Leverages BackdropFilter with thin translucent borders and adaptive light/dark mode overlays.
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0, // Material 3 rounded corners
    this.blur = 15.0, // Smooth frosted blur level
    this.color,
    this.borderColor,
    this.borderWidth = 1.2,
    this.padding,
    this.margin,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium dynamic glass fills depending on theme state
    final defaultColor = color ?? (isDark 
        ? Colors.black.withAlpha(80) // Translucent dark backing
        : Colors.white.withAlpha(95)); // Translucent light backing

    // Delicate glass borders
    final defaultBorderColor = borderColor ?? (isDark 
        ? Colors.white.withAlpha(25) // Subtle white edge in dark mode
        : Colors.black.withAlpha(30)); // Subtle dark edge in light mode

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: defaultBorderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
