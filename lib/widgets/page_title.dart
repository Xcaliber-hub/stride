// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

/// Screen heading in the Flowstate style: a semibold `headlineLarge` title
/// with an optional `bodyLarge` subtitle (e.g. the date) and an optional
/// trailing action. Announced to assistive tech as a heading.
class PageTitle extends StatelessWidget {
  /// Creates a page heading with [title] and an optional [subtitle].
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  /// The big heading text.
  final String title;

  /// Smaller line under the heading, e.g. the date.
  final String? subtitle;

  /// Optional widget at the end of the title row (e.g. an icon button).
  final Widget? trailing;

  /// Space around the heading; screens already pad their content.
  final EdgeInsetsGeometry padding;

  /// Text style of the heading, shared with screens that lay it out by hand.
  static TextStyle? titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: titleStyle(context)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
    return Padding(
      padding: padding,
      child: trailing == null
          ? heading
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: heading), trailing!],
            ),
    );
  }
}
