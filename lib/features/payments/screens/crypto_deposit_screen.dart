import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/cupertino.dart';

/// Crypto deposit screen — user can deposit BTC, ETH, USDC, USDT, or Airpak Coin
/// to fund their AirPak wallet. Shows a unique deposit address + QR code + copy
/// button for each supported network.
class CryptoDepositScreen extends ConsumerStatefulWidget {
  const CryptoDepositScreen({super.key});
  @override
  ConsumerState<CryptoDepositScreen> createState() => _CryptoDepositScreenState();
}

class _CryptoDepositScreenState extends ConsumerState<CryptoDepositScreen> {
  String _selected = 'USDC';

  static const List<_Crypto> _currencies = [
    _Crypto(
      id: 'BTC',
      name: 'Bitcoin',
      network: 'Bitcoin mainnet',
      icon: '₿',
      iconColor: Color(0xFFF7931A),
      rate: '1 BTC ≈ 64,280 USD',
      minDeposit: '0.0001 BTC',
      confirmations: '2 confirmations',
      address: 'bc1q9h6tq4z2ksp2n5p3wv6r7d8f9g0h1i2j3k4l5m',
    ),
    _Crypto(
      id: 'ETH',
      name: 'Ethereum',
      network: 'ERC-20',
      icon: 'Ξ',
      iconColor: Color(0xFF627EEA),
      rate: '1 ETH ≈ 3,180 USD',
      minDeposit: '0.005 ETH',
      confirmations: '12 confirmations',
      address: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    ),
    _Crypto(
      id: 'USDC',
      name: 'USD Coin',
      network: 'ERC-20 / Polygon / Solana',
      icon: '\$',
      iconColor: Color(0xFF2775CA),
      rate: '1 USDC = 1.00 USD',
      minDeposit: '10 USDC',
      confirmations: '12 / 64 / 32',
      address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    ),
    _Crypto(
      id: 'USDT',
      name: 'Tether',
      network: 'ERC-20 / TRC-20',
      icon: '₮',
      iconColor: Color(0xFF26A17B),
      rate: '1 USDT = 1.00 USD',
      minDeposit: '10 USDT',
      confirmations: '12 / 19',
      address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
    ),
    _Crypto(
      id: 'APC',
      name: 'Airpak Coin',
      network: 'Airpak native (EVM)',
      icon: 'A',
      iconColor: AppColors.brand,
      rate: '1 APC = 1.00 USD',
      minDeposit: '5 APC',
      confirmations: 'Instant (bridge)',
      address: '0xAPK8c4f3e7b2d9a1f6e5c8b7a4d3e2f1a9b8c7d6e',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _currencies.firstWhere((c) => c.id == _selected);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/portal/payments'),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textColor),
                    ),
                    Text('Crypto deposit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textColor)),
                  ],
                ),
              ),
            ),
            // Big info banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Fund your AirPak wallet',
                                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('Send crypto from any external wallet',
                                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Funds appear in your wallet after network confirmations. AirPak never controls your private keys.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Currency selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose asset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currencies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final c = _currencies[i];
                          final selected = c.id == _selected;
                          return GestureDetector(
                            onTap: () { HapticService.selection(); setState(() => _selected = c.id); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 110,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? c.iconColor.withValues(alpha: 0.12) : context.surfaceColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? c.iconColor : context.borderColor,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: c.iconColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(c.icon,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.id,
                                      style: TextStyle(
                                        color: selected ? c.iconColor : context.textColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Selected crypto detail
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _DepositCard(crypto: current),
              ),
            ),
            // Steps
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                      child: Text('How to deposit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                    ),
                    IosSection(
                      header: '',
                      margin: EdgeInsets.zero,
                      rows: [
                        _StepRow(num: 1, title: 'Copy the address below', sub: 'Or scan the QR code with your wallet'),
                        _StepRow(num: 2, title: 'Send only on a supported network', sub: 'Sending the wrong asset may result in permanent loss'),
                        _StepRow(num: 3, title: 'Wait for confirmations', sub: 'Funds will appear in your AirPak wallet'),
                        _StepRow(num: 4, title: 'Use Airpak Coin to pay for shipments', sub: 'Funds settle 1:1 to USD'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Contact admin for other payment
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Need another payment method?',
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: context.textColor)),
                                Text('Bank transfer, SWIFT, PayPal, WeChat Pay, or local rails.',
                                    style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: IosPrimaryButton(
                              label: 'Contact admin',
                              icon: Icons.chat_rounded,
                              onPressed: () {
                                HapticService.selection();
                                context.go('/portal/support');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: IosTextButton(
                              'Email team',
                              icon: Icons.mail_rounded,
                              onPressed: () {
                                HapticService.selection();
                                Clipboard.setData(const ClipboardData(text: 'payments@airpak-express.com'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Email copied: payments@airpak-express.com')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Crypto {
  final String id;
  final String name;
  final String network;
  final String icon;
  final Color iconColor;
  final String rate;
  final String minDeposit;
  final String confirmations;
  final String address;
  const _Crypto({
    required this.id,
    required this.name,
    required this.network,
    required this.icon,
    required this.iconColor,
    required this.rate,
    required this.minDeposit,
    required this.confirmations,
    required this.address,
  });
}

class _DepositCard extends StatelessWidget {
  final _Crypto crypto;
  const _DepositCard({required this.crypto});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: crypto.iconColor, shape: BoxShape.circle),
                child: Center(
                  child: Text(crypto.icon, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(crypto.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textColor)),
                    Text(crypto.network, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(crypto.rate, style: TextStyle(color: context.successColor, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // QR placeholder
          Center(
            child: Container(
              width: 180, height: 180,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: CustomPaint(
                painter: _QrPainter(crypto.address),
                size: const Size.square(160),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Deposit address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMutedColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    crypto.address,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticService.success();
                    Clipboard.setData(ClipboardData(text: crypto.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied to clipboard')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(label: 'Min', value: crypto.minDeposit, icon: Icons.south_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfo(label: 'Confirms', value: crypto.confirmations, icon: Icons.check_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniInfo({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.textMutedColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                Text(value, style: TextStyle(fontSize: 11, color: context.textColor, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple custom-painted "QR-style" pattern based on the address hash.
class _QrPainter extends CustomPainter {
  final String seed;
  _QrPainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final n = 21; // 21x21 grid like a real QR
    final cell = size.width / n;
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final paint = Paint()..color = const Color(0xFF0F172A);
    final finderPaint = Paint()..color = const Color(0xFF0F172A);
    final bgPaint = Paint()..color = Colors.white;

    // Random-ish deterministic fill
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        // 3 finder patterns at corners
        final isFinderArea =
            (x < 7 && y < 7) ||
            (x >= n - 7 && y < 7) ||
            (x < 7 && y >= n - 7);
        if (isFinderArea) continue;
        // Deterministic "data" cells
        final v = (hash * (x + 1) * (y + 1) + (x * 13 + y * 17)) % 100;
        if (v < 48) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    // Draw 3 finder squares
    void finder(double ox, double oy) {
      canvas.drawRect(Rect.fromLTWH(ox, oy, 7 * cell, 7 * cell), finderPaint);
      canvas.drawRect(Rect.fromLTWH(ox + cell, oy + cell, 5 * cell, 5 * cell), bgPaint);
      canvas.drawRect(Rect.fromLTWH(ox + 2 * cell, oy + 2 * cell, 3 * cell, 3 * cell), finderPaint);
    }
    finder(0, 0);
    finder((n - 7) * cell, 0);
    finder(0, (n - 7) * cell);
  }
  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

class _StepRow extends IosRow {
  _StepRow({required int num, required String title, required String sub})
      : super(
          label: title,
          sublabel: sub,
          trailing: IosTrailing.none,
          leading: Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
            child: Center(child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
        );
}
