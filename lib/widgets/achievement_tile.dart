// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import '../models/achievement.dart';
import 'glass_card.dart';

/// Card showing one achievement badge and how close it is to unlocking.
///
/// Centered vertical layout: badge icon on top, title and description
/// beneath it, progress bar at the bottom. Unlocked badges render in
/// full color with an "Unlocked" chip; locked badges are dimmed with a
/// lock overlay. [progress] is a 0..1 fraction shown on the progress
/// bar.
class AchievementTile extends StatelessWidget {
  /// Creates a tile for [achievement] with completion [progress].
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.progress,
  });

  /// The badge being displayed.
  final Achievement achievement;

  /// Completion fraction, 0..1 (clamped by the caller).
  final double progress;

  static IconData _iconFor(AchievementMetric metric) {
    switch (metric) {
      case AchievementMetric.singleDaySteps:
        return Icons.directions_walk;
      case AchievementMetric.streakDays:
        return Icons.local_fire_department;
      case AchievementMetric.singleDayDistanceMeters:
        return Icons.route;
      case AchievementMetric.lifetimeSteps:
        return Icons.military_tech;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = achievement.unlocked;

    return Semantics(
      label:
          '${unlocked ? 'Unlocked' : 'Locked'} achievement: ${achievement.title}',
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(achievement.metric),
                      size: 26,
                      color: unlocked
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    achievement.title,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: unlocked ? 1.0 : progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        unlocked
                            ? 'Done'
                            : '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                        style: textTheme.labelMedium?.copyWith(
                          color: unlocked
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                size: 20,
                color: unlocked
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
