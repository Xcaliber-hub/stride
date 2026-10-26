// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import '../widgets/floating_nav_bar.dart';

/// Root shell hosting the five main tabs of the app.
///
/// Keeps each tab mounted (so scroll position and state survive), cross-fades
/// between them with Flowstate's fade + slight scale-in, and floats
/// Flowstate's capsule navigation bar over the content. The bar slides away
/// while scrolling down and returns on any upward scroll.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _index = 0;
  bool _navVisible = true;

  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    StatsScreen(),
    AchievementsScreen(),
    GroupsScreen(),
    SettingsScreen(),
  ];

  static const List<NavTab> _tabs = [
    NavTab(
        icon: Icons.directions_walk_rounded,
        label: 'Today',
        tooltip: 'Dashboard'),
    NavTab(
        icon: Icons.bar_chart_rounded, label: 'Statistics', tooltip: 'Stats'),
    NavTab(
        icon: Icons.emoji_events_rounded,
        label: 'Awards',
        tooltip: 'Achievements'),
    NavTab(
        icon: Icons.groups_rounded,
        label: 'Groups',
        tooltip: 'Friends and groups'),
    NavTab(
        icon: Icons.settings_rounded, label: 'Settings', tooltip: 'Settings'),
  ];

  void _select(int index) {
    setState(() {
      _index = index;
      _navVisible = true;
    });
  }

  bool _onScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _navVisible) {
      setState(() => _navVisible = false);
    } else if (direction == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: Stack(
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _index != i,
                      child: ExcludeSemantics(
                        excluding: _index != i,
                        child: AnimatedOpacity(
                          opacity: _index == i ? 1 : 0,
                          duration: _index == i
                              ? const Duration(milliseconds: 320)
                              : const Duration(milliseconds: 90),
                          curve: _index == i
                              ? const Interval(0.25, 1, curve: Curves.easeOut)
                              : Curves.linear,
                          child: AnimatedScale(
                            scale: _index == i ? 1 : 0.96,
                            duration: const Duration(milliseconds: 320),
                            curve: const Interval(0.25, 1,
                                curve: Curves.easeOutCubic),
                            child: TickerMode(
                              enabled: _index == i,
                              child: _pages[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavBar(
              tabs: _tabs,
              selectedIndex: _index,
              visible: _navVisible,
              onSelect: _select,
            ),
          ),
        ],
      ),
    );
  }
}
