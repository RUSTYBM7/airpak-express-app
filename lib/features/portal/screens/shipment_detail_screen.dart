import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/models/shipment.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

final _shipmentDetailProvider = FutureProvider.autoDispose
    .family<_ShipmentDetail, String>((ref, id) async {
  final repo = ref.watch(shipmentRepoProvider);
  final list = await repo.listShipments();
  final shipment = list.data?.firstWhere(
    (s) => s.id == id,
    orElse: () => list.data!.first,
  );
  if (shipment == null) {
    return _ShipmentDetail(null, const [], null);
  }
  final events = await repo.events(shipment.id);
  return _ShipmentDetail(shipment, events.data ?? const [], null);
});

class _ShipmentDetail {
  final Shipment? shipment;
  final List<TrackingEvent> events;
  final Object? error;
  const _ShipmentDetail(this.shipment, this.events, this.error);
}

class ShipmentDetailScreen extends ConsumerWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_shipmentDetailProvider(shipmentId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.portalShipments),
        ),
        title: const Text('Shipment details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {},
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brand)),
        error: (e, _) => ErrorStateView(error: e),
        data: (d) {
          final s = d.shipment;
          if (s == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'Shipment not found',
              action: AppPrimaryButton(
                label: 'Back',
                onPressed: () => context.go(AppRoutes.portalShipments),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brandDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.status.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CopyableText(
                      s.trackingNumber,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.flag,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${s.origin.city} → ${s.destination.city}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _chip(s.service, Colors.white24, Colors.white),
                        const SizedBox(width: 6),
                        _chip(s.priceFormatted, Colors.white, AppColors.brand),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text('Created',
                              style: TextStyle(
                                  color: context.textMutedColor, fontSize: 11)),
                          Text(DateFormat('MMM d').format(s.createdAt),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text('ETA',
                              style: TextStyle(
                                  color: context.textMutedColor, fontSize: 11)),
                          Text(s.etaFormatted,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: s.trackingNumber,
                        size: 80,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Quick actions'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _action(Icons.print, 'Label', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Label print opened')),
                                );
                              }),
                              _action(Icons.receipt, 'Invoice', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Invoice download started')),
                                );
                              }),
                              _action(Icons.copy, 'Copy #', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Tracking # copied')),
                                );
                              }),
                              _action(Icons.account_balance_wallet, 'Apple Wallet', () async {
                                await _addToWallet(context, s);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Tracking history'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < d.events.length; i++)
                      TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY: 0.2,
                        isFirst: i == 0,
                        isLast: i == d.events.length - 1,
                        indicatorStyle: IndicatorStyle(
                          width: 22,
                          color: i == 0 ? AppColors.brand : AppColors.border,
                          iconStyle: IconStyle(
                            iconData:
                                i == 0 ? Icons.radio_button_checked : Icons.check,
                            color: Colors.white,
                          ),
                        ),
                        beforeLineStyle: LineStyle(
                          color: i == 0 ? AppColors.brand : AppColors.border,
                          thickness: 2,
                        ),
                        endChild: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 0, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.events[i].status.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(d.events[i].location,
                                  style: TextStyle(
                                      color: context.textMutedColor, fontSize: 12)),
                              if (d.events[i].description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(d.events[i].description!,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a')
                                    .format(d.events[i].occurredAt),
                                style: TextStyle(
                                    color: context.textMutedColor, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Sender'),
                    const SizedBox(height: 8),
                    _addressBlock(context, s.origin),
                    const Divider(height: 24),
                    const SectionHeader('Recipient'),
                    const SizedBox(height: 8),
                    _addressBlock(context, s.destination),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Report an issue',
                icon: Icons.flag_outlined,
                onPressed: () => context.push(AppRoutes.portalSupport),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.brand),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Future<void> _addToWallet(BuildContext context, Shipment s) async {
    final wallet = WalletService.instance;
    if (!wallet.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Apple Wallet is only available on iOS devices')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Building pass…')),
    );
    final ok = await wallet.presentForShipment(s);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Added to Apple Wallet'
            : 'Could not add to Wallet. See logs.'),
      ),
    );
  }

  Widget _addressBlock(BuildContext context, Address a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(a.oneLine, style: TextStyle(color: context.textMutedColor)),
        const SizedBox(height: 2),
        Text(a.phone, style: TextStyle(color: context.textMutedColor)),
      ],
    );
  }
}
