// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One destination of [FloatingNavBar].
class NavTab {
  const NavTab({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String tooltip;
}

/// Capsule navigation that floats over the content, ported from Flowstate's
/// `FloatingNavBar`. Only the selected tab shows its label in a
/// primary-container pill that resizes smoothly. [visible] slides the bar off
/// screen so the shell can hide it while the user scrolls down.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    this.visible = true,
  });

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 2),
      duration: const Duration(milliseconds: 380),
      curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 16, left: 12, right: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.5 : 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: scheme.surfaceContainerHigh
                  .withValues(alpha: dark ? 0.98 : 0.82),
              surfaceTintColor: Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: dark
                      ? scheme.outlineVariant
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _NavItem(
                        tab: tabs[i],
                        selected: i == selectedIndex,
                        onTap: () {
                          if (i == selectedIndex) return;
                          HapticFeedback.selectionClick();
                          onSelect(i);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      label: tab.tooltip,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 12 : 9,
            vertical: 12,
          ),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: selected ? scheme.primaryContainer : Colors.transparent,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, color: tint, size: 24),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    tab.label,
                    maxLines: 1,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: tint),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
