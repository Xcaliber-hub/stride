// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';
import '../utils/stats_calculator.dart';
import '../viewmodels/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_title.dart';
import '../widgets/goal_progress_ring.dart';
import '../widgets/history_section.dart';
import '../widgets/screen_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/streak_flame_icon.dart';

/// Home tab: today's step count, goal ring, quick stats and streak.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Creates the dashboard tab.
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final ConfettiController _confetti;
  int? _lastKnownStreak;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _motivation(double progress) {
    if (progress < 0.25) return 'Every journey begins with a single step.';
    if (progress < 0.5) return 'Nice pace — keep moving.';
    if (progress < 0.75) return 'Over halfway there!';
    if (progress < 1.0) return 'Almost there — one more push!';
    return 'Goal crushed! Take a victory lap.';
  }

  double _progressOf(DayRecord? record, int goal) {
    if (record == null || goal <= 0) return 0.0;
    return record.steps / goal;
  }

  @override
  Widget build(BuildContext context) {
    // Celebrate the moment the goal is first reached each day.
    ref.listen<AsyncValue<DayRecord>>(todayRecordProvider, (previous, next) {
      final goal = ref.read(profileProvider).dailyGoal;
      final prevProgress = _progressOf(previous?.valueOrNull, goal);
      final nextProgress = _progressOf(next.valueOrNull, goal);
      if (previous?.valueOrNull != null &&
          prevProgress < 1.0 &&
          nextProgress >= 1.0) {
        HapticFeedback.heavyImpact();
        _confetti.play();
        ref.invalidate(statsProvider(StatsPeriod.week));
      }
    });

    final today = ref.watch(todayRecordProvider);
    final profile = ref.watch(profileProvider);
    final sensor = ref.watch(sensorAvailableProvider);
    final weekStats = ref.watch(statsProvider(StatsPeriod.week));
    final loadedStreak = weekStats.valueOrNull?.currentStreak;
    if (loadedStreak != null) _lastKnownStreak = loadedStreak;
    final streak = _lastKnownStreak ?? 0;
    final streakDataReady = _lastKnownStreak != null;

    final allDays = ref.watch(allDaysProvider).valueOrNull;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        today.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load today\u2019s data: $error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (record) {
            final progress = _progressOf(record, profile.dailyGoal);
            final name = profile.name.trim();
            final date = DateFormat('EEEE, d MMMM').format(DateTime.now());
            final subtitle = name.isEmpty ? date : '$name \u00b7 $date';
            return ScreenList(
              children: [
                PageTitle(title: _greeting(), subtitle: subtitle),
                GlassCard(
                  child: Center(
                    child: Semantics(
                      label:
                          '${Formatters.steps(record.steps)} of ${Formatters.steps(profile.dailyGoal)} steps',
                      child: GoalProgressRing(
                        steps: record.steps,
                        goal: profile.dailyGoal,
                      ),
                    ),
                  ),
                ),
                if (sensor.valueOrNull == false)
                  GlassCard(
                    color: colorScheme.errorContainer.withValues(alpha: 0.6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sensors_off_rounded,
                          color: colorScheme.onErrorContainer,
                          semanticLabel: 'Sensor warning',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Step sensor unavailable on this device \u2014 '
                            'past data is still shown.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                StatGrid(
                  children: [
                    StatCard(
                      label: 'Distance',
                      value: Formatters.distance(
                        record.distanceMeters,
                        profile.unitSystem,
                      ),
                      icon: Icons.route_rounded,
                    ),
                    StatCard(
                      label: 'Streak',
                      value: '$streak ${streak == 1 ? 'day' : 'days'}',
                      icon: Icons.local_fire_department_rounded,
                      iconWidget: StreakFlameIcon(
                        streak: streak,
                        dataReady: streakDataReady,
                        size: 20,
                      ),
                    ),
                    StatCard(
                      label: 'Calories',
                      value: Formatters.calories(record.calories),
                      icon: Icons.bolt_rounded,
                    ),
                    StatCard(
                      label: 'Active time',
                      value: Formatters.minutes(record.activeMinutes),
                      icon: Icons.timer_rounded,
                    ),
                  ],
                ),
                _GoalCard(
                  steps: record.steps,
                  goal: profile.dailyGoal,
                  days: allDays,
                  today: record,
                ),
                GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        progress >= 1.0
                            ? Icons.celebration_rounded
                            : Icons.directions_walk_rounded,
                        color: colorScheme.primary,
                        semanticLabel: 'Motivation',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _motivation(progress),
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const HistorySection(),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }
}

/// Flowstate's "Today's goal" card: progress toward the daily goal and a row
/// of seven dots, one per day of the past week, shaded by goal progress.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.steps,
    required this.goal,
    required this.days,
    required this.today,
  });

  final int steps;
  final int goal;
  final List<DayRecord>? days;
  final DayRecord today;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ratio = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final byKey = <String, DayRecord>{
      for (final d in days ?? const <DayRecord>[]) d.dateKey: d,
      today.dateKey: today,
    };
    final now = DateTime.now();
    final week = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("Today's goal", style: textTheme.titleMedium),
              const Spacer(),
              Flexible(
                child: Text(
                  '${Formatters.steps(steps)} of ${Formatters.steps(goal)}',
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 20),
          Text(
            'This week',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in week)
                Builder(builder: (context) {
                  final daySteps = byKey[DayRecord.dateKeyFor(day)]?.steps ?? 0;
                  final fill =
                      goal > 0 ? (daySteps / goal).clamp(0.0, 1.0) : 0.0;
                  return Semantics(
                    label:
                        '${DateFormat.EEEE().format(day)}: ${Formatters.steps(daySteps)} steps',
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary
                                .withValues(alpha: 0.1 + 0.9 * fill),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.E().format(day).substring(0, 1),
                          style: textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
