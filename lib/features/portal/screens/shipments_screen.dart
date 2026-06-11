import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';
import 'portal_dashboard_screen.dart' show ShipmentCard;

final _shipmentsProvider = FutureProvider.autoDispose
    .family<RepoResult<List<Shipment>>, _ShipmentsFilter>((ref, filter) async {
  final repo = ref.watch(shipmentRepoProvider);
  final auth = ref.watch(authControllerProvider);
  final res = await repo.listShipments(userId: auth.userId);
  if (res.data == null) return res;
  var list = res.data!;
  if (filter.status != null) {
    list = list.where((s) => s.status == filter.status).toList();
  }
  if (filter.query != null && filter.query!.isNotEmpty) {
    final q = filter.query!.toLowerCase();
    list = list.where((s) {
      return s.trackingNumber.toLowerCase().contains(q) ||
          s.destination.city.toLowerCase().contains(q) ||
          s.origin.city.toLowerCase().contains(q) ||
          (s.reference?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
  return RepoResult.ok(list);
});

class _ShipmentsFilter {
  final ShipmentStatus? status;
  final String? query;
  const _ShipmentsFilter({this.status, this.query});
  @override
  bool operator ==(Object other) =>
      other is _ShipmentsFilter &&
      other.status == status &&
      other.query == query;
  @override
  int get hashCode => Object.hash(status, query);
}

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});
  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final _search = TextEditingController();
  ShipmentStatus? _filter;
  late _ShipmentsFilter _state;

  @override
  void initState() {
    super.initState();
    _state = const _ShipmentsFilter();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _state =
          _ShipmentsFilter(status: _filter, query: _search.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('My shipments',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search by tracking, city, or reference',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) => _applyFilter(),
                onChanged: (_) => _applyFilter(),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () {
                        setState(() => _filter = null);
                        _applyFilter();
                      }),
                  for (final s in const [
                    ShipmentStatus.created,
                    ShipmentStatus.pickedUp,
                    ShipmentStatus.inTransit,
                    ShipmentStatus.outForDelivery,
                    ShipmentStatus.delivered,
                    ShipmentStatus.exception,
                  ])
                    _chip(
                      label: s.label,
                      selected: _filter == s,
                      color: _colorFor(s),
                      onTap: () {
                        setState(() => _filter = s);
                        _applyFilter();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final async = ref.watch(_shipmentsProvider(_state));
                return async.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.brand)),
                  error: (e, _) => ErrorStateView(error: e),
                  data: (res) {
                    final list = res.data ?? [];
                    if (list.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No shipments match',
                        subtitle:
                            'Try a different search or clear the filters.',
                        action: AppPrimaryButton(
                          label: 'Create shipment',
                          icon: Icons.add_rounded,
                          onPressed: () =>
                              context.push(AppRoutes.portalCreate),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.brand,
                      onRefresh: () async =>
                          ref.invalidate(_shipmentsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => ShipmentCard(
                          shipment: list[i],
                          onTap: () => context.push(
                              '${AppRoutes.portalShipments}/${list[i].id}'),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.portalCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.brand;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: c.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: selected ? c : AppColors.textBody,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        side: BorderSide(
          color: selected ? c : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        showCheckmark: false,
      ),
    );
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
