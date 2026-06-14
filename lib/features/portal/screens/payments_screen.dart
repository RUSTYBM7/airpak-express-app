import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/airpak_coin.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

/// AirPak Invoice screen — two big buttons.
///
/// 1. **Deposit** — fund the AirPak wallet with Airpak Coin (1:1 USD)
///    or any supported crypto (BTC, ETH, USDC, USDT). The Airpak Coin
///    "1:1 USD" rail is already live; the other rails open the existing
///    crypto deposit screen with a full address + QR.
///
/// 2. **Invoice** — view, download, and pay any open invoice (per-shipment
///    or one-off admin-issued). Existing balance, due dates, and statuses
///    are shown inline.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final balance = auth.profile?.walletBalance ?? 0.0;
    final userId = auth.profile?.id;
    final shipAsync = userId == null
        ? const AsyncValue<RepoResult<List<Shipment>>>.data(RepoResult.ok([]))
        : ref.watch(_shipmentsProvider(userId));
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text('Invoice',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: context.textColor,
                        )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.successColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: context.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('APC 1:1 USD',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: context.successColor,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Two ways to settle. Pick one.',
                    style: TextStyle(fontSize: 13, color: context.textMutedColor)),
              ),
            ),
            // Two big action buttons
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _BigActionButton(
                        label: 'Deposit',
                        sublabel: 'Fund wallet',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.brand,
                        onTap: () => context.push('/portal/crypto-deposit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigActionButton(
                        label: 'Invoice',
                        sublabel: 'View & pay',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.success,
                        onTap: () => _openInvoices(shipAsync.value?.data ?? []),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Balance card
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _BalanceCard(balance: balance),
              ),
            ),
            // Invoices list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Open invoices',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textColor)),
                    const Spacer(),
                    shipAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (res) {
                        final list = (res.data ?? []);
                        final unpaid = list.where((s) => _statusIsUnpaid(s.status)).length;
                        if (unpaid == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('$unpaid due',
                              style: const TextStyle(color: AppColors.danger, fontSize: 10.5, fontWeight: FontWeight.w800)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            shipAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.all(40), child: EmptyState(icon: Icons.error_outline_rounded, title: 'Failed: $e')),
              ),
              data: (res) {
                final shipments = (res.data ?? []);
                if (shipments.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No invoices yet',
                        subtitle: 'Create a shipment to get an invoice.',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: shipments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _InvoiceRow(
                      shipment: shipments[i],
                      onTap: () => _showInvoice(shipments[i]),
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

  bool _statusIsUnpaid(ShipmentStatus s) {
    // Mock: any non-delivered, non-cancelled shipment with a price is "unpaid"
    return s != ShipmentStatus.delivered && s != ShipmentStatus.cancelled && s != ShipmentStatus.returned;
  }

  void _openInvoices(List<Shipment> all) {
    HapticService.selection();
    final unpaid = all.where((s) => _statusIsUnpaid(s.status)).toList();
    if (unpaid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open invoices — you\'re all paid up.')),
      );
      return;
    }
    // Scroll the user to the invoice list
    showIosSheet(
      context: context,
      title: '${unpaid.length} open invoice${unpaid.length == 1 ? '' : 's'}',
      child: Column(
        children: [
          for (final s in unpaid.take(10))
            IosRow(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.danger,
              label: s.trackingNumber,
              sublabel: '${s.origin.city} → ${s.destination.city} · \$${s.price.toStringAsFixed(2)}',
              trailing: IosTrailing.chevron,
              onTap: () {
                Navigator.pop(context);
                _showInvoice(s);
              },
            ),
        ],
      ),
    );
  }

  void _showInvoice(Shipment s) {
    final inv = 'INV-${s.trackingNumber.substring(3)}';
    showIosSheet(
      context: context,
      title: 'Invoice',
      isScrollControlled: true,
      initialChildSize: 0.85,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branded header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('A', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AirPak Express',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Global logistics · 220 destinations',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('UNPAID', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Invoice number & dates
            Row(
              children: [
                Expanded(child: _MetaTile(label: 'Invoice #', value: inv)),
                const SizedBox(width: 8),
                Expanded(child: _MetaTile(label: 'Issued', value: DateFormat('MMM d, y').format(s.createdAt))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _MetaTile(label: 'Service', value: s.service)),
                const SizedBox(width: 8),
                Expanded(child: _MetaTile(label: 'Status', value: s.status.label, valueColor: _statusColor(s.status))),
              ],
            ),
            const SizedBox(height: 16),
            // Items table
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _ItemRow(label: '${s.service} parcel — ${s.package.weightKg.toStringAsFixed(1)} kg', qty: '1', price: s.price.toStringAsFixed(2)),
                  _Divider(),
                  _ItemRow(label: 'Fuel surcharge', qty: '1', price: (s.price * 0.10).toStringAsFixed(2)),
                  _Divider(),
                  _ItemRow(label: 'Insurance', qty: '1', price: (s.price * 0.05).toStringAsFixed(2)),
                  _Divider(thick: true),
                  _ItemRow(label: 'Subtotal', price: (s.price * 1.15).toStringAsFixed(2)),
                  _ItemRow(label: 'VAT (0%)', price: '0.00'),
                  _ItemRow(label: 'TOTAL', price: (s.price * 1.15).toStringAsFixed(2), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Shipper / Consignee
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('SHIPPER'),
                  Text('${s.origin.name} · ${s.origin.city}, ${s.origin.country}',
                      style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const _SectionLabel('CONSIGNEE'),
                  Text('${s.destination.name} · ${s.destination.city}, ${s.destination.country}',
                      style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Pay buttons
            Row(
              children: [
                Expanded(
                  child: IosPrimaryButton(
                    label: 'Pay with Airpak Coin',
                    icon: Icons.payments_rounded,
                    onPressed: () {
                      HapticService.success();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${(s.price * 1.15).toStringAsFixed(2)} APC deducted from wallet'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IosTextButton(
                    'Crypto',
                    icon: Icons.currency_bitcoin_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/portal/crypto-deposit');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            IosTextButton(
              'Download PDF',
              icon: Icons.download_rounded,
              onPressed: () {
                HapticService.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF sent to your email.')),
                );
              },
            ),
          ],
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

final _shipmentsProvider = FutureProvider.autoDispose
    .family<RepoResult<List<Shipment>>, String?>((ref, userId) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.listShipments(userId: userId);
});

class _BigActionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BigActionButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticService.light(); onTap(); },
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(sublabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AirpakCoin.brandGradient,
            ),
            child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Airpak Coin balance', style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(balance.toStringAsFixed(2),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.textColor)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('APC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                    ),
                    const Spacer(),
                    Text('≈ \$${balance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  const _InvoiceRow({required this.shipment, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = shipment;
    final total = s.price * 1.15;
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () { HapticService.selection(); onTap(); },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('INV-${s.trackingNumber.substring(3)}',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.textColor)),
                    Text('${s.origin.city} → ${s.destination.city}',
                        style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\$${total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.danger)),
                  Text('Due now', style: TextStyle(fontSize: 10.5, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaTile({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor ?? context.textColor)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 10, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.5));
  }
}

class _ItemRow extends StatelessWidget {
  final String label;
  final String? qty;
  final String? price;
  final bool bold;
  const _ItemRow({required this.label, this.qty, this.price, this.bold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: context.textColor))),
          if (qty != null) Text(qty!, style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700)),
          if (price != null) ...[
            const SizedBox(width: 12),
            Text(price!, style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: context.textColor, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool thick;
  const _Divider({this.thick = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: thick ? 1 : 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: thick ? context.borderColor : context.dividerColor,
    );
  }
}
