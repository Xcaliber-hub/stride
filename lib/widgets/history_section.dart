// SPDX-License-Identifier: GPL-3.0-or-later
// Stride — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/day_record.dart';
import '../utils/formatters.dart';
import '../viewmodels/providers.dart';
import 'glass_card.dart';
import 'section_header.dart';

/// Calendar with per-day activity and a detail card, designed to be
/// embedded at the bottom of the dashboard (no own scroll view).
class HistorySection extends ConsumerStatefulWidget {
  /// Creates the history section.
  const HistorySection({super.key});

  @override
  ConsumerState<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<HistorySection> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allDays = ref.watch(allDaysProvider);
    final profile = ref.watch(profileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return allDays.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load history: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (days) {
        final events = <String, DayRecord>{
          for (final d in days) d.dateKey: d,
        };
        final selectedRecord = events[DayRecord.dateKeyFor(_selected)];

        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    title: 'History',
                    padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                  ),
                  Semantics(
                    label: 'Activity calendar',
                    child: TableCalendar<DayRecord>(
                      firstDay: DateTime(2020),
                      lastDay: DateTime.now(),
                      focusedDay: _focused,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      selectedDayPredicate: (day) => isSameDay(day, _selected),
                      onDaySelected: (selected, focused) => setState(() {
                        _selected = selected;
                        _focused = focused;
                      }),
                      onPageChanged: (focused) =>
                          setState(() => _focused = focused),
                      eventLoader: (day) {
                        final record = events[DayRecord.dateKeyFor(day)];
                        return record == null ? const [] : [record];
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: false,
                        titleTextStyle: textTheme.titleSmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded,
                            color: colorScheme.onSurfaceVariant),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant),
                        headerPadding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: textTheme.labelSmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        weekendStyle: textTheme.labelSmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: textTheme.bodyMedium!,
                        weekendTextStyle: textTheme.bodyMedium!,
                        disabledTextStyle: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        todayTextStyle: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedTextStyle: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        todayDecoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, dayEvents) {
                          if (dayEvents.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final record = dayEvents.first;
                          if (record.steps <= 0) {
                            return const SizedBox.shrink();
                          }
                          final progress = (record.steps / profile.dailyGoal)
                              .clamp(0.0, 1.0);
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              height: 4,
                              width: 16 * progress + 2,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: progress >= 1.0 ? 1 : 0.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: Formatters.date(_selected)),
                  if (selectedRecord == null)
                    Text(
                      'No step data recorded for this day.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        _DayMetric(
                          label: 'Steps',
                          value: Formatters.steps(selectedRecord.steps),
                        ),
                        _DayMetric(
                          label: 'Distance',
                          value: Formatters.distance(
                            selectedRecord.distanceMeters,
                            profile.unitSystem,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _DayMetric(
                          label: 'Calories',
                          value: Formatters.calories(selectedRecord.calories),
                        ),
                        _DayMetric(
                          label: 'Active time',
                          value:
                              Formatters.minutes(selectedRecord.activeMinutes),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One label/value pair in the selected-day card.
class _DayMetric extends StatelessWidget {
  const _DayMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
