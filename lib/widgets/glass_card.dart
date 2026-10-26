// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Translucent surface with a hairline border and a soft accent-tinted glow,
/// ported from Flowstate's `GlassCard`.
///
/// Real backdrop blur is deliberately not used: over the black canvas a
/// translucent layer reads as frosted glass at almost no GPU cost.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
    this.onLongPress,
    this.borderRadius = AppTheme.cardRadius,
    this.glow = true,
  });

  /// Card content.
  final Widget child;

  /// Inner padding; Flowstate uses 20 dp.
  final EdgeInsetsGeometry padding;

  /// Overrides the translucent surface colour (e.g. an error container).
  final Color? color;

  /// Makes the whole card tappable with an ink ripple.
  final VoidCallback? onTap;

  /// Long-press action, used together with [onTap].
  final VoidCallback? onLongPress;

  /// Corner radius.
  final double borderRadius;

  /// Draws the soft accent-tinted shadow under the card.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final surface =
        color ?? scheme.surfaceContainer.withValues(alpha: dark ? 0.96 : 0.78);
    final border = dark
        ? scheme.outlineVariant
        : scheme.outlineVariant.withValues(alpha: 0.35);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSurface),
          child: content,
        ),
      ),
    );
  }
}

/// Springs content in once, staggered by [index] (Flowstate's `Entrance`):
/// fades in while rising 56 dp. Skipped when the system asks for reduced
/// motion.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.index, required this.child});

  /// Position in the screen; each step delays the start by 70 ms.
  final int index;

  /// The content to reveal.
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: const _SpringCurve(),
  );
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _delay = Timer(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final p = _progress.value;
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - p) * 56),
            child: child,
          ),
        );
      },
    );
  }
}

/// Approximates Compose's `spring(dampingRatio = 0.75, StiffnessLow)`:
/// a quick rise with a small overshoot that settles at 1.
class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    const zeta = 0.75;
    const omega = 9.0;
    final damped = omega * math.sqrt(1 - zeta * zeta);
    final envelope = math.exp(-zeta * omega * t);
    return 1 -
        envelope *
            (math.cos(damped * t) +
                (zeta * omega / damped) * math.sin(damped * t));
  }
}
