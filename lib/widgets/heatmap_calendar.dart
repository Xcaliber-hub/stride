// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';

/// Calendar heatmap in the Flowstate style: one column per week with Monday
/// at the top, rounded cells shaded by progress toward the daily goal
/// (primary at 25–100 % opacity, neutral when there are no steps), and a
/// fade-in reveal.
///
/// Shows at least [minWeeks] weeks; longer histories scroll horizontally
/// and open on the current week. Month names label the first week of each
/// month. Tapping a day with data calls [onDaySelected]. Empty [days] shows
/// "No data yet".
class HeatmapCalendar extends StatelessWidget {
  /// Creates a heatmap for [days] against [goal].
  const HeatmapCalendar({
    super.key,
    required this.days,
    required this.goal,
    this.onDaySelected,
    this.minWeeks = 15,
  });

  /// Day records; any length of history.
  final List<DayRecord> days;

  /// Daily step goal used for the colour scale.
  final int goal;

  /// Called with the tapped day's record.
  final ValueChanged<DayRecord>? onDaySelected;

  /// Weeks that fit across the card without scrolling.
  final int minWeeks;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (days.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No data yet',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final byKey = {for (final day in days) day.dateKey: day};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final earliest = days
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestMonday =
        earliest.subtract(Duration(days: earliest.weekday - 1));
    final spanWeeks =
        (thisMonday.difference(earliestMonday).inDays / 7).round() + 1;
    final weeks = max(minWeeks, spanWeeks);
    final firstMonday = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));
    final empty = dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = min(
          (constraints.maxWidth - _gap * (minWeeks - 1)) / minWeeks,
          22.0,
        );
        final columns = <Widget>[];
        for (var w = 0; w < weeks; w++) {
          final monday = firstMonday.add(Duration(days: 7 * w));
          final showMonth = w == 0 || monday.day <= 7;
          columns.add(
            Padding(
              padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : _gap),
              child: SizedBox(
                width: cell,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: 60,
                        child: showMonth
                            ? Text(DateFormat.MMM().format(monday),
                                style: labelStyle, maxLines: 1)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    for (var d = 0; d < 7; d++)
                      Padding(
                        padding: EdgeInsets.only(top: d == 0 ? 0 : _gap),
                        child: _cell(
                          context,
                          monday.add(Duration(days: d)),
                          today,
                          byKey,
                          cell,
                          colorScheme.primary,
                          empty,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, reveal, child) =>
              Opacity(opacity: reveal, child: child),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns,
            ),
          ),
        );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    DateTime date,
    DateTime today,
    Map<String, DayRecord> byKey,
    double size,
    Color primary,
    Color empty,
  ) {
    if (date.isAfter(today)) return SizedBox.square(dimension: size);
    final record = byKey[DayRecord.dateKeyFor(date)];
    final steps = record?.steps ?? 0;
    final intensity = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final color =
        steps > 0 ? primary.withValues(alpha: 0.25 + 0.75 * intensity) : empty;
    final tooltip =
        '${Formatters.shortDate(date)}: ${Formatters.steps(steps)} steps';
    final radius = BorderRadius.circular(size * 0.3);
    final square = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );
    final tappable = record != null && onDaySelected != null;
    return Semantics(
      label: tooltip,
      button: tappable,
      child: Tooltip(
        message: tooltip,
        child: tappable
            ? InkWell(
                borderRadius: radius,
                onTap: () => onDaySelected!(record),
                child: square,
              )
            : square,
      ),
    );
  }
}
