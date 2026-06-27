import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../core/data/notification_center.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationCenterProvider);
    final unread = notifs.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (notifs.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(notificationCenterProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? const _EmptyNotif()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = notifs[i];
                return _NotifCard(
                  notif: n,
                  onTap: () {
                    ref.read(notificationCenterProvider.notifier).markRead(n.id);
                    if (n.actionRoute != null) context.push(n.actionRoute!);
                  },
                );
              },
            ),
      bottomNavigationBar: unread > 0
          ? Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.brandSoft,
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.brand, size: 18),
                  const SizedBox(width: 8),
                  Text('$unread new notification${unread == 1 ? "" : "s"}',
                      style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : null,
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: notif.isRead ? context.surfaceColor : AppColors.brandSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: notif.isRead ? context.borderColor : AppColors.brand.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: notif.isRead ? context.bgColor : AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(notif.iconName),
                color: notif.isRead ? context.textMutedColor : Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800, color: context.textColor)),
                      ),
                      Text(_relative(notif.sentAt),
                          style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: TextStyle(fontSize: 13, color: context.textMutedColor, height: 1.4)),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? name) {
    switch (name) {
      case 'support_agent': return Icons.support_agent_rounded;
      case 'local_shipping': return Icons.local_shipping_rounded;
      case 'attach_money': return Icons.attach_money_rounded;
      case 'verified': return Icons.verified_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(t);
  }
}

class _EmptyNotif extends StatelessWidget {
  const _EmptyNotif();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.brand, size: 40),
            ),
            const SizedBox(height: 18),
            Text('No notifications yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textColor)),
            const SizedBox(height: 6),
            Text('When support messages you, or your shipment status changes, it shows up here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: context.textMutedColor, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
