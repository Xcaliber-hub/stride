// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import 'glass_card.dart';

/// Scrolling screen body in the Flowstate layout: content capped at 720 dp
/// and centred, 20 dp side padding, clear of the status bar on top and of
/// the floating navigation bar at the bottom, with 16 dp between items.
/// Each child springs in with a staggered [Entrance].
class ScreenList extends StatelessWidget {
  const ScreenList({
    super.key,
    required this.children,
    this.bottomClearance = AppTheme.navClearance,
    this.animate = true,
    this.topPadding,
    this.controller,
  });

  /// Optional scroll controller.
  final ScrollController? controller;

  /// Screen sections, top to bottom.
  final List<Widget> children;

  /// Space kept free at the bottom (defaults to the nav bar's clearance).
  final double bottomClearance;

  /// Plays the staggered entrance animation.
  final bool animate;

  /// Overrides the top padding (defaults to status bar + 16 dp).
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            topPadding ?? media.padding.top + 16,
            AppTheme.pagePadding,
            bottomClearance + media.padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppTheme.cardGap),
                animate ? Entrance(index: i, child: children[i]) : children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
