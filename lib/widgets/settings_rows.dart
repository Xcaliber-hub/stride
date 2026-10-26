// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import 'glass_card.dart';
import 'section_header.dart';

/// A settings group in the Flowstate style: a glass card with a
/// `titleLarge` heading and its rows spaced 14 dp apart.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, large: true, action: action),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Title + subtitle text pair used by the settings rows.
class _RowText extends StatelessWidget {
  const _RowText({required this.title, this.subtitle, this.color});

  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall?.copyWith(color: color)),
        if (subtitle != null)
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              color: color?.withValues(alpha: 0.8) ?? scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Flowstate's `ToggleRow`: title and subtitle with a trailing switch.
/// A null [onChanged] shows the row disabled.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Opacity(
        opacity: onChanged == null ? 0.5 : 1,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _RowText(title: title, subtitle: subtitle),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Flowstate's `LinkRow`: a tappable title and subtitle, at least 48 dp
/// tall, with an optional trailing widget.
class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.color,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Text colour override, e.g. the error colour for destructive actions.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _RowText(title: title, subtitle: subtitle, color: color),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                IconTheme.merge(
                  data: IconThemeData(
                    color:
                        color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
