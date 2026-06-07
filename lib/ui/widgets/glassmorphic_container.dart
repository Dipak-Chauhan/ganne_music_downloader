import 'dart:ui';
import 'package:flutter/material.dart';

/// High-performance frosted glass-style container.
/// Uses BackdropFilter with thin translucent borders and adaptive light/dark mode overlays.
/// Optimized to bypass BackdropFilter completely if [blur] is 0 or less.
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
    this.borderRadius = 20.0,
    this.blur = 15.0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Translucent glass gradient with specular highlights to let the blur show through with depth
    final defaultGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                Colors.white.withAlpha(13),
                cs.surfaceContainerHigh.withAlpha(166),
              ),
              Color.alphaBlend(
                Colors.white.withAlpha(3),
                cs.surfaceContainerHigh.withAlpha(102),
              ),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                Colors.black.withAlpha(3),
                cs.surfaceContainerLowest.withAlpha(217),
              ),
              Color.alphaBlend(
                Colors.black.withAlpha(10),
                cs.surfaceContainerLowest.withAlpha(179),
              ),
            ],
          );

    // Subtle frosted border
    final defaultBorderColor =
        borderColor ??
        (isDark ? Colors.white.withAlpha(35) : Colors.black.withAlpha(20));

    final decoration = BoxDecoration(
      color: color,
      gradient: color == null ? defaultGradient : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: defaultBorderColor, width: borderWidth),
    );

    final shadowList =
        boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];

    // If blur is 0, completely bypass BackdropFilter for extreme performance
    if (blur <= 0) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: decoration.copyWith(boxShadow: shadowList),
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadowList,
      ),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
