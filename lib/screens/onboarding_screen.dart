// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../utils/formatters.dart';
import '../themes/app_theme.dart';
import '../viewmodels/providers.dart';
import '../widgets/glass_card.dart';

/// First-run onboarding: welcome, daily goal, and optional profile details.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the onboarding flow.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  double _goal = 10000;
  UnitSystem _units = UnitSystem.metric;
  Gender? _gender;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue.')),
      );
      return;
    }
    final heightInput = double.tryParse(_heightController.text.trim());
    final weightInput = double.tryParse(_weightController.text.trim());
    final imperial = _units == UnitSystem.imperial;
    final current = ref.read(profileProvider);
    final updated = current.copyWith(
      name: name,
      dailyGoal: _goal.round(),
      unitSystem: _units,
      age: int.tryParse(_ageController.text.trim()),
      heightCm: heightInput == null
          ? null
          : imperial
              ? heightInput * 30.48
              : heightInput,
      weightKg: weightInput == null
          ? null
          : imperial
              ? weightInput / 2.20462
              : weightInput,
      gender: _gender,
    );
    await ref.read(profileProvider.notifier).update(updated);
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    HapticFeedback.mediumImpact();
    ref.invalidate(onboardingDoneProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _welcomePage(context, colorScheme),
                  _goalPage(context, colorScheme),
                  _profilePage(context, colorScheme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared page frame: Flowstate's 20 dp padding and 720 dp width cap.
  Widget _frame(List<Widget> children) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Entrance(index: i, child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: textTheme.headlineLarge),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _navRow({
    required VoidCallback? onBack,
    required String nextLabel,
    required VoidCallback onNext,
  }) {
    return Row(
      children: [
        if (onBack != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 60)),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 60)),
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }

  Widget _welcomePage(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return _frame([
      const SizedBox(height: 24),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                colorScheme.primary,
                colorScheme.tertiary,
                colorScheme.primary,
              ],
            ),
          ),
          child: Icon(
            Icons.directions_walk_rounded,
            size: 44,
            color: colorScheme.onPrimary,
            semanticLabel: 'Walking person',
          ),
        ),
      ),
      _heading(
        context,
        'Welcome to Stride',
        'A free and open-source step counter. '
            'No ads, no tracking \u2014 just your steps.',
      ),
      GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_rounded,
              size: 20,
              color: colorScheme.primary,
              semanticLabel: 'Privacy',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'To count your steps, the app uses your device\u2019s '
                'activity-recognition sensor. You\u2019ll be asked for '
                'permission next \u2014 your step data never leaves this '
                'device.',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () => _goTo(1),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text('Get started',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
            )),
      ),
    ]);
  }

  Widget _goalPage(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return _frame([
      _heading(
        context,
        'Daily goal',
        'You can change this any time in Settings.',
      ),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Steps per day',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              Formatters.steps(_goal.round()),
              style: textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Daily step goal',
              value: '${_goal.round()} steps',
              child: Slider(
                value: _goal,
                min: 1000,
                max: 30000,
                divisions: 58,
                label: Formatters.steps(_goal.round()),
                onChanged: (value) => setState(() => _goal = value),
              ),
            ),
          ],
        ),
      ),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Units', style: textTheme.titleMedium),
            const SizedBox(height: 12),
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
                selected: {_units},
                onSelectionChanged: (selected) =>
                    setState(() => _units = selected.first),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _navRow(
        onBack: () => _goTo(0),
        nextLabel: 'Continue',
        onNext: () => _goTo(2),
      ),
    ]);
  }

  Widget _profilePage(BuildContext context, ColorScheme colorScheme) {
    return _frame([
      _heading(
        context,
        'About you',
        'Your name personalizes greetings and is used as your display name '
            'if you create or join a private group. Other details are optional '
            'and used only for calorie and distance estimates, stored on-device.',
      ),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                suffixText: 'years',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Height',
                      suffixText: _units == UnitSystem.imperial ? 'ft' : 'cm',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: _units == UnitSystem.imperial ? 'lb' : 'kg',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender?>(
              initialValue: _gender,
              borderRadius: BorderRadius.circular(16),
              decoration: const InputDecoration(labelText: 'Gender'),
              items: [
                const DropdownMenuItem<Gender?>(
                  value: null,
                  child: Text('Prefer not to say'),
                ),
                for (final g in Gender.values)
                  DropdownMenuItem<Gender?>(
                    value: g,
                    child: Text(
                      g.name[0].toUpperCase() + g.name.substring(1),
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _navRow(
        onBack: () => _goTo(1),
        nextLabel: 'Start tracking',
        onNext: _finish,
      ),
    ]);
  }
}
