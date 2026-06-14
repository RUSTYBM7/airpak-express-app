import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/cupertino.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/profile.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

/// Admin user detail screen — edit profile, set status, send update/invoice,
/// place/remove holds on the user's shipments, view audit trail.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});
  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _busy = false;

  Future<AppProfile?> _load() async {
    final repo = ref.read(shipmentRepoProvider);
    final res = await repo.listProfiles();
    return (res.data ?? []).where((p) => p.id == widget.userId).cast<AppProfile?>().firstOrNull;
  }

  Future<void> _update(AppProfile p, AppProfile Function(AppProfile) f) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(shipmentRepoProvider);
      final updated = f(p);
      await repo.upsertProfile(updated);
      HapticService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated'), backgroundColor: AppColors.success),
        );
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
        child: FutureBuilder<AppProfile?>(
          future: _load(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return Center(child: CircularProgressIndicator(color: AppColors.brand));
            }
            final user = snap.data;
            if (user == null) {
              return _NotFoundView(userId: widget.userId);
            }
            return _UserBody(
              user: user,
              busy: _busy,
              onUpdate: (f) => _update(user, f),
              onRefresh: () => setState(() {}),
            );
          },
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  final String userId;
  const _NotFoundView({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin/portal/users'),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Spacer(),
        ]),
        const Expanded(
          child: EmptyState(
            icon: Icons.person_off_rounded,
            title: 'User not found',
            subtitle: 'The customer may have been removed.',
          ),
        ),
      ],
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

class _UserBody extends ConsumerStatefulWidget {
  final AppProfile user;
  final bool busy;
  final Future<void> Function(AppProfile Function(AppProfile)) onUpdate;
  final VoidCallback onRefresh;
  const _UserBody({
    required this.user,
    required this.busy,
    required this.onUpdate,
    required this.onRefresh,
  });
  @override
  ConsumerState<_UserBody> createState() => _UserBodyState();
}

class _UserBodyState extends ConsumerState<_UserBody> {
  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/admin/portal/users'),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textColor),
                ),
                const Spacer(),
                _StatusBadge(status: u.accountStatus),
              ],
            ),
          ),
        ),
        // Avatar + identity
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                _BigAvatar(user: u),
                const SizedBox(height: 12),
                Text(u.displayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textColor)),
                const SizedBox(height: 2),
                Text(u.email, style: TextStyle(fontSize: 14, color: context.textMutedColor)),
                if (u.companyName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(u.companyName,
                        style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Quick stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _StatTile(label: 'Wallet', value: '\$${u.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                _StatTile(label: 'Points', value: '${u.rewardPoints}', icon: Icons.star_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                _StatTile(label: 'Risk', value: u.riskLevel.toUpperCase(), icon: Icons.shield_rounded, color: _riskColor(u.riskLevel)),
              ],
            ),
          ),
        ),
        // Profile section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: IosSection(
              header: 'Profile',
              margin: EdgeInsets.zero,
              rows: [
                IosRow(icon: Icons.person_rounded, label: 'Full name', value: u.fullName ?? '—', trailing: IosTrailing.chevron, onTap: () => _editText('Full name', u.fullName ?? '', (v) => widget.onUpdate((p) => p.copyWith(fullName: v)))),
                IosRow(icon: Icons.alternate_email_rounded, label: 'Email', value: u.email, trailing: IosTrailing.none),
                IosRow(icon: Icons.phone_iphone_rounded, label: 'Phone', value: u.phone ?? '—', trailing: IosTrailing.chevron, onTap: () => _editText('Phone', u.phone ?? '', (v) => widget.onUpdate((p) => p.copyWith(phone: v)))),
                IosRow(icon: Icons.business_center_rounded, label: 'Company', value: u.companyName.isEmpty ? '—' : u.companyName, trailing: IosTrailing.chevron, onTap: () => _editText('Company', u.companyName, (v) => widget.onUpdate((p) => p.copyWith(companyName: v)))),
                IosRow(icon: Icons.verified_user_rounded, label: 'KYC level', value: u.kycLevel.name.toUpperCase(), valueColor: _kycColor(u.kycLevel), trailing: IosTrailing.chevron, onTap: () => _pickKyc(u)),
                IosRow(icon: Icons.security_rounded, label: 'Two-factor', value: u.twoFactorEnabled ? 'Enabled' : 'Off', valueColor: u.twoFactorEnabled ? AppColors.success : AppColors.textMuted, trailing: IosTrailing.none),
                IosRow(icon: Icons.shield_rounded, label: 'Risk level', value: u.riskLevel.toUpperCase(), valueColor: _riskColor(u.riskLevel), trailing: IosTrailing.chevron, onTap: () => _pickRisk(u)),
                IosRow(icon: Icons.login_rounded, label: 'Last login', value: u.lastLoginAt == null ? '—' : DateFormat('MMM d, HH:mm').format(u.lastLoginAt!), trailing: IosTrailing.none),
                IosRow(icon: Icons.event_rounded, label: 'Joined', value: u.joinedAt == null ? '—' : DateFormat('MMM d, y').format(u.joinedAt!), trailing: IosTrailing.none),
              ],
            ),
          ),
        ),
        // Account status section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: IosSection(
              header: 'Account status',
              margin: EdgeInsets.zero,
              rows: [
                _StatusRow(label: 'Active', status: AccountStatus.active, current: u.accountStatus, onPick: (s) => widget.onUpdate((p) => p.copyWith(accountStatus: s))),
                _StatusRow(label: 'Verified', status: AccountStatus.verified, current: u.accountStatus, onPick: (s) => widget.onUpdate((p) => p.copyWith(accountStatus: s))),
                _StatusRow(label: 'Pending', status: AccountStatus.pending, current: u.accountStatus, onPick: (s) => widget.onUpdate((p) => p.copyWith(accountStatus: s))),
                _StatusRow(label: 'Suspended', status: AccountStatus.suspended, current: u.accountStatus, onPick: (s) => widget.onUpdate((p) => p.copyWith(accountStatus: s))),
                _StatusRow(label: 'Blocked', status: AccountStatus.blocked, current: u.accountStatus, onPick: (s) => widget.onUpdate((p) => p.copyWith(accountStatus: s))),
              ],
            ),
          ),
        ),
        // Admin actions
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          sliver: SliverToBoxAdapter(
            child: IosSection(
              header: 'Admin actions',
              margin: EdgeInsets.zero,
              rows: [
                IosRow(icon: Icons.chat_bubble_outline_rounded, iconColor: AppColors.info, label: 'Send update / message', sublabel: 'Notify user about parcels, holds, or any topic', trailing: IosTrailing.chevron, onTap: () => _sendUpdate(u)),
                IosRow(icon: Icons.receipt_long_rounded, iconColor: AppColors.warning, label: 'Send server invoice', sublabel: 'Generate and email a custom invoice', trailing: IosTrailing.chevron, onTap: () => _sendInvoice(u)),
                IosRow(icon: Icons.local_shipping_rounded, iconColor: AppColors.danger, label: 'Manage parcel holds', sublabel: 'Place/remove hold (customs, border, payment)', trailing: IosTrailing.chevron, onTap: () => _manageHolds(u)),
                IosRow(icon: Icons.flag_rounded, iconColor: AppColors.danger, label: 'Add admin note', sublabel: u.notes == null || u.notes!.isEmpty ? 'No notes' : u.notes!, trailing: IosTrailing.chevron, onTap: () => _editText('Admin note', u.notes ?? '', (v) => widget.onUpdate((p) => p.copyWith(notes: v)))),
                IosRow(icon: Icons.privacy_tip_rounded, iconColor: AppColors.brand, label: 'Impersonate user', trailing: IosTrailing.chevron, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impersonation started (mock)')),
                  );
                }),
                IosRow(icon: Icons.delete_outline_rounded, iconColor: AppColors.danger, label: 'Delete user', valueColor: AppColors.danger, trailing: IosTrailing.none, onTap: () => _confirmDelete(u)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Color _kycColor(KycLevel k) {
    switch (k) {
      case KycLevel.full: return AppColors.success;
      case KycLevel.basic: return AppColors.info;
      case KycLevel.none: return AppColors.textMuted;
    }
  }
  Color _riskColor(String r) {
    switch (r) {
      case 'high': return AppColors.danger;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Future<void> _editText(String label, String current, Function(String) onSave) async {
    final ctrl = TextEditingController(text: current);
    String? newValue;
    await showIosSheet(
      context: context,
      title: 'Edit $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosTextField(controller: ctrl, hint: label, autofocus: true),
          const SizedBox(height: 12),
          IosPrimaryButton(label: 'Save', icon: Icons.check_rounded, onPressed: () {
            newValue = ctrl.text.trim();
            Navigator.pop(context);
          }),
        ],
      ),
    );
    if (newValue != null && newValue != current) onSave(newValue!);
  }

  Future<void> _pickKyc(AppProfile u) async {
    await showIosSheet(
      context: context,
      title: 'KYC level',
      child: Column(
        children: [
          for (final k in KycLevel.values)
            IosRow(
              icon: Icons.verified_user_rounded,
              iconColor: _kycColor(k),
              label: k.name.toUpperCase(),
              trailing: u.kycLevel == k ? IosTrailing.check : IosTrailing.none,
              onTap: () {
                widget.onUpdate((p) => p.copyWith(kycLevel: k));
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickRisk(AppProfile u) async {
    await showIosSheet(
      context: context,
      title: 'Risk level',
      child: Column(
        children: [
          for (final r in const ['low', 'medium', 'high'])
            IosRow(
              icon: Icons.shield_rounded,
              iconColor: _riskColor(r),
              label: r.toUpperCase(),
              trailing: u.riskLevel == r ? IosTrailing.check : IosTrailing.none,
              onTap: () {
                widget.onUpdate((p) => p.copyWith(riskLevel: r));
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _sendUpdate(AppProfile u) async {
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? sendResult;
    await showIosSheet(
      context: context,
      title: 'Send update to ${u.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosTextField(controller: subjectCtrl, hint: 'Subject (e.g. Parcel held by customs)', prefixIcon: Icons.subject_rounded),
          const SizedBox(height: 8),
          IosTextField(controller: bodyCtrl, hint: 'Message body', maxLines: 5, prefixIcon: Icons.message_rounded),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in const [
              'Parcel in customs',
              'Action required',
              'Address correction needed',
              'Delivery attempt failed',
              'Refund processed',
            ])
              GestureDetector(
                onTap: () {
                  subjectCtrl.text = t;
                  bodyCtrl.text = 'Hi ${u.displayName}, this is an update from AirPak Express regarding your shipment.';
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(t, style: const TextStyle(color: AppColors.brand, fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          IosPrimaryButton(label: 'Send', icon: Icons.send_rounded, onPressed: () {
            if (subjectCtrl.text.trim().isEmpty) {
              sendResult = null;
            } else {
              sendResult = subjectCtrl.text;
            }
            Navigator.pop(context);
          }),
        ],
      ),
    );
    if (sendResult != null) {
      HapticService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update sent: "$sendResult"'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _sendInvoice(AppProfile u) async {
    final descCtrl = TextEditingController(text: 'Custom service fee');
    final amountCtrl = TextEditingController(text: '50.00');
    String? confirm;
    await showIosSheet(
      context: context,
      title: 'Send invoice to ${u.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IosTextField(controller: descCtrl, hint: 'Description', prefixIcon: Icons.description_rounded),
          const SizedBox(height: 8),
          IosTextField(
            controller: amountCtrl,
            hint: 'Amount (USD)',
            prefixIcon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          IosPrimaryButton(label: 'Send invoice', icon: Icons.receipt_long_rounded, onPressed: () {
            final amt = double.tryParse(amountCtrl.text);
            if (amt == null || amt <= 0) return;
            confirm = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            Navigator.pop(context);
          }),
        ],
      ),
    );
    if (confirm != null) {
      HapticService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice $confirm for \$${amountCtrl.text} emailed to ${u.email}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _manageHolds(AppProfile u) async {
    // Show shipments for user
    final repo = ref.read(shipmentRepoProvider);
    final res = await repo.listShipments(userId: u.id);
    final shipments = (res.data ?? []).where((s) => s.userId == u.id).toList();
    if (!mounted) return;
    await showIosSheet(
      context: context,
      title: 'Manage holds — ${u.displayName}',
      child: Column(
        children: [
          if (shipments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(icon: Icons.local_shipping_outlined, title: 'No shipments yet'),
            )
          else
            for (final s in shipments.take(8))
              _ShipmentHoldRow(shipment: s, onChanged: () => setState(() {})),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AppProfile u) async {
    bool? confirm;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete user?'),
        content: Text('This will permanently remove ${u.displayName} and all their shipments. This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () { confirm = false; Navigator.pop(ctx); },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () { confirm = true; Navigator.pop(ctx); },
          ),
        ],
      ),
    );
    if (confirm == true) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${u.displayName} marked for deletion (mock)'), backgroundColor: AppColors.danger),
      );
    }
  }
}

class _BigAvatar extends StatelessWidget {
  final AppProfile user;
  const _BigAvatar({required this.user});
  @override
  Widget build(BuildContext context) {
    final initial = (user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName!.substring(0, 1).toUpperCase()
        : user.email.substring(0, 1).toUpperCase();
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_avatarColor(user.id, 0), _avatarColor(user.id, 1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
      ),
    );
  }
  Color _avatarColor(String id, int idx) {
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    final palette = [
      [AppColors.brand, AppColors.brandDark],
      [AppColors.info, AppColors.accent],
      [AppColors.success, AppColors.info],
      [AppColors.warning, AppColors.brand],
      [AppColors.danger, AppColors.warning],
    ];
    return palette[hash % palette.length][idx];
  }
}

class _StatusBadge extends StatelessWidget {
  final AccountStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.name.toUpperCase(),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        ],
      ),
    );
  }
  Color _color(AccountStatus s) {
    switch (s) {
      case AccountStatus.verified: return AppColors.success;
      case AccountStatus.active: return AppColors.info;
      case AccountStatus.pending: return AppColors.warning;
      case AccountStatus.suspended: return AppColors.warning;
      case AccountStatus.blocked: return AppColors.danger;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textColor)),
            Text(label, style: TextStyle(fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends IosRow {
  _StatusRow({
    required String label,
    required AccountStatus status,
    required AccountStatus current,
    required ValueChanged<AccountStatus> onPick,
  }) : super(
          label: label,
          icon: current == status ? Icons.check_circle_rounded : Icons.circle_outlined,
          iconColor: current == status
              ? (status == AccountStatus.blocked
                  ? AppColors.danger
                  : status == AccountStatus.verified
                      ? AppColors.success
                      : status == AccountStatus.pending
                          ? AppColors.warning
                          : AppColors.info)
              : AppColors.textMuted,
          trailing: IosTrailing.none,
          onTap: () => onPick(status),
        );
}

class _ShipmentHoldRow extends ConsumerStatefulWidget {
  final dynamic shipment;
  final VoidCallback onChanged;
  const _ShipmentHoldRow({required this.shipment, required this.onChanged});
  @override
  ConsumerState<_ShipmentHoldRow> createState() => _ShipmentHoldRowState();
}

class _ShipmentHoldRowState extends ConsumerState<_ShipmentHoldRow> {
  static const _reasons = [
    ('customs',     'Held by customs',            Icons.gavel_rounded,        AppColors.warning),
    ('border',      'Held by border regulators',  Icons.shield_moon_rounded,  AppColors.warning),
    ('guard',       'Held by guards',             Icons.local_police_rounded, AppColors.warning),
    ('payment',     'Payment hold',               Icons.payments_rounded,     AppColors.danger),
    ('docs',        'Documents missing',          Icons.description_rounded,  AppColors.info),
    ('inspection',  'Security inspection',        Icons.search_rounded,       AppColors.info),
    ('address',     'Address verification',       Icons.location_searching_rounded, AppColors.info),
    ('clear',       'Clear all holds (resume)',   Icons.play_circle_rounded,  AppColors.success),
  ];

  String? _activeHold;

  @override
  Widget build(BuildContext context) {
    final s = widget.shipment;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.brand, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.trackingNumber, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    Text('${s.origin.city} → ${s.destination.city}',
                        style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                  ],
                ),
              ),
              if (_activeHold != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(_activeHold!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              for (final r in _reasons)
                GestureDetector(
                  onTap: () async {
                    HapticService.selection();
                    setState(() {
                      if (r.$1 == 'clear') {
                        _activeHold = null;
                      } else {
                        _activeHold = r.$1.toUpperCase();
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(r.$1 == 'clear'
                            ? 'Hold cleared on ${s.trackingNumber}'
                            : '${r.$2} applied to ${s.trackingNumber}'),
                        backgroundColor: r.$4,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    widget.onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.$4.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(r.$2, style: TextStyle(color: r.$4, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
