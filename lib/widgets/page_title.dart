// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

/// Large, bold page heading with an optional subtitle.
///
/// Sits at the top of each main screen. Announced to assistive tech as a
/// heading.
class PageTitle extends StatelessWidget {
  /// Creates a page heading with [title] and an optional [subtitle].
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 20),
  });

  /// The big heading text.
  final String title;

  /// Smaller line under the heading, e.g. the date.
  final String? subtitle;

  /// Space around the heading; the default lines it up with the cards.
  final EdgeInsetsGeometry padding;

  /// Text style of the heading, shared with screens that lay it out by hand.
  static TextStyle? titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.08,
          letterSpacing: -1.2,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: titleStyle(context)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
