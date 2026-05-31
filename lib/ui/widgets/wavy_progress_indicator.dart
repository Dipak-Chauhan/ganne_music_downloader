import 'dart:math';
import 'package:flutter/material.dart';

/// Material 3 Expressive Wavy Linear Progress Indicator
///
/// Replicates Widget.Material3Expressive.LinearProgressIndicator.Wavy
/// Both the track and active indicators correctly follow the traversing sine wave.
class WavyLinearProgressIndicator extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final double waveAmplitude;
  final double waveLength;
  final BorderRadius? borderRadius;

  const WavyLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.trackColor,
    this.height = 8, // Recommended thick height per M3E docs
    this.waveAmplitude = 2.5,
    this.waveLength = 25,
    this.borderRadius,
  });

  @override
  State<WavyLinearProgressIndicator> createState() =>
      _WavyLinearProgressIndicatorState();
}

class _WavyLinearProgressIndicatorState
    extends State<WavyLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = widget.color ?? cs.primary;
    final trackColor = widget.trackColor ?? cs.primaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity,
          height: widget.height + widget.waveAmplitude * 2,
          child: CustomPaint(
            painter: _WavyLinearPainter(
              value: widget.value,
              activeColor: activeColor,
              trackColor: trackColor,
              height: widget.height,
              waveAmplitude: widget.waveAmplitude,
              waveLength: widget.waveLength,
              animValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _WavyLinearPainter extends CustomPainter {
  final double? value;
  final Color activeColor;
  final Color trackColor;
  final double height;
  final double waveAmplitude;
  final double waveLength;
  final double animValue;

  _WavyLinearPainter({
    required this.value,
    required this.activeColor,
    required this.trackColor,
    required this.height,
    required this.waveAmplitude,
    required this.waveLength,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final isDeterminate = value != null;
    final progress = isDeterminate ? value!.clamp(0.0, 1.0) : null;
    
    // Smooth moving phase
    final phase = animValue * 2 * pi;
    
    double waveY(double x) {
      return centerY + sin(2 * pi * (x / waveLength) - phase) * waveAmplitude;
    }

    Path buildWavePath(double startX, double endX) {
      final path = Path();
      if (endX <= startX) {
        if (endX == startX) {
            path.moveTo(startX, waveY(startX));
            path.lineTo(startX + 0.1, waveY(startX + 0.1));
        }
        return path;
      }
      bool first = true;
      for (double x = startX; x <= endX; x += 1.0) {
        final y = waveY(x);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      // Guarantee it hits the end X precisely
      path.lineTo(endX, waveY(endX));
      return path;
    }

    final paintStyle = Paint()
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final gap = 4.0; 

    if (isDeterminate && progress != null) {
      final activeWidth = progress * size.width;
      
      // 1. Draw Inactive Track
      if (activeWidth + gap < size.width) {
        final trackStart = activeWidth == 0.0 ? 0.0 : activeWidth + gap;
        final p = buildWavePath(trackStart, size.width);
        canvas.drawPath(p, paintStyle..color = trackColor);
      }

      // 2. Draw Active Track
      if (activeWidth > 0.0) {
        final p = buildWavePath(0, activeWidth);
        canvas.drawPath(p, paintStyle..color = activeColor);
      }
    } else {
      // Indeterminate mode
      // Always draw full track
      final pTrack = buildWavePath(0, size.width);
      canvas.drawPath(pTrack, paintStyle..color = trackColor);

      // Draw two sweeping disjoint segments (simulated)
      final sweep1Center = (animValue * 1.5 * size.width) - size.width * 0.25;
      final sweep2Center = (animValue * 1.5 * size.width) - size.width * 0.85;
      
      void drawSweep(double center, double widthMultiplier) {
        final activeWidth = size.width * widthMultiplier;
        final start = (center - activeWidth / 2).clamp(0.0, size.width);
        final end = (center + activeWidth / 2).clamp(0.0, size.width);
        if (end > start) {
          final pActive = buildWavePath(start, end);
          canvas.drawPath(pActive, paintStyle..color = activeColor);
        }
      }

      drawSweep(sweep1Center, 0.4);
      drawSweep(sweep2Center, 0.2);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyLinearPainter oldDelegate) => true;
}

/// Material 3 Expressive Wavy Circular Progress Indicator
class WavyCircularProgressIndicator extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color? trackColor;
  final double size;
  final double strokeWidth;
  final int wavyTeeth;
  final double? wavyAmplitude;

  const WavyCircularProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.trackColor,
    this.size = 52, // Recommended 52dp per M3E circular thick spec
    this.strokeWidth = 6,
    this.wavyTeeth = 18,
    this.wavyAmplitude,
  });

  @override
  State<WavyCircularProgressIndicator> createState() =>
      _WavyCircularProgressIndicatorState();
}

class _WavyCircularProgressIndicatorState
    extends State<WavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = widget.color ?? cs.primary;
    final trackColor = widget.trackColor ?? cs.primaryContainer;
    
    // Scale amplitude automatically to look elegant if not provided
    final double amp = widget.wavyAmplitude ?? (widget.strokeWidth * 0.4);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _WavyCircularPainter(
              value: widget.value,
              activeColor: activeColor,
              trackColor: trackColor,
              strokeWidth: widget.strokeWidth,
              wavyTeeth: widget.wavyTeeth,
              wavyAmplitude: amp,
              animValue: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double? value;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final int wavyTeeth;
  final double wavyAmplitude;
  final double animValue;

  _WavyCircularPainter({
    required this.value,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.wavyTeeth,
    required this.wavyAmplitude,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (min(size.width, size.height) / 2) - strokeWidth;
    
    // Wave traversing phase
    final phase = animValue * 2 * pi;

    double dynamicRadius(double angle) {
      // Rotate the wave over time
      return baseRadius + sin(angle * wavyTeeth - phase * 3) * wavyAmplitude;
    }

    Path buildWavyArc(double startAngle, double sweepAngle) {
      final path = Path();
      if (sweepAngle <= 0) {
        if (sweepAngle == 0) {
          final r = dynamicRadius(startAngle);
          path.moveTo(center.dx + r * cos(startAngle), center.dy + r * sin(startAngle));
          path.lineTo(center.dx + r * cos(startAngle+0.01), center.dy + r * sin(startAngle+0.01));
        }
        return path;
      }
      final step = sweepAngle / 80; // Smooth Resolution
      bool first = true;
      for (double angle = startAngle; angle <= startAngle + sweepAngle; angle += step) {
        final r = dynamicRadius(angle);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      // Ensure it lands on the exact end
      final rEnd = dynamicRadius(startAngle + sweepAngle);
      path.lineTo(center.dx + rEnd * cos(startAngle + sweepAngle), center.dy + rEnd * sin(startAngle + sweepAngle));
      return path;
    }

    final paintStyle = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final isDeterminate = value != null;
    final progress = isDeterminate ? value!.clamp(0.0, 1.0) : null;
    
    final gapAngle = 6.0 / baseRadius; 

    if (isDeterminate && progress != null) {
      final startAngle = -pi / 2;
      final sweepAngle = progress * 2 * pi;
      
      // 1. Draw Inactive Track
      final trackSweep = (2 * pi) - sweepAngle - (progress > 0.0 && progress < 1.0 ? gapAngle : 0.0);
      if (trackSweep > 0) {
        final trackStart = startAngle + sweepAngle + (progress > 0.0 ? gapAngle : 0.0);
        final pTrack = buildWavyArc(trackStart, trackSweep);
        canvas.drawPath(pTrack, paintStyle..color = trackColor);
      }

      // 2. Draw Active Arc
      if (sweepAngle > 0) {
        final pActive = buildWavyArc(startAngle, sweepAngle);
        canvas.drawPath(pActive, paintStyle..color = activeColor);
      }
    } else {
      // Indeterminate mode
      // Full rotated track background
      final pTrack = buildWavyArc(0, 2 * pi);
      canvas.drawPath(pTrack, paintStyle..color = trackColor);

      // Active stroke oscillating and rotating
      final startAngle = -pi / 2 + animValue * 4 * pi; // Spin
      // Oscillating sweep angle from a small dot (0.1) up to 270 deg (1.5 * pi)
      final sweepMode = sin(animValue * 2 * pi); // -1 to 1
      final currentSweep = (0.3 + 0.6 * ((sweepMode + 1.0) / 2.0)) * 2 * pi; // between ~100 deg and ~250 deg
      
      final pActive = buildWavyArc(startAngle, currentSweep);
      canvas.drawPath(pActive, paintStyle..color = activeColor);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter oldDelegate) => true;
}
