// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

/// Card heading in the Flowstate style: a `titleMedium` label at the top of
/// a glass card (or `titleLarge` for settings groups via [large]), with an
/// optional trailing [action].
class SectionHeader extends StatelessWidget {
  /// Creates a section header with [title] and an optional [action].
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.large = false,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  /// Section title text.
  final String title;

  /// Trailing widget, e.g. a "See all" TextButton.
  final Widget? action;

  /// Uses `titleLarge`, as Flowstate's settings group titles do.
  final bool large;

  /// Space around the header.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: large ? textTheme.titleLarge : textTheme.titleMedium,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
