// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import 'glow_card.dart';

/// A small tappable card showing one headline metric.
///
/// Layout: a small [icon] and the [label] sit on top, with the large [value]
/// anchored at the bottom of the card. When [onTap] is provided the whole
/// card ripples and is exposed to assistive tech as a button.
class StatCard extends StatelessWidget {
  /// Creates a stat card with [label], [value] and [icon].
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconWidget,
    this.onTap,
  });

  /// Caption describing the metric, e.g. "Distance".
  final String label;

  /// Formatted metric value, e.g. "5.2 km".
  final String value;

  /// Icon shown next to the label.
  final IconData icon;

  /// Optional custom icon widget, used for the animated streak flame.
  final Widget? iconWidget;

  /// Called when the card is tapped; null makes the card non-interactive.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: iconWidget ??
                      Icon(icon, size: 20, color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    return MergeSemantics(
      child: Semantics(
        label: '$label: $value',
        button: onTap != null,
        child: GlowCard(
          intensity: 0.75,
          clipBehavior: Clip.antiAlias,
          child:
              onTap == null ? content : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}
