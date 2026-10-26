// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';
import '../utils/stats_calculator.dart';
import '../viewmodels/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/streak_flame_icon.dart';
import '../widgets/steps_bar_chart.dart';
import '../widgets/steps_line_chart.dart';

/// Statistics tab: period selector, summary cards and trend charts.
class StatsScreen extends ConsumerStatefulWidget {
  /// Creates the stats tab.
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;

  String _periodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.year:
        return 'Year';
      case StatsPeriod.all:
        return 'All';
    }
  }

  List<DayRecord> _chartDays(List<DayRecord> days, DateTime now) {
    if (_period != StatsPeriod.all) {
      return StatsCalculator.continuousDays(days, _period, now);
    }
    final withSteps = days.where((d) => d.steps > 0).toList();
    if (withSteps.isEmpty) return const [];
    final first = withSteps
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final today = DateTime(now.year, now.month, now.day);
    final length = today.difference(first).inDays + 1;
    return StatsCalculator.continuousDays(days, StatsPeriod.all, now).sublist(
        StatsCalculator.periodLength(StatsPeriod.all) -
            length.clamp(1, StatsCalculator.periodLength(StatsPeriod.all)));
  }

  String _chartCaption(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Last 7 days';
      case StatsPeriod.month:
        return 'Last 30 days';
      case StatsPeriod.year:
        return 'Last 12 months';
      case StatsPeriod.all:
        return 'All time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider(_period));
    final allDays = ref.watch(allDaysProvider);
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget loadingCard() => const GlassCard(
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
    Widget errorCard(String message) => GlassCard(
          child: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
        );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageTitle(title: 'Statistics'),
        const SizedBox(height: 12),
        Semantics(
          label: 'Statistics period',
          child: SegmentedButton<StatsPeriod>(
            showSelectedIcon: false,
            segments: StatsPeriod.values
                .map(
                  (p) => ButtonSegment<StatsPeriod>(
                    value: p,
                    label: Text(_periodLabel(p), maxLines: 1, softWrap: false),
                  ),
                )
                .toList(),
            selected: {_period},
            onSelectionChanged: (selected) =>
                setState(() => _period = selected.first),
          ),
        ),
      ],
    );

    final chartCard = allDays.when(
      loading: loadingCard,
      error: (error, _) => errorCard('Could not load history: $error'),
      data: (days) {
        final now = DateTime.now();
        final chartDays = _chartDays(days, now);
        final total = stats.valueOrNull?.totalSteps;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Steps', style: textTheme.titleMedium),
              Text(
                total == null ? '\u2014' : Formatters.steps(total),
                style: textTheme.headlineMedium,
              ),
              Text(
                _chartCaption(_period),
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (_period == StatsPeriod.week)
                StepsBarChart(days: chartDays, goal: profile.dailyGoal)
              else
                StepsLineChart(days: chartDays, goal: profile.dailyGoal),
            ],
          ),
        );
      },
    );

    final heatmapCard = allDays.when(
      loading: loadingCard,
      error: (error, _) => errorCard('Could not load history: $error'),
      data: (days) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: _period == StatsPeriod.all
                  ? 'Activity heatmap'
                  : 'Last 15 weeks',
            ),
            HeatmapCalendar(days: days, goal: profile.dailyGoal),
          ],
        ),
      ),
    );

    final children = <Widget>[header, chartCard];
    stats.when(
      loading: () => children.add(loadingCard()),
      error: (error, _) =>
          children.add(errorCard('Could not load statistics: $error')),
      data: (s) {
        final best = s.bestDay;
        children.add(
          StatGrid(
            children: [
              StatCard(
                label: 'Average / day',
                value: Formatters.steps(s.averageSteps.round()),
                icon: Icons.speed_rounded,
              ),
              StatCard(
                label: best == null
                    ? 'Best day'
                    : 'Best \u00b7 ${Formatters.shortDate(best.date)}',
                value: best == null ? '\u2014' : Formatters.steps(best.steps),
                icon: Icons.emoji_events_rounded,
              ),
              StatCard(
                label: 'Goal completion',
                value: Formatters.percent(s.goalCompletionRate),
                icon: Icons.task_alt_rounded,
              ),
              StatCard(
                label: 'Current streak',
                value:
                    '${s.currentStreak} ${s.currentStreak == 1 ? 'day' : 'days'}',
                icon: Icons.local_fire_department_rounded,
                iconWidget: StreakFlameIcon(streak: s.currentStreak, size: 20),
              ),
              StatCard(
                label: 'Longest streak',
                value:
                    '${s.longestStreak} ${s.longestStreak == 1 ? 'day' : 'days'}',
                icon: Icons.trending_up_rounded,
              ),
              StatCard(
                label: 'Lifetime steps',
                value: Formatters.steps(s.lifetimeSteps),
                icon: Icons.all_inclusive_rounded,
              ),
            ],
          ),
        );
        final consistency = s.consistencyScore.clamp(0.0, 1.0);
        children.add(
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Consistency', style: textTheme.titleMedium),
                    ),
                    Text(
                      '${(consistency * 100).round()} / 100',
                      style: textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: consistency,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share of days with recorded steps \u00b7 ${_chartCaption(_period).toLowerCase()}. '
                  '${s.daysTracked} ${s.daysTracked == 1 ? 'day' : 'days'} tracked.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
    children.add(heatmapCard);

    return ScreenList(children: children);
  }
}
