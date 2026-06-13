import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cupertino.dart';
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
  final _Sort sort;
  const _ShipmentsFilter({this.status, this.query, this.sort = _Sort.recent});
  _ShipmentsFilter copyWith({ShipmentStatus? status, String? query, _Sort? sort}) =>
      _ShipmentsFilter(
        status: status ?? this.status,
        query: query ?? this.query,
        sort: sort ?? this.sort,
      );
  @override
  bool operator ==(Object other) =>
      other is _ShipmentsFilter &&
      other.status == status &&
      other.query == query &&
      other.sort == sort;
  @override
  int get hashCode => Object.hash(status, query, sort);
}

enum _Sort { recent, eta, carrier }

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
      body: Consumer(builder: (context, ref, _) {
        final async = ref.watch(_shipmentsProvider(_state));
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            IosLargeNavBar(
              title: 'Shipments',
              expandedHeight: 96,
              actions: [
                CupertinoButton(
                  minSize: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () {
                    HapticService.light();
                    _showFilterSheet(context);
                  },
                  child: const Icon(CupertinoIcons.slider_horizontal_3,
                      color: AppColors.brand, size: 22),
                ),
                CupertinoButton(
                  minSize: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () {
                    HapticService.medium();
                    context.push(AppRoutes.portalCreate);
                  },
                  child: const Icon(CupertinoIcons.add_circled,
                      color: AppColors.brand, size: 24),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: IosSearchBar(
                  controller: _search,
                  hint: 'Search by tracking, city, or reference',
                  onChanged: (_) => _applyFilter(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
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
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                HapticService.medium();
                ref.invalidate(_shipmentsProvider);
                await Future.delayed(const Duration(milliseconds: 600));
              },
              builder: _refreshIndicator,
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorStateView(error: e),
              ),
              data: (res) {
                final list = res.data ?? [];
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
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
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return IosContextMenu(
                        actions: [
                          IosContextMenuItem(
                            icon: CupertinoIcons.location_solid,
                            label: 'Track on map',
                            onTap: () => context.push(
                                '${AppRoutes.liveMap}?tracking=${s.trackingNumber}'),
                          ),
                          IosContextMenuItem(
                            icon: CupertinoIcons.share,
                            label: 'Share tracking',
                            onTap: () => showIosShareSheet(
                              context: context,
                              title: 'Share shipment',
                              message:
                                  'Track shipment ${s.trackingNumber} on AirPak Express',
                              url:
                                  'https://airpak-express.com/track/${s.trackingNumber}',
                            ),
                          ),
                          IosContextMenuItem(
                            icon: CupertinoIcons.doc_on_clipboard,
                            label: 'Copy tracking number',
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: s.trackingNumber));
                              _toast(context, 'Copied');
                            },
                          ),
                          IosContextMenuItem(
                            icon: CupertinoIcons.bell,
                            label: 'Notify on updates',
                            onTap: () => _toast(context, 'Notifications on'),
                          ),
                          IosContextMenuItem(
                            icon: CupertinoIcons.archivebox,
                            label: 'Archive shipment',
                            onTap: () => _toast(context, 'Archived'),
                          ),
                          IosContextMenuItem(
                            destructive: true,
                            icon: CupertinoIcons.delete,
                            label: 'Delete',
                            onTap: () => _toast(context, 'Delete tapped'),
                          ),
                        ],
                        child: IosSwipeActions(
                          leadingActions: [
                            IosSwipeAction(
                              label: 'Track',
                              icon: CupertinoIcons.location_solid,
                              background: AppColors.info,
                              onTap: () => context.push(
                                  '${AppRoutes.liveMap}?tracking=${s.trackingNumber}'),
                            ),
                          ],
                          trailingActions: [
                            IosSwipeAction(
                              label: 'Archive',
                              icon: CupertinoIcons.archivebox,
                              background: AppColors.warning,
                              onTap: () => _toast(context, 'Archived'),
                            ),
                            IosSwipeAction(
                              label: 'Delete',
                              icon: CupertinoIcons.delete,
                              background: AppColors.danger,
                              onTap: () => _toast(context, 'Deleted'),
                            ),
                          ],
                          child: ShipmentCard(
                            shipment: s,
                            onTap: () => context.push(
                                '${AppRoutes.portalShipments}/${s.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () {
          HapticService.medium();
          context.push(AppRoutes.portalCreate);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _refreshIndicator(
      BuildContext context, RefreshIndicatorMode mode, double pulledExtent,
      double refreshTriggerPullDistance, double refreshIndicatorExtent) {
    final p = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    return Container(
      alignment: Alignment.center,
      height: refreshIndicatorExtent,
      child: Transform.scale(
        scale: 0.6 + 0.4 * p,
        child: Opacity(
          opacity: p,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient),
            child: const Icon(CupertinoIcons.arrow_down,
                color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showIosBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort & filter',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textColor)),
            const SizedBox(height: 16),
            IosSegmentedControl<_Sort>(
              options: const {
                _Sort.recent: 'Recent',
                _Sort.eta: 'ETA',
                _Sort.carrier: 'Carrier',
              },
              groupValue: _state.sort,
              onChanged: (s) {
                setState(() {
                  _state = _state.copyWith(sort: s);
                  _applyFilter();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    HapticService.success();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.textColor,
    ));
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
