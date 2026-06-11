import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final points = auth.profile?.rewardPoints ?? 0;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
          title: const Text('Rewards',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _PointsCard(points: points),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Redeem',
                    icon: Icons.card_giftcard_rounded,
                    onPressed: () => _showRedeem(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Refer & earn',
                    icon: Icons.share_rounded,
                    onPressed: () => _showRefer(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionHeader('How to earn', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            ..._earnWays.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _earnRow(e: e),
                )),
            const SizedBox(height: 22),
            const SectionHeader('Available rewards', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            ..._rewards.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(r: r, canAfford: points >= r.cost),
                )),
          ],
        ),
      ),
    );
  }

  Widget _earnRow({required _Earn e}) {
    return _EarnRow(e: e);
  }

  void _showRedeem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Redeem points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
                'Pick a reward and we will email you a voucher within 24 hours.',
                style: TextStyle(color: context.textMutedColor)),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reward redeemed (mock)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRefer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refer & earn'),
        content: const Text(
            'Share your code AIRPAK-DEMO and earn 500 points when a friend creates their first shipment.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final _Earn e;
  const _EarnRow({required this.e});
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
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(e.icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.textColor)),
                Text(e.subtitle,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Text(e.points,
              style: TextStyle(
                  color: AppColors.brand, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;
  const _PointsCard({required this.points});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Your points',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$points',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2)),
          Text('Earn 10 points for every USD 1 spent',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final _Reward r;
  final bool canAfford;
  const _RewardCard({required this.r, required this.canAfford});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(r.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(r.subtitle,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${r.cost} pts',
                  style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800)),
              if (!canAfford)
                Text('Not enough',
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Earn {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;
  const _Earn(this.icon, this.title, this.subtitle, this.points);
}

class _Reward {
  final IconData icon;
  final String title;
  final String subtitle;
  final int cost;
  const _Reward(this.icon, this.title, this.subtitle, this.cost);
}

const _earnWays = [
  _Earn(Icons.local_shipping_rounded, 'Ship a parcel',
      'Earn 10 points for every USD 1 spent on shipping.', '+10 pts / USD 1'),
  _Earn(Icons.share_rounded, 'Refer a friend',
      'Get points when a friend creates their first shipment.', '+500 pts'),
  _Earn(Icons.star_rate_rounded, 'Leave a review',
      'Rate your delivery and earn points.', '+50 pts'),
  _Earn(Icons.celebration_rounded, 'Birthday bonus',
      'Receive a birthday gift every year.', '+200 pts'),
];

const _rewards = [
  _Reward(Icons.discount_rounded, 'USD 5 voucher', 'Off your next shipment', 500),
  _Reward(Icons.local_cafe_rounded, 'Free coffee', 'Voucher at partner cafés', 300),
  _Reward(Icons.headset_mic_rounded, 'Priority support', '24/7 dedicated line', 1000),
  _Reward(Icons.flight_rounded, 'Free upgrade', 'Standard → Express (single use)', 2000),
];
