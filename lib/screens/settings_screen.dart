// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder.dart';
import '../models/user_profile.dart';
import '../themes/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/providers.dart';
import '../widgets/page_title.dart';
import '../widgets/screen_layout.dart';
import '../widgets/settings_rows.dart';

/// Settings tab: profile, appearance, notifications, reminders, backup, about.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings tab.
  const SettingsScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile updated,
  ) async {
    await ref.read(profileProvider.notifier).update(updated);
    HapticFeedback.mediumImpact();
  }

  Future<void> _saveName(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String name,
  ) async {
    await ref
        .read(profileProvider.notifier)
        .update(profile.copyWith(name: name));
    HapticFeedback.mediumImpact();
    try {
      final user = await ref.read(authStateProvider.future);
      if (user == null) return;
      await ref.read(authServiceProvider).updateDisplayName(name);
      await ref.read(groupServiceProvider).updateMemberDisplayName(
            uid: user.uid,
            displayName: name,
          );
      if (context.mounted) {
        _snack(context, 'Your group display name was updated.');
      }
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          'Name saved in Settings, but the group display name could not be synced. Check your connection and save again.',
        );
      }
    }
  }

  /// Generic number-editing dialog. Returns the entered value, or null.
  Future<double?> _numberDialog(
    BuildContext context, {
    required String title,
    required String? initialValue,
    required String unit,
  }) {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            hintText: 'Enter a value',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editAge(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final value = await _numberDialog(
      context,
      title: 'Age',
      initialValue: profile.age?.toString(),
      unit: 'years',
    );
    if (value == null || !context.mounted) return;
    final age = value.round();
    if (age < 1 || age > 130) {
      _snack(context, 'Please enter an age between 1 and 130.');
      return;
    }
    await _saveProfile(context, ref, profile.copyWith(age: age));
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final controller = TextEditingController(text: profile.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    if (value.toLowerCase() == 'aditya') {
      await _saveName(context, ref, profile, value);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Hey dev!'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    await _saveName(context, ref, profile, value);
  }

  Future<void> _editHeight(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final imperial = profile.unitSystem == UnitSystem.imperial;
    final displayed = profile.heightCm == null
        ? null
        : imperial
            ? (profile.heightCm! / 30.48).toStringAsFixed(2)
            : profile.heightCm!.toStringAsFixed(1);
    final value = await _numberDialog(
      context,
      title: 'Height',
      initialValue: displayed,
      unit: imperial ? 'ft' : 'cm',
    );
    if (value == null || !context.mounted) return;
    final cm = imperial ? value * 30.48 : value;
    if (cm < 50 || cm > 300) {
      _snack(context, 'Please enter a realistic height.');
      return;
    }
    await _saveProfile(context, ref, profile.copyWith(heightCm: cm));
  }

  Future<void> _editWeight(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final imperial = profile.unitSystem == UnitSystem.imperial;
    final displayed = profile.weightKg == null
        ? null
        : imperial
            ? (profile.weightKg! * 2.20462).toStringAsFixed(1)
            : profile.weightKg!.toStringAsFixed(1);
    final value = await _numberDialog(
      context,
      title: 'Weight',
      initialValue: displayed,
      unit: imperial ? 'lb' : 'kg',
    );
    if (value == null || !context.mounted) return;
    final kg = imperial ? value / 2.20462 : value;
    if (kg < 20 || kg > 500) {
      _snack(context, 'Please enter a realistic weight.');
      return;
    }
    await _saveProfile(context, ref, profile.copyWith(weightKg: kg));
  }

  Future<void> _editDailyGoal(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final value = await _numberDialog(
      context,
      title: 'Daily step goal',
      initialValue: profile.dailyGoal.toString(),
      unit: 'steps',
    );
    if (value == null || !context.mounted) return;
    final goal = value.round();
    if (goal < 500 || goal > 100000) {
      _snack(context, 'Please enter a goal between 500 and 100,000 steps.');
      return;
    }
    await _saveProfile(context, ref, profile.copyWith(dailyGoal: goal));
  }

  Future<void> _pickGender(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    Gender? selected = profile.gender;
    bool confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<Gender?>(
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in [null, ...Gender.values])
                      RadioListTile<Gender?>(
                        title: Text(
                          option == null ? 'Prefer not to say' : option.name,
                        ),
                        value: option,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                confirmed = true;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (!confirmed || !context.mounted) return;
    await _saveProfile(context, ref, profile.copyWith(gender: selected));
  }

  String _genderLabel(Gender? gender) {
    if (gender == null) return 'Not set';
    return gender.name[0].toUpperCase() + gender.name.substring(1);
  }

  String _heightLabel(UserProfile profile) {
    if (profile.heightCm == null) return 'Not set';
    if (profile.unitSystem == UnitSystem.imperial) {
      return '${(profile.heightCm! / 2.54).toStringAsFixed(1)} in';
    }
    return '${profile.heightCm!.toStringAsFixed(1)} cm';
  }

  String _weightLabel(UserProfile profile) {
    if (profile.weightKg == null) return 'Not set';
    if (profile.unitSystem == UnitSystem.imperial) {
      return '${(profile.weightKg! * 2.20462).toStringAsFixed(1)} lb';
    }
    return '${profile.weightKg!.toStringAsFixed(1)} kg';
  }

  // --- Reminders --------------------------------------------------------

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    ReminderItem reminder,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    await ref.read(remindersProvider.notifier).updateTime(reminder.id, minutes);
    HapticFeedback.selectionClick();
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New reminder'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reminder title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(titleController.text.trim()),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (title == null || !context.mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null || !context.mounted) return;
    await ref.read(remindersProvider.notifier).add(
          ReminderItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title.isEmpty ? 'Reminder' : title,
            minutesOfDay: picked.hour * 60 + picked.minute,
            type: ReminderType.custom,
          ),
        );
    HapticFeedback.mediumImpact();
  }

  // --- Backup -------------------------------------------------------------

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final days = await ref.read(allDaysProvider.future);
      final backup = ref.read(backupServiceProvider);
      final path = await backup.exportCsv(days);
      await backup.shareFile(path, 'Stride CSV export');
    } catch (e) {
      if (context.mounted) _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final days = await ref.read(allDaysProvider.future);
      final profile = ref.read(profileProvider);
      final backup = ref.read(backupServiceProvider);
      final path = await backup.exportJson(days, profile);
      await backup.shareFile(path, 'Stride JSON backup');
    } catch (e) {
      if (context.mounted) _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    try {
      final backup = ref.read(backupServiceProvider);
      final result = await backup.pickAndParse();
      if (result == null || !context.mounted) return;
      final db = ref.read(databaseServiceProvider);
      for (final day in result.days) {
        await db.upsertDay(day);
      }
      if (result.profile != null) {
        await ref.read(profileProvider.notifier).update(result.profile!);
      }
      ref.invalidate(allDaysProvider);
    } catch (e) {
      if (context.mounted) _snack(context, 'Import failed: $e');
    }
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently deletes all recorded step history, '
          'achievements and reminders. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(databaseServiceProvider).clearAll();
    ref.invalidate(allDaysProvider);
    ref.invalidate(statsProvider);
    HapticFeedback.heavyImpact();
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final reminders = ref.watch(remindersProvider);
    final masterOn = profile.notificationsEnabled;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const chevron = Icon(Icons.chevron_right_rounded);

    return ScreenList(
      children: [
        const PageTitle(title: 'Settings'),
        SettingsGroup(
          title: 'Profile',
          children: [
            LinkRow(
              title: 'Name',
              subtitle: profile.name.isEmpty
                  ? 'Not set \u00b7 used in private groups'
                  : '${profile.name} \u00b7 used in private groups',
              trailing: chevron,
              onTap: () => _editName(context, ref),
            ),
            LinkRow(
              title: 'Daily goal',
              subtitle: '${Formatters.steps(profile.dailyGoal)} steps',
              trailing: chevron,
              onTap: () => _editDailyGoal(context, ref),
            ),
            LinkRow(
              title: 'Age',
              subtitle: profile.age == null ? 'Not set' : '${profile.age}',
              trailing: chevron,
              onTap: () => _editAge(context, ref),
            ),
            LinkRow(
              title: 'Height',
              subtitle: _heightLabel(profile),
              trailing: chevron,
              onTap: () => _editHeight(context, ref),
            ),
            LinkRow(
              title: 'Weight',
              subtitle: _weightLabel(profile),
              trailing: chevron,
              onTap: () => _editWeight(context, ref),
            ),
            LinkRow(
              title: 'Gender',
              subtitle: _genderLabel(profile.gender),
              trailing: chevron,
              onTap: () => _pickGender(context, ref),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Appearance',
          children: [
            Semantics(
              label: 'Theme mode',
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System', maxLines: 1, softWrap: false),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light', maxLines: 1, softWrap: false),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark', maxLines: 1, softWrap: false),
                  ),
                ],
                selected: {profile.themeMode},
                onSelectionChanged: (selected) => _saveProfile(
                  context,
                  ref,
                  profile.copyWith(themeMode: selected.first),
                ),
              ),
            ),
            ToggleRow(
              title: 'AMOLED black',
              subtitle: 'Pure black surfaces in dark mode',
              value: profile.amoledBlack,
              onChanged: (value) => _saveProfile(
                context,
                ref,
                profile.copyWith(amoledBlack: value),
              ),
            ),
            ToggleRow(
              title: 'Dynamic color',
              subtitle: 'Use colors from your wallpaper where supported',
              value: profile.dynamicColor,
              onChanged: (value) => _saveProfile(
                context,
                ref,
                profile.copyWith(dynamicColor: value),
              ),
            ),
            if (!profile.dynamicColor) ...[
              Text('Accent color', style: textTheme.titleSmall),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in AppTheme.accentColors.entries)
                    Builder(builder: (context) {
                      final selected =
                          profile.accentColor == option.value.toARGB32();
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: '${option.key} accent color',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _saveProfile(
                            context,
                            ref,
                            profile.copyWith(
                              accentColor: option.value.toARGB32(),
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: option.value,
                              border: selected
                                  ? Border.all(
                                      color: colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.6),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Text size', style: textTheme.titleSmall),
                    ),
                    Text(
                      '${(profile.fontScale * 100).round()}%',
                      style: textTheme.titleSmall,
                    ),
                  ],
                ),
                Slider(
                  min: 0.8,
                  max: 1.4,
                  divisions: 12,
                  value: profile.fontScale.clamp(0.8, 1.4).toDouble(),
                  semanticFormatterCallback: (value) =>
                      '${(value * 100).round()} percent',
                  onChanged: (value) {
                    ref
                        .read(profileProvider.notifier)
                        .update(profile.copyWith(fontScale: value));
                  },
                ),
              ],
            ),
            Text('Units', style: textTheme.titleSmall),
            Semantics(
              label: 'Unit system',
              child: SegmentedButton<UnitSystem>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: UnitSystem.metric,
                    label: Text('Metric'),
                  ),
                  ButtonSegment(
                    value: UnitSystem.imperial,
                    label: Text('Imperial'),
                  ),
                ],
                selected: {profile.unitSystem},
                onSelectionChanged: (selected) => _saveProfile(
                  context,
                  ref,
                  profile.copyWith(unitSystem: selected.first),
                ),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Notifications',
          children: [
            ToggleRow(
              title: 'Enable notifications',
              subtitle: 'Master switch for all reminders',
              value: masterOn,
              onChanged: (value) => _saveProfile(
                context,
                ref,
                profile.copyWith(notificationsEnabled: value),
              ),
            ),
            _subSwitch(
              context,
              ref,
              profile,
              title: 'Morning motivation',
              subtitle: 'Start your day with a nudge',
              value: profile.morningMotivation,
              enabled: masterOn,
              apply: (p, v) => p.copyWith(morningMotivation: v),
            ),
            _subSwitch(
              context,
              ref,
              profile,
              title: 'Goal reached alert',
              subtitle: 'Celebrate when you hit your daily goal',
              value: profile.goalReachedAlert,
              enabled: masterOn,
              apply: (p, v) => p.copyWith(goalReachedAlert: v),
            ),
            _subSwitch(
              context,
              ref,
              profile,
              title: 'Halfway reminder',
              subtitle: 'A push when you pass 50% of your goal',
              value: profile.halfwayReminder,
              enabled: masterOn,
              apply: (p, v) => p.copyWith(halfwayReminder: v),
            ),
            _subSwitch(
              context,
              ref,
              profile,
              title: 'Inactivity alert',
              subtitle: 'Reminds you to move after sitting too long',
              value: profile.inactivityAlert,
              enabled: masterOn,
              apply: (p, v) => p.copyWith(inactivityAlert: v),
            ),
            _subSwitch(
              context,
              ref,
              profile,
              title: 'Evening summary',
              subtitle: 'A recap of your day before bed',
              value: profile.eveningSummary,
              enabled: masterOn,
              apply: (p, v) => p.copyWith(eveningSummary: v),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Reminders',
          action: TextButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
            onPressed: () => _addReminder(context, ref),
          ),
          children: [
            if (reminders.isEmpty)
              Text(
                'No reminders yet. Add one to get nudged at a specific time.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            else
              for (final reminder in reminders)
                _reminderTile(context, ref, reminder),
          ],
        ),
        SettingsGroup(
          title: 'Data',
          children: [
            LinkRow(
              title: 'Export CSV',
              subtitle: 'Day-by-day step history',
              trailing: const Icon(Icons.ios_share_rounded),
              onTap: () => _exportCsv(context, ref),
            ),
            LinkRow(
              title: 'Export JSON',
              subtitle: 'Full backup including profile',
              trailing: const Icon(Icons.ios_share_rounded),
              onTap: () => _exportJson(context, ref),
            ),
            LinkRow(
              title: 'Import backup',
              subtitle: 'Restore from a previous backup file',
              trailing: chevron,
              onTap: () => _importBackup(context, ref),
            ),
            LinkRow(
              title: 'Reset all data',
              subtitle: 'Permanently delete everything',
              color: colorScheme.error,
              trailing: const Icon(Icons.delete_forever_rounded),
              onTap: () => _resetAllData(context, ref),
            ),
            Text(
              'Your data stays on this device. Source code is freely available.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SettingsGroup(
          title: 'About',
          children: [
            LinkRow(
              title: 'Stride',
              subtitle: 'Version 1.1.0',
              onTap: null,
            ),
            LinkRow(
              title: 'Made by Aditya Awasthi',
              onTap: null,
            ),
            LinkRow(
              title: 'GPL-3.0 \u2014 free and open-source',
              subtitle: 'Your data stays on your device. '
                  'Source code is freely available.',
              onTap: null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _subSwitch(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile, {
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required UserProfile Function(UserProfile, bool) apply,
  }) {
    return ToggleRow(
      title: title,
      subtitle: subtitle,
      value: value && enabled,
      onChanged:
          enabled ? (v) => _saveProfile(context, ref, apply(profile, v)) : null,
    );
  }

  Widget _reminderTile(
    BuildContext context,
    WidgetRef ref,
    ReminderItem reminder,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reminder.title, style: textTheme.titleSmall),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickReminderTime(context, ref, reminder),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    Formatters.timeOfDay(reminder.minutesOfDay),
                    semanticsLabel:
                        'Reminder time ${Formatters.timeOfDay(reminder.minutesOfDay)}, tap to change',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: 'Enable ${reminder.title}',
          child: Switch(
            value: reminder.enabled,
            onChanged: (value) =>
                ref.read(remindersProvider.notifier).toggle(reminder.id, value),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: colorScheme.onSurfaceVariant,
          tooltip: 'Delete reminder',
          onPressed: () {
            ref.read(remindersProvider.notifier).remove(reminder.id);
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }
}
