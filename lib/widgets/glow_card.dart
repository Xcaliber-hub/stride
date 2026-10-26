// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import 'glass_card.dart';

/// Compatibility wrapper around [GlassCard] for callers that add their own
/// padding. Renders the Flowstate glass surface (translucent fill, hairline
/// border, soft accent glow) with no inner padding.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.color,
    this.intensity = 1.0,
    this.borderRadius = AppTheme.cardRadius,
    this.margin,
    this.clipBehavior,
  });

  /// Card content.
  final Widget child;

  /// Surface colour override.
  final Color? color;

  /// 0 hides the accent glow; anything above keeps it.
  final double intensity;

  /// Corner radius.
  final double borderRadius;

  /// Outer margin; none by default because screens space cards themselves.
  final EdgeInsetsGeometry? margin;

  /// Kept for API compatibility; the glass surface always clips.
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: EdgeInsets.zero,
      color: color,
      borderRadius: borderRadius,
      glow: intensity > 0,
      child: child,
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}
