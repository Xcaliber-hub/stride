// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../utils/stats_calculator.dart';
import '../viewmodels/providers.dart';
import '../widgets/achievement_tile.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../widgets/stat_card.dart';

/// Achievements tab: unlockable milestones with live progress.
class AchievementsScreen extends ConsumerWidget {
  /// Creates the achievements tab.
  const AchievementsScreen({super.key});

  double _progressFor(
    Achievement achievement, {
    required int todaySteps,
    required double todayDistanceMeters,
    required int currentStreak,
    required int lifetimeSteps,
  }) {
    double raw;
    switch (achievement.metric) {
      case AchievementMetric.singleDaySteps:
        raw = todaySteps / achievement.targetValue;
      case AchievementMetric.streakDays:
        raw = currentStreak / achievement.targetValue;
      case AchievementMetric.singleDayDistanceMeters:
        raw = todayDistanceMeters / achievement.targetValue;
      case AchievementMetric.lifetimeSteps:
        raw = lifetimeSteps / achievement.targetValue;
    }
    return raw.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final today = ref.watch(todayRecordProvider);
    final all = ref.watch(allDaysProvider);
    final stats = ref.watch(statsProvider(StatsPeriod.all));

    return achievements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load achievements: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (list) {
        final unlockedCount = list.where((a) => a.unlocked).length;
        final todayRecord = today.valueOrNull;
        final lifetime = stats.valueOrNull?.lifetimeSteps ?? 0;
        final goal = ref.watch(profileProvider).dailyGoal;
        final streak = all.valueOrNull != null
            ? StatsCalculator.currentStreak(all.valueOrNull!, goal)
            : 0;

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final fraction = list.isEmpty ? 0.0 : unlockedCount / list.length;

        return ScreenList(
          children: [
            const PageTitle(
              title: 'Awards',
              subtitle: 'Milestones you unlock by walking',
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 20,
                        color: colorScheme.primary,
                        semanticLabel: 'Trophy',
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unlocked',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$unlockedCount of ${list.length}',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep walking to unlock them all.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatGrid(
              children: [
                for (final achievement in list)
                  AchievementTile(
                    achievement: achievement,
                    progress: _progressFor(
                      achievement,
                      todaySteps: todayRecord?.steps ?? 0,
                      todayDistanceMeters: todayRecord?.distanceMeters ?? 0,
                      currentStreak: streak,
                      lifetimeSteps: lifetime,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
