// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';

/// Bar chart of daily step counts in the Flowstate chart style: fully
/// rounded capsule bars (62 % of each slot), no grid or axes, small
/// `labelSmall` captions underneath and a spring-in reveal.
///
/// Days that reach [goal] use the full primary colour, days below it a
/// softer primary, and empty days a short neutral stub. A faint dashed line
/// marks the goal. Tapping a bar shows a tooltip with the step count.
/// Shows "No data yet" when [days] is empty.
class StepsBarChart extends StatelessWidget {
  /// Creates a bar chart for [days] against [goal].
  const StepsBarChart({super.key, required this.days, required this.goal});

  /// Day records in chronological order, one bar per entry.
  final List<DayRecord> days;

  /// Daily step goal drawn as a faint horizontal line.
  final int goal;

  static const double _chartHeight = 150;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

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
    final maxY = max(max(maxSteps, goal), 1).toDouble();
    final track = dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / days.length;
        final barWidth = slot * 0.62;
        final stub = maxY * (4 / _chartHeight);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, reveal, _) => SizedBox(
            height: _chartHeight + 40,
            child: BarChart(
              duration: const Duration(milliseconds: 250),
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 0,
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].steps > 0
                              ? max(days[i].steps * reveal, stub)
                              : stub,
                          color: days[i].steps <= 0
                              ? track
                              : days[i].steps >= goal
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.55),
                          width: barWidth,
                          borderRadius: BorderRadius.circular(barWidth / 2),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    tooltipRoundedRadius: 12,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = days[group.x.toInt()];
                      return BarTooltipItem(
                        '${Formatters.shortDate(day.date)}\n'
                        '${Formatters.steps(day.steps)} steps',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (goal > 0)
                      HorizontalLine(
                        y: goal.toDouble(),
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.35),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final date = days[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(DateFormat.E().format(date)[0],
                                    style: labelStyle),
                                Text(DateFormat('d').format(date),
                                    style: labelStyle),
                              ],
                            ),
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
      },
    );
  }
}
