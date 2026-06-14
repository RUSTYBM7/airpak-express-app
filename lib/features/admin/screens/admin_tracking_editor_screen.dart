import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

/// Admin-only screen to update a shipment's tracking history.
///
/// The customer sees a read-only timeline. Only admins (this screen)
/// can append events, place holds with reasons, or push a new
/// "present location" update.
class AdminTrackingEditorScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const AdminTrackingEditorScreen({super.key, required this.shipmentId});
  @override
  ConsumerState<AdminTrackingEditorScreen> createState() =>
      _AdminTrackingEditorScreenState();
}

class _AdminTrackingEditorScreenState
    extends ConsumerState<AdminTrackingEditorScreen> {
  bool _busy = false;
  int _refresh = 0;

  Future<RepoResult<Shipment?>> _loadShipment() async {
    final repo = ref.read(shipmentRepoProvider);
    final res = await repo.listShipments();
    final all = res.data ?? [];
    return RepoResult.ok(all.where((s) => s.id == widget.shipmentId).cast<Shipment?>().firstOrNull);
  }

  Future<void> _appendEvent(Shipment ship, ShipmentStatus status, String location, String? desc) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(shipmentRepoProvider);
      await repo.appendEvent(
        shipmentId: ship.id,
        status: status,
        location: location,
        description: desc,
      );
      HapticService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event added: $status · $location'), backgroundColor: AppColors.success),
        );
        setState(() => _refresh++);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: FutureBuilder<RepoResult<Shipment?>>(
          future: _loadShipment(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brand));
            }
            final ship = snap.data?.data;
            if (ship == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyState(icon: Icons.local_shipping_outlined, title: 'Shipment not found'),
                    const SizedBox(height: 16),
                    IosTextButton('Go back', onPressed: () => context.canPop() ? context.pop() : context.go('/admin/portal/shipments')),
                  ],
                ),
              );
            }
            return _EditorBody(
              key: ValueKey('${ship.id}_$_refresh'),
              ship: ship,
              busy: _busy,
              onAppend: _appendEvent,
              onRefresh: () => setState(() => _refresh++),
            );
          },
        ),
      ),
    );
  }
}

extension _ListX<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class _EditorBody extends ConsumerStatefulWidget {
  final Shipment ship;
  final bool busy;
  final Future<void> Function(Shipment, ShipmentStatus, String, String?) onAppend;
  final VoidCallback onRefresh;
  const _EditorBody({
    super.key,
    required this.ship,
    required this.busy,
    required this.onAppend,
    required this.onRefresh,
  });
  @override
  ConsumerState<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends ConsumerState<_EditorBody> {
  @override
  Widget build(BuildContext context) {
    final ship = widget.ship;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/admin/portal/shipments'),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 12, color: AppColors.brand),
                      SizedBox(width: 4),
                      Text('Admin', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ship.trackingNumber, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textColor)),
                const SizedBox(height: 4),
                Text('${ship.origin.city} → ${ship.destination.city} · ${ship.status.label}',
                    style: TextStyle(fontSize: 13, color: context.textMutedColor)),
              ],
            ),
          ),
        ),

        // Quick actions
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: IosSection(
              header: 'Quick updates',
              margin: EdgeInsets.zero,
              rows: [
                IosRow(
                  leading: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 14),
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  label: 'Picked up',
                  sublabel: 'Mark package collected from sender',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.pickedUp, 'Origin facility'),
                ),
                IosRow(
                  leading: const Icon(Icons.flight_rounded, color: Colors.white, size: 14),
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.info,
                  label: 'In transit',
                  sublabel: 'Currently on a linehaul',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.inTransit, 'Linehaul'),
                ),
                IosRow(
                  leading: const Icon(Icons.gavel_rounded, color: Colors.white, size: 14),
                  icon: Icons.gavel_rounded,
                  iconColor: AppColors.warning,
                  label: 'Hold · customs',
                  sublabel: 'Held by customs at border',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.exception, 'Customs · border checkpoint', 'Held by customs — documents under review'),
                ),
                IosRow(
                  leading: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 14),
                  icon: Icons.shield_moon_rounded,
                  iconColor: AppColors.warning,
                  label: 'Hold · border regulator',
                  sublabel: 'Stopped by border security',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.exception, 'Border security', 'Held by border regulator — clearance in progress'),
                ),
                IosRow(
                  leading: const Icon(Icons.local_police_rounded, color: Colors.white, size: 14),
                  icon: Icons.local_police_rounded,
                  iconColor: AppColors.warning,
                  label: 'Hold · security guards',
                  sublabel: 'Stopped by armed security',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.exception, 'Security checkpoint', 'Held by security guards — secondary inspection'),
                ),
                IosRow(
                  leading: const Icon(Icons.payments_rounded, color: Colors.white, size: 14),
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.danger,
                  label: 'Hold · payment',
                  sublabel: 'Duty or surcharge outstanding',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.exception, 'Customs counter', 'Payment hold — duty/VAT owed'),
                ),
                IosRow(
                  leading: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 14),
                  icon: Icons.delivery_dining_rounded,
                  iconColor: AppColors.info,
                  label: 'Out for delivery',
                  sublabel: 'Courier has the package',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.outForDelivery, 'Local delivery vehicle'),
                ),
                IosRow(
                  leading: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 14),
                  icon: Icons.task_alt_rounded,
                  iconColor: AppColors.success,
                  label: 'Delivered',
                  sublabel: 'Package delivered to recipient',
                  trailing: IosTrailing.none,
                  onTap: () => _showAddSheet(ship, ShipmentStatus.delivered, '${ship.destination.city}, ${ship.destination.country}'),
                ),
              ],
            ),
          ),
        ),

        // Custom event
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: IosPrimaryButton(
              label: 'Add custom tracking event',
              icon: Icons.add_location_alt_rounded,
              onPressed: () => _showAddSheet(ship, null, ''),
            ),
          ),
        ),

        // Existing timeline (read-only mirror of what the customer sees)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _ExistingEventsList(shipId: ship.id, onChange: widget.onRefresh),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(Shipment ship, ShipmentStatus? defaultStatus, String defaultLocation, [String? defaultDesc]) async {
    final statusCtrl = ValueNotifier<ShipmentStatus?>(defaultStatus);
    final locCtrl = TextEditingController(text: defaultLocation);
    final descCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    await showIosSheet(
      context: context,
      title: 'Append tracking event',
      isScrollControlled: true,
      initialChildSize: 0.78,
      child: StatefulBuilder(
        builder: (ctx, setSt) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status picker
              const Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: ShipmentStatus.values.map((s) {
                  final selected = statusCtrl.value == s;
                  return GestureDetector(
                    onTap: () { HapticService.selection(); setSt(() => statusCtrl.value = s); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: selected ? AppColors.brand : AppColors.border),
                      ),
                      child: Text(s.label,
                          style: TextStyle(color: selected ? Colors.white : AppColors.textBody, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              IosTextField(controller: locCtrl, hint: 'Present location (city, country)', prefixIcon: Icons.place_rounded),
              const SizedBox(height: 8),
              IosTextField(controller: descCtrl, hint: 'Description (optional)', prefixIcon: Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 14),
              const Text('LIVE COORDINATES (optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: IosTextField(controller: latCtrl, hint: 'Latitude', prefixIcon: Icons.north_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: IosTextField(controller: lngCtrl, hint: 'Longitude', prefixIcon: Icons.east_rounded, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 18),
              IosPrimaryButton(
                label: widget.busy ? 'Saving…' : 'Save event',
                icon: Icons.cloud_upload_rounded,
                onPressed: widget.busy
                    ? null
                    : () {
                        final st = statusCtrl.value;
                        final loc = locCtrl.text.trim();
                        if (st == null || loc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pick a status and location.')),
                          );
                          return;
                        }
                        String? desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                        final lat = latCtrl.text.trim();
                        final lng = lngCtrl.text.trim();
                        if (lat.isNotEmpty && lng.isNotEmpty) {
                          desc = '${desc ?? ''}\n[coords: $lat, $lng]'.trim();
                        }
                        Navigator.pop(context);
                        widget.onAppend(ship, st, loc, desc);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExistingEventsList extends ConsumerWidget {
  final String shipId;
  final VoidCallback onChange;
  const _ExistingEventsList({required this.shipId, required this.onChange});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(_eventsProvider(shipId));
    return events.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      ),
      error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Failed: $e')),
      data: (res) {
        final list = res.data ?? [];
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.timeline_rounded, title: 'No events yet');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Text('Existing history (${list.length})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
            ),
            IosSection(
              header: '',
              margin: EdgeInsets.zero,
              rows: list.take(20).map((e) => IosRow(
                icon: _iconFor(e.status),
                iconColor: _colorFor(e.status),
                label: e.status.label,
                sublabel: '${e.location} · ${DateFormat('MMM d, HH:mm').format(e.occurredAt)}',
                trailing: IosTrailing.none,
              )).toList(),
            ),
          ],
        );
      },
    );
  }

  IconData _iconFor(ShipmentStatus s) {
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
  Color _colorFor(ShipmentStatus s) {
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

final _eventsProvider = FutureProvider.autoDispose
    .family<RepoResult<List<TrackingEvent>>, String>((ref, shipId) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.events(shipId);
});
