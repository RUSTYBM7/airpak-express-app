import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/models/airpak_coin.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

/// Airpak Coin payment dashboard — Coinbase / Trust Wallet feel, but
/// with the explicit constraint of "Buy · Deposit · Pay" only.
/// No withdrawal. No swaps. Brand-native settlement, 1:1 USD peg.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  late FiatCurrency _currency;
  int _tabIndex = 0; // 0 portfolio, 1 buy, 2 history

  @override
  void initState() {
    super.initState();
    _currency = kFiatCurrencies.first;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final apcBalance = auth.profile?.walletBalance ?? 0.0;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Text('Airpak Coin',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.successColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: context.successColor,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text('1:1 USD',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.successColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _BalanceCard(apc: apcBalance, currency: _currency)),
            SliverToBoxAdapter(child: _ActionRow(onTab: (i) => setState(() => _tabIndex = i), current: _tabIndex)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  if (_tabIndex == 0) _PortfolioView(apc: apcBalance, currency: _currency, onCurrency: (c) => setState(() => _currency = c)),
                  if (_tabIndex == 1) _BuyView(apc: apcBalance, currency: _currency),
                  if (_tabIndex == 2) _HistoryView(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance card ────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double apc;
  final FiatCurrency currency;
  const _BalanceCard({required this.apc, required this.currency});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3A), Color(0xFF0A2540), Color(0xFF0052FF)],
          stops: [0.0, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.30),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Center(
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Airpak Coin',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(currency.flag,
                  style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Available balance',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value: apc,
                decimals: 2,
                prefix: '${currency.symbol}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('APC',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${formatFiat(apc, currency)} ${currency.code}  ·  Pegged 1:1 USD',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Action row (Buy / Deposit / Pay) ─────────────────────────────────
class _ActionRow extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTab;
  const _ActionRow({required this.current, required this.onTab});
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Buy', Icons.shopping_bag_rounded, const Color(0xFF0052FF)),
      ('Deposit', Icons.account_balance_rounded, const Color(0xFF34C759)),
      ('Pay', Icons.send_rounded, AppColors.brand),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: PressScale(
                onTap: () => onTab(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: current == i
                        ? items[i].$3.withValues(alpha: 0.12)
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: current == i
                          ? items[i].$3
                          : context.borderColor,
                      width: current == i ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(items[i].$2,
                          color: current == i
                              ? items[i].$3
                              : context.textMutedColor,
                          size: 22),
                      const SizedBox(height: 4),
                      Text(items[i].$1,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: current == i
                                  ? items[i].$3
                                  : context.textMutedColor)),
                    ],
                  ),
                ),
              ),
            ),
            if (i < items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

// ── Portfolio view (chart + asset allocation) ───────────────────────
class _PortfolioView extends StatelessWidget {
  final double apc;
  final FiatCurrency currency;
  final ValueChanged<FiatCurrency> onCurrency;
  const _PortfolioView(
      {required this.apc,
      required this.currency,
      required this.onCurrency});
  @override
  Widget build(BuildContext context) {
    final spots = _makeChart();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big chart card
        AppCard(
          padding: const EdgeInsets.all(18),
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('30-day activity',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.successColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded,
                            size: 12, color: context.successColor),
                        const SizedBox(width: 3),
                        Text('+12.4%',
                            style: TextStyle(
                                color: context.successColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AirpakCoin.spark,
                        barWidth: 2.4,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AirpakCoin.spark.withValues(alpha: 0.30),
                              AirpakCoin.spark.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Currency selector
        _CurrencySelector(
          current: currency,
          onPick: onCurrency,
        ),
        const SizedBox(height: 16),
        Text('Your assets',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 8),
        _AssetRow(
          symbol: 'APC',
          name: 'Airpak Coin',
          sub: 'Brand settlement · 1:1 USD',
          amount: apc,
          currency: currency,
          isPrimary: true,
        ),
        _AssetRow(
          symbol: 'REW',
          name: 'Rewards Points',
          sub: 'Earned per shipment · redeemable',
          amount: 0,
          currency: currency,
          isPrimary: false,
          amountText: '0 pts',
        ),
        const SizedBox(height: 16),
        Text('Recent activity',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 8),
        ..._sampleActivity.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityRow(t: t, currency: currency),
            )),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  final String symbol;
  final String name;
  final String sub;
  final double amount;
  final FiatCurrency currency;
  final bool isPrimary;
  final String? amountText;
  const _AssetRow({
    required this.symbol,
    required this.name,
    required this.sub,
    required this.amount,
    required this.currency,
    required this.isPrimary,
    this.amountText,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isPrimary
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0052FF), Color(0xFF0A2540)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFCC00), Color(0xFFD97706)],
                    ),
            ),
            child: Center(
              child: Text(symbol.substring(0, 1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textColor)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: context.textMutedColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText ?? formatFiat(amount, currency),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textColor),
              ),
              Text(symbol,
                  style: TextStyle(
                      fontSize: 11, color: context.textSubtleColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _Txn t;
  final FiatCurrency currency;
  const _ActivityRow({required this.t, required this.currency});
  @override
  Widget build(BuildContext context) {
    final inb = t.delta > 0;
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: inb
                  ? const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF16A34A)])
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              inb
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textColor)),
                Text(t.subtitle,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: context.textMutedColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${inb ? '+' : '-'}${formatFiat(t.delta.abs(), currency)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: inb
                        ? context.successColor
                        : context.textColor),
              ),
              Text(DateFormat('MMM d · h:mm a').format(t.date),
                  style: TextStyle(
                      fontSize: 10.5,
                      color: context.textMutedColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Buy view ────────────────────────────────────────────────────────
class _BuyView extends StatelessWidget {
  final double apc;
  final FiatCurrency currency;
  const _BuyView({required this.apc, required this.currency});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You pay',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textMutedColor)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.brand, size: 26),
                  const SizedBox(width: 8),
                  Text(currency.symbol,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  const SizedBox(width: 6),
                  Text('100.00',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 0.6,
                color: context.dividerColor,
              ),
              const SizedBox(height: 12),
              Text('You receive',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textMutedColor)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AirpakCoin.brandGradient,
                    ),
                    child: const Center(
                      child: Text('A',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('100.00',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  const SizedBox(width: 6),
                  Text('APC',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textMutedColor)),
                  const Spacer(),
                  Text('Rate 1:1',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.successColor)),
                ],
              ),
              const SizedBox(height: 18),
              _BuyAmountChips(),
              const SizedBox(height: 12),
              Text('Buy via',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textMutedColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _PayMethod(
                      label: 'Visa •• 4242', icon: Icons.credit_card_rounded),
                  _PayMethod(label: 'FPX', icon: Icons.account_balance_rounded),
                  _PayMethod(label: 'Apple Pay', icon: Icons.apple_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IosPrimaryButton(
          label: 'Buy 100 APC',
          icon: Icons.bolt_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Buy flow (mock)')),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Airpak Coin is a brand-native settlement token. It is pegged 1:1 to USD, may be funded with fiat via Buy or Deposit, and is used to Pay for shipments. Withdrawals are not supported.',
          style: TextStyle(
              fontSize: 11.5,
              color: context.textMutedColor,
              height: 1.45),
        ),
        const SizedBox(height: 18),
        // Crypto deposit + Contact admin — alternatives
        IosSection(
          header: 'Other ways to fund',
          margin: EdgeInsets.zero,
          rows: [
            IosRow(
              icon: Icons.currency_bitcoin_rounded,
              iconColor: const Color(0xFFF7931A),
              label: 'Crypto deposit',
              sublabel: 'BTC · ETH · USDC · USDT · APC',
              trailing: IosTrailing.chevron,
              onTap: () => context.push('/portal/crypto-deposit'),
            ),
            IosRow(
              icon: Icons.support_agent_rounded,
              iconColor: AppColors.warning,
              label: 'Contact admin for other payment',
              sublabel: 'Bank transfer, SWIFT, PayPal, WeChat Pay, local rails',
              trailing: IosTrailing.chevron,
              onTap: () => context.push('/portal/support'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BuyAmountChips extends StatelessWidget {
  const _BuyAmountChips();
  @override
  Widget build(BuildContext context) {
    final amounts = const ['50', '100', '250', '500', '1000'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: amounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: i == 1
                  ? AirpakCoin.spark.withValues(alpha: 0.12)
                  : context.surfaceMutedColor,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: i == 1
                    ? AirpakCoin.spark
                    : context.borderColor,
              ),
            ),
            child: Text(
              amounts[i],
              style: TextStyle(
                color: i == 1 ? AirpakCoin.spark : context.textBodyColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PayMethod({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceMutedColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textBodyColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textBodyColor)),
        ],
      ),
    );
  }
}

// ── History view ────────────────────────────────────────────────────
class _HistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          radius: 18,
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.brand, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No withdrawal supported',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.textColor)),
                    Text(
                      'Airpak Coin is a brand settlement token. Move it via Buy, Deposit or Pay only.',
                      style: TextStyle(
                          fontSize: 12, color: context.textMutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('All transactions',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 8),
        ..._sampleActivity.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityRow(
                  t: t,
                  currency: kFiatCurrencies.first),
            )),
      ],
    );
  }
}

// ── Currency selector ───────────────────────────────────────────────
class _CurrencySelector extends StatelessWidget {
  final FiatCurrency current;
  final ValueChanged<FiatCurrency> onPick;
  const _CurrencySelector({required this.current, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kFiatCurrencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = kFiatCurrencies[i];
          final sel = c.code == current.code;
          return PressScale(
            onTap: () => onPick(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? AirpakCoin.spark.withValues(alpha: 0.12)
                    : context.surfaceColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: sel ? AirpakCoin.spark : context.borderColor,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(c.code,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? AirpakCoin.spark
                              : context.textBodyColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Txn {
  final String title;
  final String subtitle;
  final double delta;
  final DateTime date;
  const _Txn(this.title, this.subtitle, this.delta, this.date);
}

final _sampleActivity = [
  _Txn('Top-up · Visa •• 4242', 'Bought 200 APC @ 1:1', 200.0,
      DateTime.now().subtract(const Duration(hours: 4))),
  _Txn('Pay · Shipment APK2026052600003', 'Standard · Kuala Lumpur → Jakarta', -32.40,
      DateTime.now().subtract(const Duration(hours: 6))),
  _Txn('Reward redemption', 'Discount voucher', -25.0,
      DateTime.now().subtract(const Duration(days: 1))),
  _Txn('Pay · Shipment APK20260524001233', 'Express · Singapore → Manila', -18.95,
      DateTime.now().subtract(const Duration(days: 2))),
  _Txn('Top-up · FPX', 'Maybank •• 4421', 150.0,
      DateTime.now().subtract(const Duration(days: 3))),
  _Txn('Pay · Shipment APK20260421000111', 'Sea Freight · Hong Kong', -210.0,
      DateTime.now().subtract(const Duration(days: 5))),
];

List<FlSpot> _makeChart() {
  final r = DateTime.now().millisecondsSinceEpoch;
  return List.generate(30, (i) {
    final v = 150 + ((i * 7 + (r ~/ 1000) % 11) % 50).toDouble() + i * 0.6;
    return FlSpot(i.toDouble(), v);
  });
}
