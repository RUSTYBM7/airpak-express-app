import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/profile.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

final _usersProvider =
    FutureProvider.autoDispose<RepoResult<List<AppProfile>>>((ref) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.listProfiles();
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String _role = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_usersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const LargeNavBar(
              title: 'Customers',
              subtitle: 'All registered accounts',
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.brand),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const SizedBox(height: 4),
                  IosTextField(
                    controller: _search,
                    hint: 'Search by name, email, company',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        for (final r in const ['All', 'Active', 'Suspended'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _role = r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _role == r
                                      ? AppColors.brand
                                      : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                  border: Border.all(
                                    color: _role == r
                                        ? AppColors.brand
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(r,
                                    style: TextStyle(
                                        color: _role == r
                                            ? Colors.white
                                            : AppColors.textBody,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.brand)),
                    ),
                    error: (e, _) => ErrorStateView(error: e),
                    data: (res) {
                      final users = (res.data ?? []).where((u) {
                        if (u.role == UserRole.admin) return false;
                        final q = _search.text.trim().toLowerCase();
                        if (q.isEmpty) return true;
                        return u.email.toLowerCase().contains(q) ||
                            u.displayName.toLowerCase().contains(q) ||
                            u.companyName.toLowerCase().contains(q);
                      }).toList();
                      if (users.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No customers match',
                          ),
                        );
                      }
                      return IosSection(
                        header: 'Accounts',
                        margin: EdgeInsets.zero,
                        rows: users
                            .map((u) => IosRow(
                                  icon: Icons.person_rounded,
                                  iconColor: _colorForPoints(u.rewardPoints),
                                  label: u.displayName,
                                  sublabel: u.email +
                                      (u.companyName.isNotEmpty
                                          ? ' • ${u.companyName}'
                                          : ''),
                                  trailing: IosTrailing.custom,
                                  customTrailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${u.rewardPoints} pts',
                                          style: const TextStyle(
                                              color: AppColors.brand,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13)),
                                      Text('Wallet ${u.walletBalance.toStringAsFixed(0)} USD',
                                          style: TextStyle(
                                              color: context.textMutedColor,
                                              fontSize: 11)),
                                    ],
                                  ),
                                  onTap: () => _showUser(context, u),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForPoints(int pts) {
    if (pts >= 2000) return AppColors.warning;
    if (pts >= 500) return AppColors.brand;
    return AppColors.info;
  }

  void _showUser(BuildContext context, AppProfile u) {
    showIosSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(u.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(u.displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(u.email,
                        style: TextStyle(
                            color: context.textMutedColor, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IosSection(
            header: 'Account',
            margin: EdgeInsets.zero,
            rows: [
              IosRow(
                icon: Icons.business_center_rounded,
                label: 'Company',
                value: u.companyName.isEmpty ? '—' : u.companyName,
                trailing: IosTrailing.none,
              ),
              IosRow(
                icon: Icons.star_rounded,
                iconColor: AppColors.warning,
                label: 'Reward points',
                value: '${u.rewardPoints}',
                trailing: IosTrailing.none,
              ),
              IosRow(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.success,
                label: 'Wallet balance',
                value: '${u.walletBalance.toStringAsFixed(2)} USD',
                trailing: IosTrailing.none,
              ),
              IosRow(
                icon: Icons.security_rounded,
                label: 'Two-factor',
                value: u.twoFactorEnabled ? 'Enabled' : 'Off',
                valueColor: u.twoFactorEnabled
                    ? AppColors.success
                    : AppColors.textMuted,
                trailing: IosTrailing.none,
              ),
            ],
          ),
          const SizedBox(height: 16),
          IosPrimaryButton(
            label: 'Impersonate user',
            icon: Icons.privacy_tip_rounded,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impersonation started (mock)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
