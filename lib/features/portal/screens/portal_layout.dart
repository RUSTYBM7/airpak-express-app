import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';

class PortalLayout extends ConsumerWidget {
  final Widget child;
  const PortalLayout({super.key, required this.child});

  static const _tabs = [
    (AppRoutes.portalDashboard, Icons.dashboard_outlined, 'Home'),
    (AppRoutes.portalShipments, Icons.inventory_2_outlined, 'Shipments'),
    (AppRoutes.portalPayments, Icons.credit_card, 'Payments'),
    (AppRoutes.portalRewards, Icons.card_giftcard, 'Rewards'),
    (AppRoutes.portalSettings, Icons.settings_outlined, 'Settings'),
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandLight,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.$2, color: context.textMutedColor),
              selectedIcon: Icon(t.$2, color: AppColors.brand),
              label: t.$3,
            ),
        ],
      ),
    );
  }
}
