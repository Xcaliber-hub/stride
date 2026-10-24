// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Animated ring showing today's steps against the daily goal.
///
/// The fill animates from 0 to the clamped progress on every rebuild.
/// The center shows the step count, the goal, and the percentage in a
/// tonal pill. Announced to assistive tech as a percentage of the goal.
class GoalProgressRing extends StatelessWidget {
  /// Creates a progress ring for [steps] out of [goal].
  const GoalProgressRing({
    super.key,
    required this.steps,
    required this.goal,
    this.size = 240,
  });

  /// Steps recorded today.
  final int steps;

  /// Daily step goal.
  final int goal;

  /// Outer diameter of the ring in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);

    return Semantics(
      label: '${Formatters.percent(progress)} of daily goal',
      value: '${Formatters.steps(steps)} of ${Formatters.steps(goal)} steps',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: value,
              trackColor: colorScheme.surfaceContainerHigh,
              haloColor: colorScheme.primary.withValues(alpha: 0.2),
              progressColor: colorScheme.primary,
            ),
            child: SizedBox.square(
              dimension: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Formatters.steps(steps),
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${Formatters.steps(goal)} steps',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      Formatters.percent(value),
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints the track and progress arcs of [GoalProgressRing].
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.haloColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color haloColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const trackWidth = 24.0;
    const arcWidth = 18.0;
    const haloWidth = 30.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - haloWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // A soft, wider outline sits under the solid arc.
    final haloPaint = Paint()
      ..color = haloColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = haloWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(bounds, -pi / 2, 2 * pi * progress, false, haloPaint);
    canvas.drawArc(bounds, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.haloColor != haloColor ||
        oldDelegate.progressColor != progressColor;
  }
}
