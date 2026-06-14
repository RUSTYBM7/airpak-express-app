import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

/// Admin shipments list — every parcel on the platform.
/// Tap any row to open the tracking editor (admin-only write).
class AdminShipmentsScreen extends ConsumerStatefulWidget {
  const AdminShipmentsScreen({super.key});
  @override
  ConsumerState<AdminShipmentsScreen> createState() => _AdminShipmentsScreenState();
}

class _AdminShipmentsScreenState extends ConsumerState<AdminShipmentsScreen> {
  String _status = 'All';
  String _search = '';

  static const _statuses = ['All', 'Created', 'Picked up', 'In transit', 'Out for delivery', 'Delivered', 'On hold'];

  @override
  Widget build(BuildContext context) {
    final shipAsync = ref.watch(_shipmentsProvider);
    final usersAsync = ref.watch(_usersProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Shipments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.textColor)),
              const SizedBox(width: 8),
              shipAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (res) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${(res.data ?? []).length}', style: const TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
              const Spacer(),
              IosPrimaryButton(label: 'New', icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.adminCreate)),
            ],
          ),
          const SizedBox(height: 12),
          IosTextField(
            controller: TextEditingController(),
            hint: 'Search by tracking # or destination',
            prefixIcon: Icons.search_rounded,
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final s = _statuses[i];
                final selected = s == _status;
                return GestureDetector(
                  onTap: () { HapticService.selection(); setState(() => _status = s); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brand : context.surfaceColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: selected ? AppColors.brand : context.borderColor),
                    ),
                    child: Text(s, style: TextStyle(color: selected ? Colors.white : context.textColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: shipAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (res) {
                final all = res.data ?? [];
                final users = (usersAsync.value?.data ?? []).cast<AppProfile>();
                final userById = {for (final u in users) u.id: u};
                final filtered = all.where((s) {
                  if (_status != 'All') {
                    if (_status == 'On hold' && s.status != ShipmentStatus.exception) return false;
                    if (_status != 'On hold' && s.status.label != _status) return false;
                  }
                  if (_search.isNotEmpty) {
                    final q = _search;
                    final hit = s.trackingNumber.toLowerCase().contains(q) ||
                        s.destination.city.toLowerCase().contains(q) ||
                        s.origin.city.toLowerCase().contains(q) ||
                        s.destination.country.toLowerCase().contains(q);
                    if (!hit) return false;
                  }
                  return true;
                }).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(icon: Icons.local_shipping_outlined, title: 'No shipments match');
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    final u = userById[s.userId];
                    return _AdminShipmentRow(shipment: s, user: u);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _shipmentsProvider = FutureProvider.autoDispose<RepoResult<List<Shipment>>>((ref) async {
  return ref.watch(shipmentRepoProvider).listShipments();
});

final _usersProvider = FutureProvider.autoDispose<RepoResult<List<AppProfile>>>((ref) async {
  return ref.watch(shipmentRepoProvider).listProfiles();
});

class _AdminShipmentRow extends StatelessWidget {
  final Shipment shipment;
  final AppProfile? user;
  const _AdminShipmentRow({required this.shipment, this.user});
  @override
  Widget build(BuildContext context) {
    final s = shipment;
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/portal/shipment/${s.id}/tracking'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_statusColor(s.status).withValues(alpha: 0.4), _statusColor(s.status)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(s.status), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(s.trackingNumber, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.textColor)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(s.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(s.status.label, style: TextStyle(color: _statusColor(s.status), fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.flight_takeoff_rounded, size: 11, color: context.textMutedColor),
                        const SizedBox(width: 3),
                        Text('${s.origin.city}', style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Icon(Icons.east_rounded, size: 11, color: context.textMutedColor),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_rounded, size: 11, color: context.textMutedColor),
                        const SizedBox(width: 3),
                        Text('${s.destination.city}', style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (user != null) ...[
                          Icon(Icons.person_rounded, size: 11, color: context.textMutedColor),
                          const SizedBox(width: 3),
                          Expanded(child: Text(user!.displayName, style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                        ],
                        Text(DateFormat('MMM d').format(s.createdAt), style: TextStyle(fontSize: 10.5, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.push('/admin/portal/shipment/${s.id}/tracking'),
                icon: Icon(Icons.chevron_right_rounded, color: context.textMutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.delivered: return Icons.task_alt_rounded;
      case ShipmentStatus.outForDelivery: return Icons.delivery_dining_rounded;
      case ShipmentStatus.inTransit: return Icons.flight_rounded;
      case ShipmentStatus.pickedUp: return Icons.local_shipping_rounded;
      case ShipmentStatus.exception: return Icons.warning_amber_rounded;
      case ShipmentStatus.cancelled: return Icons.cancel_rounded;
      case ShipmentStatus.returned: return Icons.assignment_return_rounded;
      case ShipmentStatus.created: return Icons.fiber_new_rounded;
    }
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
