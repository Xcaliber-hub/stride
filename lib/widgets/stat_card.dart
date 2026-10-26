// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import 'glass_card.dart';

/// One headline metric on a glass card, laid out like Flowstate's stat
/// tiles: a small accent icon and `labelLarge` caption on top, the value in
/// `headlineMedium` below. When [onTap] is provided the card ripples and is
/// exposed to assistive tech as a button.
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

    return MergeSemantics(
      child: Semantics(
        label: '$label: $value',
        button: onTap != null,
        child: GlassCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: Center(
                      child: iconWidget ??
                          Icon(icon, size: 20, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child:
                    Text(value, style: textTheme.headlineMedium, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays cards out two per row with Flowstate's 16 dp gaps; cards in a row
/// share the height of the tallest one.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.spacing = 16});

  /// The cards, in reading order.
  final List<Widget> children;

  /// Gap between cards in both directions.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
