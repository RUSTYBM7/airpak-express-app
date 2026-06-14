import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';
import '../../settings/settings_controller.dart';

/// Admin settings — every option is real-time, persisted, and
/// observable from anywhere in the app via SettingsController.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        SectionHeader('Workspace', trailing: Text('${auth.profile?.companyName ?? "—"}', style: TextStyle(color: context.textMutedColor, fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF111827)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.shield_rounded, color: Colors.white, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(auth.profile?.fullName ?? 'Admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textColor)),
                    Text('${auth.profile?.email ?? "—"} · Admin', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  ],
                ),
              ),
              IosSwitch(value: settings.twoFactor, onChanged: (v) {
                ref.read(settingsControllerProvider.notifier).set2FA(v);
                HapticService.success();
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader('Operations'),
        IosSection(
          header: 'Live operations',
          margin: EdgeInsets.zero,
          rows: [
            IosRow(
              leading: Switch(
                value: settings.adminTelemetry,
                activeColor: AppColors.brand,
                onChanged: (v) {
                  ref.read(settingsControllerProvider.notifier).setAdminTelemetry(v);
                  HapticService.selection();
                },
              ),
              icon: Icons.speed_rounded,
              iconColor: AppColors.brand,
              label: 'Live telemetry',
              sublabel: settings.adminTelemetry ? 'Streaming every 4 seconds' : 'Paused',
            ),
            IosRow(
              leading: Switch(
                value: settings.adminAiCopilot,
                activeColor: AppColors.brand,
                onChanged: (v) {
                  ref.read(settingsControllerProvider.notifier).setAdminAiCopilot(v);
                  HapticService.selection();
                },
              ),
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFFAF52DE),
              label: 'AI co-pilot',
              sublabel: settings.adminAiCopilot ? 'Assisting with routing, holds, customer comms' : 'Off',
            ),
            IosRow(
              leading: Switch(
                value: settings.adminSlack,
                activeColor: AppColors.brand,
                onChanged: (v) {
                  ref.read(settingsControllerProvider.notifier).setAdminSlack(v);
                  HapticService.selection();
                },
              ),
              icon: Icons.tag_rounded,
              iconColor: const Color(0xFF4A154B),
              label: 'Slack alerts',
              sublabel: settings.adminSlack ? 'On — #airpak-ops' : 'Off',
            ),
            IosRow(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFF8E8E93),
              label: 'Time zone',
              value: settings.adminTimezone,
              trailing: IosTrailing.chevron,
              onTap: () => _showTimezone(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader('Notifications'),
        IosSection(
          header: 'Real-time alerts',
          margin: EdgeInsets.zero,
          rows: [
            IosRow(
              leading: Switch(
                value: settings.pushEnabled,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setPush(v),
              ),
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFFFF3B30),
              label: 'Push notifications',
              sublabel: 'On this device',
            ),
            IosRow(
              leading: Switch(
                value: settings.emailEnabled,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setEmail(v),
              ),
              icon: Icons.email_rounded,
              iconColor: const Color(0xFF007AFF),
              label: 'Email digests',
              sublabel: 'Daily summary at 09:00',
            ),
            IosRow(
              leading: Switch(
                value: settings.smsEnabled,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setSms(v),
              ),
              icon: Icons.sms_rounded,
              iconColor: const Color(0xFF34C759),
              label: 'SMS escalation',
              sublabel: 'Critical holds only',
            ),
            IosRow(
              leading: Switch(
                value: settings.haptics,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setHaptics(v),
              ),
              icon: Icons.vibration_rounded,
              iconColor: const Color(0xFFFF3B30),
              label: 'Haptic feedback',
              sublabel: 'Tactile alerts',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader('Personal'),
        IosSection(
          header: 'Account',
          margin: EdgeInsets.zero,
          rows: [
            IosRow(
              leading: Switch(
                value: settings.faceId,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setFaceId(v),
              ),
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF34C759),
              label: 'Face ID',
              sublabel: 'Unlock with biometrics',
            ),
            IosRow(
              leading: Switch(
                value: settings.biometricPayments,
                activeColor: AppColors.brand,
                onChanged: (v) => ref.read(settingsControllerProvider.notifier).setBiometricPayments(v),
              ),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.success,
              label: 'Biometric approvals',
              sublabel: 'Confirm payouts and invoices',
            ),
            IosRow(
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFF34C759),
              label: 'Payout account',
              value: 'DBS · •• 7821',
              trailing: IosTrailing.chevron,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout account management coming soon.'))),
            ),
            IosRow(
              icon: Icons.public_rounded,
              iconColor: const Color(0xFF5856D6),
              label: 'Currency',
              value: settings.defaultCurrency,
              trailing: IosTrailing.chevron,
              onTap: () => _showCurrencies(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader('Sign out'),
        IosSection(
          header: '',
          margin: EdgeInsets.zero,
          rows: [
            IosRow(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFFF3B30),
              label: 'Sign out of admin console',
              destructive: true,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.adminLogin);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showCurrencies(BuildContext context, WidgetRef ref) {
    final c = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'AUD', 'SGD', 'MYR', 'HKD', 'KRW', 'INR', 'AED', 'SAR'];
    showIosSheet(
      context: context,
      title: 'Currency',
      child: Column(
        children: [
          for (final x in c)
            IosRow(
              icon: Icons.public_rounded,
              label: x,
              trailing: IosTrailing.check,
              onTap: () {
                ref.read(settingsControllerProvider.notifier).setDefaultCurrency(x);
                HapticService.selection();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _showTimezone(BuildContext context, WidgetRef ref) {
    final tzs = [
      'UTC', 'Asia/Singapore', 'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata',
      'Asia/Dubai', 'Europe/London', 'Europe/Berlin', 'Europe/Paris',
      'America/New_York', 'America/Chicago', 'America/Los_Angeles',
      'Australia/Sydney', 'Pacific/Auckland',
    ];
    showIosSheet(
      context: context,
      title: 'Time zone',
      child: Column(
        children: [
          for (final t in tzs)
            IosRow(
              icon: Icons.schedule_rounded,
              label: t,
              trailing: IosTrailing.check,
              onTap: () {
                ref.read(settingsControllerProvider.notifier).setAdminTimezone(t);
                HapticService.selection();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
