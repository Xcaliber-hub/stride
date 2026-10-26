// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Today's steps against the daily goal, drawn like Flowstate's timer ring:
/// a thick rounded track with a primary→tertiary sweep-gradient arc, a
/// `titleMedium` label, the count in light `displayLarge` numerals and a
/// short caption underneath. The arc springs in from 0 on every change.
class GoalProgressRing extends StatelessWidget {
  /// Creates a progress ring for [steps] out of [goal].
  const GoalProgressRing({
    super.key,
    required this.steps,
    required this.goal,
    this.size = 280,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final progress = goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);
    final remaining = max(0, goal - steps);

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
              trackColor: dark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              primary: colorScheme.primary,
              tertiary: colorScheme.tertiary,
            ),
            child: child,
          );
        },
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  progress >= 1 ? 'Goal reached' : 'Steps today',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Formatters.steps(steps),
                    style: textTheme.displayLarge,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                Text(
                  progress >= 1
                      ? '${Formatters.percent(steps / max(goal, 1))} of ${Formatters.steps(goal)}'
                      : '${Formatters.steps(remaining)} to go',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the track and gradient progress arc of [GoalProgressRing].
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.primary,
    required this.tertiary,
  });

  final double progress;
  final Color trackColor;
  final Color primary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    const pad = stroke + 6;
    final rect = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    final center = rect.center;

    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    final sweep = 2 * pi * progress;
    if (sweep < 0.02) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(
      rect,
      0,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [primary, tertiary, primary],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.primary != primary ||
        oldDelegate.tertiary != tertiary;
  }
}
