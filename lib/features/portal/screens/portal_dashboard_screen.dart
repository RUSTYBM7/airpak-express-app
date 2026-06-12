import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../../app/router.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

final _myShipmentsProvider = FutureProvider.autoDispose<RepoResult<List<Shipment>>>(
  (ref) async {
    final repo = ref.watch(shipmentRepoProvider);
    final auth = ref.watch(authControllerProvider);
    return repo.listShipments(userId: auth.userId);
  },
);

class PortalDashboardScreen extends ConsumerWidget {
  const PortalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final async = ref.watch(_myShipmentsProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(size: 32),
            SizedBox(width: 8),
            AirpakWordmark(size: 18, showUnderline: false, showR: false),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () => context.push(AppRoutes.portalSupport),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.brand)),
          error: (e, _) => ErrorStateView(error: e),
          data: (res) {
            final shipments = res.data ?? [];
            return RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () async => ref.invalidate(_myShipmentsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _GreetingCard(
                    name: auth.profile?.displayName ?? 'there',
                    shipments: shipments,
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionHeader('Recent shipments', padding: EdgeInsets.zero),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.portalShipments),
                        child: Text('See all',
                            style: TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (shipments.isEmpty)
                    EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No shipments yet',
                      subtitle:
                          'Create your first shipment to see it here.',
                      action: AppPrimaryButton(
                        label: 'Create shipment',
                        icon: Icons.add_rounded,
                        onPressed: () => context.push(AppRoutes.portalCreate),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final s in shipments.take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShipmentCard(
                              shipment: s,
                              onTap: () => context.push(
                                  '${AppRoutes.portalShipments}/${s.id}'),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  const SectionHeader('Wallet & rewards',
                      padding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppStatCard(
                          label: 'Wallet',
                          value: FormatUtils.currency(
                              auth.profile?.walletBalance ?? 0),
                          icon: Icons.account_balance_wallet_rounded,
                          gradient: AppColors.brandGradient,
                          iconColor: AppColors.brand,
                          trend: '+12%',
                          positive: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppStatCard(
                          label: 'Points',
                          value: '${auth.profile?.rewardPoints ?? 0}',
                          icon: Icons.card_giftcard_rounded,
                          gradient: AppColors.goldGradient,
                          iconColor: AppColors.gold,
                          trend: '+8%',
                          positive: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () => context.push(AppRoutes.portalCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New shipment',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _NotifTile(
                icon: Icons.local_shipping_rounded,
                title: 'Out for delivery',
                subtitle:
                    'APK20240521001230 is out for delivery in Petaling Jaya',
                time: '30m',
                color: AppColors.info,
                unread: true,
              ),
              const SizedBox(height: 8),
              _NotifTile(
                icon: Icons.card_giftcard_rounded,
                title: 'Reward points credited',
                subtitle: 'You earned 120 points on your last shipment',
                time: '1d',
                color: AppColors.gold,
                unread: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool unread;
  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.unread,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style:
                  TextStyle(color: context.textMutedColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final List<Shipment> shipments;
  const _GreetingCard({required this.name, required this.shipments});
  @override
  Widget build(BuildContext context) {
    final inTransit = shipments
        .where((s) =>
            s.status == ShipmentStatus.inTransit ||
            s.status == ShipmentStatus.outForDelivery ||
            s.status == ShipmentStatus.pickedUp)
        .length;
    final delivered =
        shipments.where((s) => s.status == ShipmentStatus.delivered).length;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name 👋',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              const Text("Here's what's happening with your parcels",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _stat(inTransit.toDouble(), 'In transit'),
                  _divider(),
                  _stat(delivered.toDouble(), 'Delivered'),
                  _divider(),
                  _stat(shipments.length.toDouble(), 'Total'),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _stat(double value, String label) => Expanded(
        child: Column(
          children: [
            AnimatedCounter(
              value: value,
              decimals: 0,
              duration: const Duration(milliseconds: 1400),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.18),
      );
}

class _QuickActions extends StatelessWidget {
  final _actions = const [
    (Icons.add_box_outlined, 'Create', AppRoutes.portalCreate),
    (Icons.qr_code_scanner_rounded, 'Track', AppRoutes.tracking),
    (Icons.receipt_long_rounded, 'Invoices', AppRoutes.portalPayments),
    (Icons.support_agent_rounded, 'Support', AppRoutes.portalSupport),
  ];
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      radius: AppRadius.lg,
      child: Row(
        children: [
          for (var i = 0; i < _actions.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => context.push(_actions[i].$3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(_actions[i].$1,
                            color: AppColors.brand, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(_actions[i].$2,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;
  const ShipmentCard({super.key, required this.shipment, this.onTap});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.trackingNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2),
                ),
              ),
              StatusPill(label: shipment.status.label, color: _colorFor(shipment.status)),
            ],
          ),
          const SizedBox(height: 12),
          SoftProgress(
              value: shipment.status.progress,
              color: _colorFor(shipment.status)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: context.textMutedColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(shipment.origin.city,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 12, color: context.textMutedColor),
              const SizedBox(width: 4),
              Icon(Icons.location_on_rounded,
                  size: 14, color: context.textMutedColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(shipment.destination.city,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_serviceIcon(shipment.service),
                  size: 14, color: AppColors.brand),
              const SizedBox(width: 4),
              Text(shipment.service,
                  style: TextStyle(
                      color: AppColors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(shipment.createdAt),
                style: TextStyle(
                    color: context.textMutedColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(String s) {
    switch (s) {
      case 'Express':
        return Icons.bolt_rounded;
      case 'Air Freight':
        return Icons.flight_rounded;
      case 'Sea Freight':
        return Icons.directions_boat_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

Color _colorFor(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.delivered:
      return AppColors.success;
    case ShipmentStatus.outForDelivery:
      return AppColors.info;
    case ShipmentStatus.exception:
      return AppColors.danger;
    case ShipmentStatus.cancelled:
    case ShipmentStatus.returned:
      return AppColors.textMuted;
    default:
      return AppColors.warning;
  }
}
