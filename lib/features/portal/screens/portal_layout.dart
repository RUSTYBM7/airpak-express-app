import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../app/cupertino.dart';

class PortalLayout extends ConsumerWidget {
  final Widget child;
  const PortalLayout({super.key, required this.child});

  static const _tabs = [
    (AppRoutes.portalDashboard, CupertinoIcons.house, 'Home'),
    (AppRoutes.portalShipments, CupertinoIcons.cube_box, 'Shipments'),
    (AppRoutes.portalPayments, CupertinoIcons.creditcard, 'Payments'),
    (AppRoutes.portalRewards, CupertinoIcons.gift, 'Rewards'),
    (AppRoutes.portalSettings, CupertinoIcons.settings, 'Settings'),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].$1) return i;
    }
    if (location.startsWith(AppRoutes.portalShipments)) return 1;
    if (location.startsWith(AppRoutes.portalPayments)) return 2;
    if (location.startsWith(AppRoutes.portalRewards)) return 3;
    if (location.startsWith(AppRoutes.portalSettings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgColor,
      // Edge-to-edge: content extends behind the status bar.
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: child,
      // iOS-style translucent bottom bar.
      bottomNavigationBar: _IosTabBar(
        tabs: _tabs,
        index: index,
        isDark: isDark,
        onTap: (i) {
          HapticService.selection();
          context.go(_tabs[i].$1);
        },
      ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  final List<(String, IconData, String)> tabs;
  final int index;
  final bool isDark;
  final ValueChanged<int> onTap;
  const _IosTabBar({
    required this.tabs,
    required this.index,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: context.dividerColor, width: 0.33),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: context.bgColor
                .withValues(alpha: isDark ? 0.78 : 0.82),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(
                        child: _IosTabItem(
                          icon: tabs[i].$2,
                          label: tabs[i].$3,
                          selected: index == i,
                          onTap: () => onTap(i),
                        ),
                      ),
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

class _IosTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IosTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              size: 26,
              color: selected
                  ? AppColors.brand
                  : context.textMutedColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.brand
                  : context.textMutedColor,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
