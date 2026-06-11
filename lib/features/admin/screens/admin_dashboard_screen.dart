import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

final _allShipmentsProvider = FutureProvider.autoDispose<RepoResult<List<Shipment>>>(
  (ref) async {
    final repo = ref.watch(shipmentRepoProvider);
    return repo.listShipments();
  },
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allShipmentsProvider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand)),
      error: (e, _) => ErrorStateView(error: e),
      data: (res) {
        final all = res.data ?? [];
        final today = all.where((s) =>
            DateTime.now().difference(s.createdAt).inHours < 24).length;
        final inTransit = all
            .where((s) =>
                s.status == ShipmentStatus.inTransit ||
                s.status == ShipmentStatus.outForDelivery)
            .length;
        final delivered = all
            .where((s) => s.status == ShipmentStatus.delivered)
            .length;
        final revenue = all
            .where((s) => s.status == ShipmentStatus.delivered)
            .fold<double>(0, (a, b) => a + b.price);
        return RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async => ref.invalidate(_allShipmentsProvider),
          child: CustomScrollView(
            slivers: [
              const LargeNavBar(
                title: 'Admin Console',
                subtitle: 'Operations overview',
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.refresh_rounded, color: AppColors.brand),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _AdminHero(
                        today: today,
                        revenue: revenue,
                        inTransit: inTransit,
                        delivered: delivered),
                    const SizedBox(height: 24),
                    const SectionHeader('Performance', padding: EdgeInsets.zero),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text('Shipments · last 14 days',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Spacer(),
                              Icon(Icons.show_chart_rounded,
                                  size: 16, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('+12.4%',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 180, child: _TrendChart()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader('Recent shipments',
                        action: 'View all', padding: EdgeInsets.zero),
                    const SizedBox(height: 8),
                    if (all.isEmpty)
                      const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No shipments yet',
                      )
                    else
                      ...all.take(8).map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ShipmentRow(s: s),
                          )),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminHero extends StatelessWidget {
  final int today;
  final int inTransit;
  final int delivered;
  final double revenue;
  const _AdminHero({
    required this.today,
    required this.inTransit,
    required this.delivered,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Today',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Live',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$today',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5)),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('shipments',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(label: 'In transit', value: '$inTransit'),
              const SizedBox(width: 12),
              _miniStat(label: 'Delivered', value: '$delivered'),
              const SizedBox(width: 12),
              _miniStat(
                  label: 'Revenue',
                  value: FormatUtils.currency(revenue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10.5, letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ShipmentRow extends StatelessWidget {
  final Shipment s;
  const _ShipmentRow({required this.s});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.trackingNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                Text('${s.origin.city} → ${s.destination.city}',
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
                Text(
                    DateFormat('MMM d • h:mm a').format(s.createdAt),
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 11)),
              ],
            ),
          ),
          IosStatusPill(label: s.status.label, color: _colorFor(s.status)),
        ],
      ),
    );
  }

  Color _colorFor(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.delivered:
        return AppColors.success;
      case ShipmentStatus.outForDelivery:
        return AppColors.info;
      case ShipmentStatus.exception:
        return AppColors.brand;
      case ShipmentStatus.cancelled:
      case ShipmentStatus.returned:
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();
  @override
  Widget build(BuildContext context) {
    final data = List.generate(14, (i) {
      return FlSpot(i.toDouble(), (i * 3 + 12 + (i % 4) * 5).toDouble());
    });
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, _) {
                if (value.toInt() % 2 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('D${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: AppColors.brand,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brand.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}
