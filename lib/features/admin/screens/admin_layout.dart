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

  static const _tabs = [
    (AppRoutes.adminPortal, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    (AppRoutes.adminUsers, Icons.people_outline, Icons.people, 'Users'),
    (AppRoutes.adminChat, Icons.chat_bubble_outline, Icons.chat_bubble, 'Inbox'),
    (
      AppRoutes.adminAiStudio,
      Icons.auto_awesome_outlined,
      Icons.auto_awesome,
      'AI'
    ),
    (
      AppRoutes.adminAutomation,
      Icons.auto_mode_outlined,
      Icons.auto_mode,
      'Rules'
    ),
    (
      AppRoutes.adminDocParser,
      Icons.description_outlined,
      Icons.description,
      'Docs'
    ),
    (
      AppRoutes.adminVoiceTools,
      Icons.record_voice_over_outlined,
      Icons.record_voice_over,
      'Voice'
    ),
    (
      AppRoutes.adminAuditLogs,
      Icons.fact_check_outlined,
      Icons.fact_check,
      'Audit'
    ),
    (
      AppRoutes.adminSettings,
      Icons.settings_outlined,
      Icons.settings,
      'Settings'
    ),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].$1) return i;
      if (location.startsWith(_tabs[i].$1 + '/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);
    final isHome = loc == AppRoutes.adminPortal;
    return Scaffold(
      backgroundColor: context.bgColor,
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
          _SideNav(
            tabs: _tabs,
            index: index,
            onTap: (i) => context.go(_tabs[i].$1),
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

class _SideNav extends StatelessWidget {
  final List<(String, IconData, IconData, String)> tabs;
  final int index;
  final ValueChanged<int> onTap;
  const _SideNav(
      {required this.tabs, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: SafeArea(
        right: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          children: [
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onTap(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: index == i
                            ? AppColors.brandLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              index == i ? tabs[i].$3 : tabs[i].$2,
                              color: index == i
                                  ? AppColors.brand
                                  : context.textMutedColor,
                              size: 18),
                          const SizedBox(width: 10),
                          Text(tabs[i].$4,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: index == i
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: index == i
                                      ? AppColors.brand
                                      : context.textColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
