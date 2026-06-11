import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../auth/providers/auth_controller.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  int _indexFor(String location) {
    if (location == AppRoutes.adminPortal) return 0;
    if (location.startsWith(AppRoutes.adminUsers)) return 1;
    if (location.startsWith(AppRoutes.adminChat)) return 2;
    if (location.startsWith(AppRoutes.adminSettings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);
    final isHome = loc == AppRoutes.adminPortal;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF111827)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Admin Console'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Create shipment',
            onPressed: () => context.push(AppRoutes.adminCreate),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go(AppRoutes.adminPortal);
                  break;
                case 1:
                  context.go(AppRoutes.adminUsers);
                  break;
                case 2:
                  context.go(AppRoutes.adminChat);
                  break;
                case 3:
                  context.go(AppRoutes.adminSettings);
                  break;
              }
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            selectedIconTheme: const IconThemeData(color: AppColors.brand),
            unselectedIconTheme:
                IconThemeData(color: context.textMutedColor),
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home')),
              NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Users')),
              NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Inbox')),
              NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: isHome
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              onPressed: () => context.push(AppRoutes.adminCreate),
              icon: const Icon(Icons.add),
              label: const Text('New shipment'),
            )
          : null,
    );
  }
}
