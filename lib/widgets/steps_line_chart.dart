// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';

/// Line chart of daily step counts in the Flowstate chart style: a 3 dp
/// rounded primary line over a primary→transparent gradient, no grid or
/// axes, `labelSmall` captions underneath, revealed left to right.
///
/// A faint dashed line marks the goal. Touching the chart shows a tooltip
/// with the step count. Shows "No data yet" when [days] is empty.
class StepsLineChart extends StatelessWidget {
  /// Creates a line chart for [days] against [goal].
  const StepsLineChart({super.key, required this.days, required this.goal});

  /// Day records in chronological order, one spot per entry.
  final List<DayRecord> days;

  /// Daily step goal drawn as a faint dashed line.
  final int goal;

  static const double _chartHeight = 150;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (days.isEmpty) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: Text(
            'No data yet',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxSteps = days.fold<int>(0, (m, d) => max(m, d.steps));
    final maxY = max(max(maxSteps, goal), 1) * 1.05;
    // Keep bottom labels readable: aim for ~6 labels across the chart.
    final labelEvery = max(1, (days.length / 6).ceil());
    final primary = colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, reveal, child) => ClipRect(
        clipper: _RevealClipper(reveal),
        child: child,
      ),
      child: SizedBox(
        height: _chartHeight + 24,
        child: LineChart(
          duration: const Duration(milliseconds: 250),
          LineChartData(
            minX: 0,
            // Avoid a zero-width axis when there is only one day.
            maxX: max(1, days.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < days.length; i++)
                    FlSpot(i.toDouble(), days[i].steps.toDouble()),
                ],
                isCurved: false,
                color: primary,
                barWidth: 3,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primary.withValues(alpha: 0.35),
                      primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colorScheme.inverseSurface,
                tooltipRoundedRadius: 12,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${Formatters.shortDate(days[spot.x.toInt()].date)}\n'
                      '${Formatters.steps(spot.y.toInt())} steps',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (goal > 0)
                  HorizontalLine(
                    y: goal.toDouble(),
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= days.length ||
                        index % labelEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        Formatters.shortDate(days[index].date),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the chart to the left [fraction] of its width.
class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, -8, size.width * fraction, size.height + 16);

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
