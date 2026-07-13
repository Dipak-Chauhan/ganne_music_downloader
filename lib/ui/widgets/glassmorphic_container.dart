import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/settings_provider.dart';

/// High-performance frosted glass-style container.
/// Uses BackdropFilter with thin translucent borders and adaptive light/dark mode overlays.
/// Optimized to bypass BackdropFilter completely if [blur] is 0 or less, or if blur is disabled in settings.
class GlassmorphicContainer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final double effectiveBlur = settings.enableBlur ? blur.clamp(0.0, 12.0) : 0.0;

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

    Color? finalColor = color;
    Gradient? finalGradient;

    if (settings.enableBlur) {
      finalGradient = color == null ? defaultGradient : null;
    } else {
      // Degrade gracefully to solid, fully opaque container backgrounds when blur is disabled
      if (finalColor != null) {
        finalColor = finalColor.withAlpha(255);
      } else {
        // Fallback to fully opaque container surface colors
        finalColor = isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest;
      }
      finalGradient = null;
    }

    final decoration = BoxDecoration(
      color: finalColor,
      gradient: finalGradient,
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
    if (effectiveBlur <= 0) {
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
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
