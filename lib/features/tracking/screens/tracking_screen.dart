import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../core/data/notification_center.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';
import '../../support/support_chat_controller.dart';

/// New tracking page = "ship column" + live map preview. Tapping a
/// shipment (or pressing "View on full map") opens the full-screen
/// Snapchat-style world map with pinch-zoom, then a tracking-history
/// button, share/PDF, and chat support.
class TrackingScreen extends ConsumerStatefulWidget {
  final String? initialTracking;
  const TrackingScreen({super.key, this.initialTracking});
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTracking ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _track() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    HapticService.light();
    context.push('${AppRoutes.tracking}/$t');
  }

  void _openLiveMap(String tracking) {
    HapticService.light();
    context.push('/portal/track/$tracking');
  }

  void _openChat() {
    HapticService.selection();
    context.push(AppRoutes.portalSupport);
  }

  void _openNotifications() {
    HapticService.selection();
    context.push('/portal/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userId = auth.profile?.id ?? 'demo';
    final async = ref.watch(_shipmentsProvider(userId));
    final chatState = ref.watch(supportChatControllerProvider(userId));
    final notifs = ref.watch(notificationCenterProvider);
    final unread = notifs.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Back',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.portalDashboard);
                        }
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor, size: 18),
                    ),
                    const Spacer(),
                    // Chat with unread badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Support chat',
                          onPressed: _openChat,
                          icon: Icon(Icons.support_agent_rounded, color: context.textColor, size: 20),
                        ),
                        if (chatState.hasUnreadAgentReply)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    // Notifications with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: _openNotifications,
                          icon: Icon(Icons.notifications_none_rounded, color: context.textColor, size: 20),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Track your parcel',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: context.textColor)),
                    const SizedBox(height: 4),
                    Text('Live updates from origin to doorstep.',
                        style: TextStyle(fontSize: 14, color: context.textMutedColor)),
                    const SizedBox(height: 18),
                    IosTextField(
                      controller: _ctrl,
                      hint: 'Enter tracking number (e.g. APK2026052900003)',
                      prefixIcon: Icons.numbers_rounded,
                      onSubmitted: (_) => _track(),
                    ),
                    const SizedBox(height: 12),
                    IosPrimaryButton(
                      label: 'Track',
                      icon: Icons.search_rounded,
                      onPressed: _track,
                    ),
                  ],
                ),
              ),
            ),
            // ── Ship column (your shipments) ────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Your shipments',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textColor)),
                    const Spacer(),
                    Text('Tap to open full live map',
                        style: TextStyle(fontSize: 11.5, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.brand))),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.all(40), child: EmptyState(icon: Icons.error_outline_rounded, title: 'Could not load shipments')),
              ),
              data: (res) {
                final all = res.data ?? [];
                if (all.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.local_shipping_rounded, color: AppColors.brand, size: 30),
                            ),
                            const SizedBox(height: 14),
                            Text('No shipments yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textColor)),
                            const SizedBox(height: 4),
                            Text('Search a tracking number above, or create a new shipment from the dashboard.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: context.textMutedColor, height: 1.45)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _ShipmentTrackCard(
                      shipment: all[i],
                      onTap: () => _openLiveMap(all[i].trackingNumber),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final _shipmentsProvider = FutureProvider.autoDispose
    .family<RepoResult<List<Shipment>>, String?>((ref, userId) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.listShipments(userId: userId);
});

class _ShipmentTrackCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  const _ShipmentTrackCard({required this.shipment, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IosContextMenu(
      actions: [
        IosContextMenuItem(
          label: 'View on full map',
          icon: Icons.map_rounded,
          onTap: onTap,
        ),
        IosContextMenuItem(
          label: 'Copy tracking number',
          icon: Icons.copy_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(text: shipment.trackingNumber));
            HapticService.success();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tracking number copied')),
            );
          },
        ),
        IosContextMenuItem(
          label: 'Notify on updates',
          icon: Icons.notifications_rounded,
          onTap: () {
            HapticService.selection();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You will be notified on updates.')),
            );
          },
        ),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map preview header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _TrackMapPreviewPainter(
                          progress: shipment.status.progress,
                          status: shipment.status,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(shipment.status).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(shipment.status.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen_rounded, size: 11, color: AppColors.brand),
                          SizedBox(width: 3),
                          Text('Tap for full map', style: TextStyle(color: AppColors.brand, fontSize: 9.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shipment.trackingNumber,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textColor)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(shipment.service, style: const TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flight_takeoff_rounded, size: 14, color: context.textMutedColor),
                        const SizedBox(width: 4),
                        Text(shipment.origin.city,
                            style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.east_rounded, size: 14, color: context.textMutedColor),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_rounded, size: 14, color: context.textMutedColor),
                        const SizedBox(width: 4),
                        Text(shipment.destination.city,
                            style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (shipment.estimatedDelivery != null)
                          Text(
                            'ETA ${DateFormat('MMM d').format(shipment.estimatedDelivery!)}',
                            style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(color: context.dividerColor, borderRadius: BorderRadius.circular(99)),
                        ),
                        FractionallySizedBox(
                          widthFactor: shipment.status.progress,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.brand, AppColors.warning]),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.delivered: return AppColors.success;
      case ShipmentStatus.outForDelivery: return AppColors.info;
      case ShipmentStatus.inTransit: return AppColors.brand;
      case ShipmentStatus.pickedUp: return AppColors.warning;
      case ShipmentStatus.exception: return AppColors.danger;
      case ShipmentStatus.cancelled: return AppColors.textMuted;
      case ShipmentStatus.returned: return AppColors.warning;
      case ShipmentStatus.created: return AppColors.info;
    }
  }
}

class _TrackMapPreviewPainter extends CustomPainter {
  final double progress;
  final ShipmentStatus status;
  _TrackMapPreviewPainter({required this.progress, required this.status});
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bg = Paint()..color = const Color(0xFF0E1320);
    canvas.drawRect(Offset.zero & size, bg);

    // Subtle grid
    final grid = Paint()
      ..color = const Color(0xFF2A3142).withValues(alpha: 0.4)
      ..strokeWidth = 0.4;
    for (int i = 0; i <= 8; i++) {
      final x = i * size.width / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int i = 0; i <= 4; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Route line (curved)
    final start = Offset(size.width * 0.10, size.height * 0.85);
    final end = Offset(size.width * 0.90, size.height * 0.15);
    final ctrl = Offset(size.width * 0.55, size.height * 0.30);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    // Background grey
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF3B475E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Active portion
    final metrics = path.computeMetrics().first;
    final activePath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(activePath, Paint()
      ..shader = const LinearGradient(colors: [AppColors.brand, AppColors.warning]).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Origin & destination dots
    canvas.drawCircle(start, 5, Paint()..color = AppColors.success);
    canvas.drawCircle(start, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(end, 5, Paint()..color = AppColors.danger);
    canvas.drawCircle(end, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Courier current position
    final t = progress.clamp(0.0, 1.0);
    final pt = _quadAt(t, start, ctrl, end);
    final pulse = ((DateTime.now().millisecondsSinceEpoch ~/ 1000) % 4) / 4.0;
    canvas.drawCircle(pt, 10 + pulse * 6, Paint()..color = AppColors.brand.withValues(alpha: (1 - pulse) * 0.45));
    canvas.drawCircle(pt, 7, Paint()..color = AppColors.brand);
    canvas.drawCircle(pt, 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  Offset _quadAt(double t, Offset p0, Offset p1, Offset p2) {
    final u = 1 - t;
    final x = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final y = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _TrackMapPreviewPainter old) =>
      old.progress != progress;
}
